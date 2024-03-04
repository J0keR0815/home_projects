#!/bin/bash
#
# USAGE: smart_check.sh [test [L|S/TIMESPEC]]
#
# DESCRIPTION:
#
# For more details about TIMESPEC: See smart_check.conf
# The test mode tests if the check mode (L: long or S: short) and the TIMESPEC
# are valid or not. (See run_tests.sh)

##### Global definitions #####

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_INTERRUPTED=128
EXIT_USAGE=255

declare -A current_timespec
is_match=1
is_long=0
is_short=0
export pid=$$
ret=${EXIT_SUCCESS}
declare -a timespec_fields=( \
    "month_of_year" \
    "week_of_month" \
    "day_of_month" \
    "day_of_week" \
)
declare -A uuid_label_map=()

##### Config variables #####

conf="/etc/smart_check.conf"
#conf="${PWD}/smart_check.conf"
email_from="admin@example.org"
email_to="root"
export log_dir="/var/log/smart_check"

##### Function definitions #####

function check_dev() {
    # Check the specified device using smartctl in either long or short mode
    local check_mode=""
    local dev=""

    # Check which mode is specified
    while getopts "ls" opt
    do
        case "${opt}" in
            l)
                check_mode="long"
                ;;
            s)
                check_mode="short"
                ;;
            *)
                log_err "Usage: ${FUNCNAME} -l|-s DEV (Invalid option)"
                kill -SIGUSR2 ${pid}
                return ${EXIT_USAGE}
                ;;
        esac
    done

    if [ -z "${check_mode}" ]
    then
        log_err "Usage: ${FUNCNAME} -l|-s DEV (Missing option -l or -s)"
        kill -SIGUSR2 ${pid}
        return ${EXIT_USAGE}
    fi

    shift $(( $OPTIND - 1 ))

    # Check if device is specified
    dev="$1"
    if [ -z "${dev}" ]
    then
        log_err "Usage: ${FUNCNAME} -l|-s DEV" \
            "(Invalid value \"${dev}\" for DEV)"
        kill -SIGUSR2 ${pid}
        return ${EXIT_USAGE}
    fi

    # Get the actual device name (device is specified by UUID and refers to
    # a block device /dev/sdX)
    local uuid="$(basename "${dev}")"
    # Move old logfile and create new one
    local log_file="${log_dir}/${uuid}_${uuid_label_map[${uuid}]}"
    if [ -f "${log_file}" ]
    then
        mv "${log_file}" "${log_file}.bk"
        if [ $? -ne 0 ]
        then
            log_err "(${FUNCNAME}) Failed to move old log file" \
                "\"${log_file}\" to \"${log_file}\".bk"
            kill -SIGUSR1 ${pid}
        fi
    fi

    # Turn on S.M.A.R.T features
    /usr/sbin/smartctl -o on -s on -S on "${dev}"

    # Get recommended polling time
    declare -a polling_times=($( \
        /usr/sbin/smartctl -c "${dev}" | \
            grep "recommended polling time" | \
            sed 's/^.*([ \t]*\([0-9]\+\)).*$/\1/g' \
    ))
    if [ ${#polling_times[@]} -ne 2 ]
    then
        log_err "(${FUNCNAME}) Failed to get polling times for device " \
            "\"${dev}\""
        kill -SIGUSR1 ${pid}
    fi

    local polling_time_min=${polling_times[0]}
    if [ "${check_mode}" == "long" ]
    then
        local polling_time_min=${polling_times[1]}
    fi

    # Run check depending on check mode and wait for check to finish
    log_info "Running S.M.A.R.T ${check_mode} check for device \"${dev}\""
    /usr/sbin/smartctl -t "${check_mode}" "${dev}"
    wait_for_smart_check "${dev}" "${check_mode}" "${polling_time_min}"
    if [ $? -ne 0 ]
    then
        # Abort check
        /usr/sbin/smartctl -X "${dev}"
        log_err "(${FUNCNAME}) Failed waiting for ${check_mode} check of" \
            "device \"${dev}\""
        kill -SIGUSR1 ${pid}
    fi

    # Write S.M.A.R.T results
    log_info "Finished S.M.A.R.T ${check_mode} check for device \"${dev}\""
    /usr/sbin/smartctl -a "${dev}" > "${log_file}" 2>&1
}

function eval_timespec() {
    # Evaluate the TIMESPEC (See smart_check.conf)
    if [ -z "$1" ]
    then
        log_err "Usage: ${FUNCNAME} TIMESPEC"
        return ${EXIT_USAGE}
    fi

    # Evaluate check mode
    local check_mode=$(echo "$1" | cut -d '/' -s -f 1)
    eval_check_mode "${check_mode}"
    if [ $? -ne 0 ]
    then
        log_err "($FUNCNAME) Invalid check mode \"${check_mode}\""
        return ${EXIT_FAILURE}
    fi

    # Split TIMESPEC fields and check if the current date matches with each
    # field
    for i in "${!timespec_fields[@]}"
    do
        local value=$(echo "$1" | cut -d '/' -s -f $(( $i + 2 )))
        eval_timespec_field "${timespec_fields[$i]}" "${value}"
        if [ $? -ne 0 ]
        then
            log_err "($FUNCNAME) Invalid value \"${value}\"" \
                "for field \"${timespec_fields[$i]}\""
            return ${EXIT_FAILURE}
        fi
    done
    return ${EXIT_SUCCESS}
}

function eval_check_mode() {
    # Evaluate the mode field
    case "$1" in
        L)
            is_long=1
            ;;
        S)
            is_short=1
            ;;
        *)
            log_err "Usage: ${FUNCNAME} CHECK_MODE (Invalid argument)"
            return ${EXIT_USAGE}
            ;;
    esac

    return ${EXIT_SUCCESS}
}

function eval_timespec_field() {
    # Evaluates the specified value for the specified TIMESPEC field
    local ret=${EXIT_SUCCESS}

    # Check if specified field is valid and get default value
    local default_value="$(get_timespec_field_default_value "$1")"
    if [ -z "${default_value}" ]
    then
        log_err "Usage: ${FUNCNAME} TIMESPEC_FIELD VALUE" \
            "(Invalid argument \"$1\" for TIMESPEC_FIELD)"
        return ${EXIT_USAGE}
    fi

    # Check specified value
    if [ -z "$2" ]
    then
        log_err "Usage: ${FUNCNAME} TIMESPEC_FIELD VALUE" \
            "(Invalid argument \"$2\" for VALUE)"
        return ${EXIT_USAGE}
    fi

    local field="$1"
    local usage_msg_field="Usage: ${FUNCNAME} TIMESPEC_FIELD=${field} "
    usage_msg_field+="$(to_upper "${field}")_VALUE"
    local func_check="is_${field}"
    local value="$2"

    # Check value matches default value
    if [ "${value}" == "${default_value}" ]
    then
        return ${EXIT_SUCCESS}
    fi

    readarray -t values < <(split_group "${value}")
    for entry in "${values[@]}"
    do
        readarray -t range_values < <(split_range "${entry}")
        if [ ${#range_values[@]} -eq 2 ]
        then
            # Check if the value matches the specified range

            # Check start value
            local start=${range_values[0]}
            "${func_check}" "${start}" || ret=$?
            if [ ${ret} -ne ${EXIT_SUCCESS} ]
            then
                log_err "${usage_msg_field} (Invalid range \"${entry}\")"
                break
            fi

            # Check end value
            local end=${range_values[1]}
            "${func_check}" "${end}" || ret=$?
            if [ ${ret} -ne ${EXIT_SUCCESS} ]
            then
                log_err "${usage_msg_field} (Invalid range \"${entry}\")"
                break
            fi

            # Check if start <= end
            if [ ${start} -gt ${end} ]
            then
                ret=${EXIT_USAGE}
                log_err "${usage_msg_field} (Invalid range \"${entry}\")"
                break
            fi

            # Check if current TIMESPEC field value is in the range
            if [ ! \( \
                ${current_timespec[${field}]} -ge ${start} -a \
                ${current_timespec[${field}]} -le ${end} \
            \) ]
            then
                is_match=0
            fi
        elif [ ${#range_values[@]} -eq 1 ]
        then
            # Check if current TIMESPEC field value matches the specified single
            # value

            # Check the value
            "${func_check}" "${range_values[0]}" || ret=$?
            if [ ${ret} -ne ${EXIT_SUCCESS} ]
            then
                log_err "${usage_msg_field} (Invalid value \"${entry}\")"
                break
            fi

            # Check if current TIMESPEC field value matches the single value
            if [ ${current_timespec[${field}]} != ${range_values[0]} ]
            then
                is_match=0
            fi
        else
            ret=${EXIT_USAGE}
            log_err "${usage_msg_field} (Invalid value \"${entry}\")"
            break
        fi
    done

    if [ ${is_match} -eq 0 ]
    then
        log_dbg "(${FUNCNAME})" \
            "Current value \"${current_timespec[${field}]}\"" \
            "for TIMESPEC_FIELD \"${field}\"" \
            "does not match the specified VALUE \"${value}\""
    else
        log_dbg "(${FUNCNAME})" \
            "Current value \"${current_timespec[${field}]}\"" \
            "for TIMESPEC_FIELD \"${field}\"" \
            "matches the specified VALUE \"${value}\""
    fi

    return ${ret}
}

function get_timespec_fields_current_values() {
    # Loads the TIMESPEC of the current timestamp for each TIMESPEC field
    # (see: timespec_fields)
    for field in "${timespec_fields[@]}"
    do
        case "${field}" in
            month_of_year)
                current_timespec[${field}]=$(date +"%m")
                ;;
            week_of_month)
                current_timespec[${field}]=$(get_week_of_month)
                [ $? -ne ${EXIT_SUCCESS} ] && return ${EXIT_FAILURE}
                ;;
            day_of_month)
                current_timespec[${field}]=$(date +"%d")
                ;;
            day_of_week)
                current_timespec[${field}]=$(date +"%u")
                ;;
            *)
                log_err "(${FUNCNAME}) Invalid TIMESPEC field \"${field}\""
                return ${EXIT_FAILURE}
                ;;
        esac
    done

    return ${EXIT_SUCCESS}
}

function get_timespec_field_default_value() {
    # Checks if the specified field is a valid TIMESPEC field
    # (see: timespec_fields) and get default value
    case "$1" in
        day_of_month|month_of_year)
            echo ".."
            ;;
        day_of_week|week_of_month)
            echo "."
            ;;
        *)
            log_err "Usage: ${FUNCNAME} TIMESPEC_FIELD" \
                "(Invalid argument \"$1\" for TIMESPEC_FIELD)"
            return ${EXIT_USAGE}
            ;;
    esac

    return ${EXIT_SUCCESS}
}

function get_week_of_month() {
    # Gets the week of the current month (1 - 6)

    # Get current month of year
    local curr_month=$(date +"%m")

    # Get first day of current month
    local first_day_of_month=$(date -d "$(date +"%Y-%m-01")" +"%u")

    # Get current week of year
    local curr_week=$(date +"%V")
    if [ ${curr_month} -eq 1 -a ${curr_week} -eq 52 ]
    then
        curr_week=0
    elif [ ${curr_month} -eq 12 -a ${curr_week} -eq 1 ]
    then
        curr_week=53
    fi

    # Get week of year for the first day of this month
    local first_week=$(date -d "$(date +"%Y-%m-01")" +"%V")
    if [ ${curr_month} -eq 1 -a ${first_week} -eq 52 ]
    then
        first_week=0
    elif [ ${curr_month} -eq 12 -a ${first_week} -eq 1 ]
    then
        first_week=53
    fi

    # Calculate week of month
    local week_of_month=$(( ${curr_week} - ${first_week} ))
    if [ ${first_day_of_month} -eq 1 ]
    then
        week_of_month=$(( ${week_of_month} + 1 ))
    fi

    # Check if the value is value
    is_week_of_month "${week_of_month}"
    [ $? -ne 0 ] && return ${EXIT_FAILURE}

    echo "${week_of_month}"
    return ${EXIT_SUCCESS}
}

function init_uuid_label_map() {
    # Initiates the global variable uuid_label_map by adding pairs of
    # device UUIDs as key and the label of the btrfs filesystem on the mapped
    # device as value

    # Get UUIDs for all mapped devices and set the btrfs label
    declare -a dm_entries=($(cat /sys/class/block/dm-*/dm/uuid))
    if [ ${#dm_entries[@]} -eq 0 ]
    then
        log_err "(${FUNCNAME}) Failed to receive UUIDs of device mapper"
        return ${EXIT_FAILURE}
    fi

    for dm_entry in "${dm_entries[@]}"
    do
        local dm_entry_uuid="$(echo "${dm_entry}" | cut -s -d "-" -f 3)"
        local uuid="${dm_entry_uuid:0:8}-"
        uuid+="${dm_entry_uuid:8:4}-"
        uuid+="${dm_entry_uuid:12:4}-"
        uuid+="${dm_entry_uuid:16:4}-"
        uuid+="${dm_entry_uuid:20}"
        local dm="$(echo "${dm_entry}" | cut -s -d "-" -f 4-)"
        uuid_label_map[${uuid}]="$(btrfs filesystem label "/dev/mapper/${dm}")"
        if [ $? -ne 0 ]
        then
            log_err "(${FUNCNAME}) Mapping \"${uuid}\" to btrfs label failed"
            return ${EXIT_FAILURE}
        fi
    done

    # Add spare devices
    for dev_entry in "${devices[@]}"
    do
        # Get the UUID
        local uuid=$(echo "${dev_entry}" | cut -d ':' -s -f 1)

        # Add an entry if uuid is not in uuid_label_map        
        if [ -z "${uuid_label_map[${uuid}]}" ]
        then
            uuid_label_map[${uuid}]="spare"
        fi
    done

    return ${EXIT_SUCCESS}
}

function is_day_of_month() {
    # Check if the specified value is a valid day of month (01 ... 31)
    if [ -z "$1" ]
    then
        log_err "Usage: ${FUNCNAME} DAY_OF_MONTH_SPEC"
        return ${EXIT_USAGE}
    fi

    echo "$1" | grep -qE "^(0[1-9]|[12][0-9]|3[01])$"
    if [ $? -ne 0 ]
    then
        log_err "Usage: ${FUNCNAME} DAY_OF_MONTH_SPEC (Invalid value \"$1\")"
        return ${EXIT_USAGE}
    fi
    return ${EXIT_SUCCESS}
}

function is_day_of_week() {
    # Check if the specified value is a valid day of week (1 ... 7)
    if [ -z "$1" ]
    then
        log_err "Usage: ${FUNCNAME} DAY_OF_WEEK_SPEC"
        return ${EXIT_USAGE}
    fi

    echo "$1" | grep -qE "^[1-7]$"
    if [ $? -ne 0 ]
    then
        log_err "Usage: ${FUNCNAME} DAY_OF_WEEK_SPEC (Invalid value \"$1\")"
        return ${EXIT_USAGE}
    fi
    return ${EXIT_SUCCESS}
}

function is_month_of_year() {
    # Check if the specified value is a valid month of year (01 ... 12)
    if [ -z "$1" ]
    then
        log_err "Usage: ${FUNCNAME} MONTH_OF_YEAR_SPEC"
        return ${EXIT_USAGE}
    fi

    echo "$1" | grep -qE "^(0[1-9]|1[0-2])$"
    if [ $? -ne 0 ]
    then
        log_err "Usage: ${FUNCNAME} MONTH_OF_YEAR_SPEC (Invalid value \"$1\")"
        return ${EXIT_USAGE}
    fi
    return ${EXIT_SUCCESS}
}

function is_week_of_month() {
    # Check if the specified value is valid a week of month (0 ... 5)
    if [ -z "$1" ]
    then
        log_err "Usage: ${FUNCNAME} WEEK_OF_MONTH_SPEC"
        return ${EXIT_USAGE}
    fi

    echo "$1" | grep -qE "^[0-5]$"
    if [ $? -ne 0 ]
    then
        log_err "Usage: ${FUNCNAME} WEEK_OF_MONTH_SPEC (Invalid value \"$1\")"
        return ${EXIT_USAGE}
    fi
    return ${EXIT_SUCCESS}
}

function log_dbg() {
    # Print specified message to STDOUT and produce a debug log entry
    echo -e "[DEBUG] $*"
    logger -p syslog.debug -t "$(basename $0)" --id=${pid} "$*"
}

function log_err() {
    # Print specified message to STDERR and produce an error log entry
    echo -e "[ERROR] $*" >&2
    logger -p syslog.err -t "$(basename $0)" --id=${pid} "$*"
}

function log_info() {
    # Print specified message to STDOUT and produce an info log entry
    echo -e "[INFO] $*"
    logger -p syslog.info -t "$(basename $0)" --id=${pid} "$*"
}

function send_mail_notification() {
    # Sends the check results via E-mail
    local ret=${EXIT_SUCCESS}

    # Check if receiver and sender E-mail addresses are set
    if [ -z "${email_to}" ]
    then
        log_err "(${FUNCNAME})" Receiver E-mail address not specified
        return ${EXIT_FAILURE}
    fi

    if [ -z "${email_from}" ]
    then
        log_err "(${FUNCNAME})" Sender E-mail address not specified
        return ${EXIT_FAILURE}
    fi

    # Get list of new check results from log directory
    declare -a attachments=($( \
        find "${log_dir}" -mindepth 1 | grep -v "^.*\.bk$" \
    ))
    local message="S.M.A.R.T check results:\n\n"
    local message_attachments=""
    for file in "${attachments[@]}"
    do
        local fn="$(basename "${file}")"

        # Get device UUID from filename and check it
        local uuid="$(echo "${fn}" | cut -s -d '_' -f 1)"
        if [ -z "${uuid_label_map[${uuid}]}" ]
        then
            log_err "(${FUNCNAME}) Invalid UUID \"${uuid}\": No btrfs label" \
                "for mapped device"
            ret=${EXIT_FAILURE}
            continue
        fi

        # Create E-mail message
        message+="Device with UUID=${uuid} (${uuid_label_map[${uuid}]}): "

        # Append error status
        grep -iq "no errors logged" "${file}"
        if [ $? -eq 0 ]
        then
            message+="No errors found"
        else
            # Get number of errors
            declare -i error_count=$( \
                grep -i "error count" "${file}" | \
                    sed "s/^.*Error Count: \([0-9]\+\).*$/\1/g" \
            )
            if [ ${error_count} -eq 0 ]
            then
                message+="Could not get number of errors"
            else
                message+="${error_count} errors detected"
            fi
        fi

        message+="\n"

        # Add file to message attachements
        message_attachments+="-A \"${file}\" "
    done

    # Send E-mail
    local mail_command="mail -s \"S.M.A.R.T check results\" "
    mail_command+="-a \"From:${email_from}\" "
    [ ! -z "${message_attachments}" ] && mail_command+="${message_attachments}"
    mail_command+="\"${email_to}\""
    eval "echo -e \"${message}\" | ${mail_command}" || ret=$?
    if [ ${ret} -ne ${EXIT_SUCCESS} ]
    then
        log_err "(${FUNCNAME}) Sending E-mail from \"${email_from}\"" \
            "to \"${email_to}\" failed"
    fi

    return ${ret}
}

function split_group() {
    # Splits a group (..|..|..) into '\n'-separated entries and prints them to
    # STDOUT
    # If the specified argument is no group the argument is just printed to
    # STDOUT

    # Check if entry is a group
    echo "$1" | grep -qE "^\(.+\)$"
    if [ $? -eq 0 ]
    then
        # Split the group entries into a set of values and print it
        echo "$1" | \
            sed "s/^(\(.\+\))$/\1/g" | \
            tr '|' '\n' | \
            sort | \
            uniq
    elif [ ! -z "$1" ]
    then
        # No group: Print the value
        echo "$1"
    fi
}

function split_range() {
    # Splits a range [...-...] into two '\n'-separated values for start and end
    # of the range and prints them to STDOUT
    # If the specified argument is no range the argument is just printed to
    # STDOUT

    # Check if entry is a range
    echo "$1" | grep -qE "^\[[^-]+-[^-]+\]$"
    if [ $? -eq 0 ]
    then
        # Split the range entries into start and end value
        echo "$1" | \
            sed "s/^\[\(.\+\)\]$/\1/g" | \
            tr '-' '\n'
    elif [ ! -z "$1" ]
    then
        # No group: Print the value
        echo "$1"
    fi
}

function stop() {
    # Stops running S.M.A.R.T checks
    for dev_entry in "${devices[@]}"
    do
        # Check if device with specified UUID exists
        uuid=$(echo "${dev_entry}" | cut -d ':' -s -f 1)
        dev="/dev/disk/by-uuid/${uuid}"
        /usr/sbin/smartctl -X "${dev}"
    done

    exit ${EXIT_INTERRUPTED}
}

function to_upper() {
    # Convert specified argument to upper case
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

function wait_for_smart_check() {
    # Wait a specified time for the smart check of the specified device to
    # finish.
    # If short is specified for the check mode the specified time is used
    # for polling until the check is finished.
    # If long is specified for the check mode the specified time is used
    # for polling initially. Further polls are done with a higher frequency.
    # After the initial poll is finished the 2 % of the specified polling time
    # is used.

    # Check if device is set
    if [ -z "$1" ]
    then
        log_err "Usage: ${FUNCNAME} DEVICE CHECK_MODE WAITING_TIME_MIN" \
            "(Invalid value \"$1\") for DEVICE"
        return ${EXIT_USAGE}
    fi
    local dev="$1"

    # Check the check mode
    case "$2" in
        short|long)
            ;;
        *)
            log_err "Usage: ${FUNCNAME} DEVICE CHECK_MODE WAITING_TIME_MIN" \
                "(Invalid value \"$2\") for CHECK_MODE"
            return ${EXIT_USAGE}
        ;;
    esac
    local check_mode="$2"

    # Check waiting time
    if [ -z "$3" ]
    then
        log_err "Usage: ${FUNCNAME} DEVICE CHECK_MODE WAITING_TIME_MIN" \
            "(Invalid value \"$3\") for WAITING_TIME"
        return ${EXIT_USAGE}
    fi
    
    declare -i waiting_time_min="$3"
    if [ ${waiting_time_min} -le 0 ]
    then
        log_err "Usage: ${FUNCNAME} DEVICE CHECK_MODE WAITING_TIME_MIN" \
            "(Invalid value \"$3\") for WAITING_TIME"
        return ${EXIT_USAGE}
    fi

    # Wait initially
    log_info "Waiting ${waiting_time_min} min for" \
        "S.M.A.R.T ${check_mode} check of device \"${dev}\""
    declare -i waiting_time_sec=$(( 60 * ${waiting_time_min} ))
    sleep ${waiting_time_sec}

    if [ "${check_mode}" == "long" ]
    then
        # Reduce further waiting time for long checks to 2 %
        declare -i waiting_time_sec=$(( ${waiting_time_sec} / 50 ))
    fi

    while true
    do
        # Check if finished
        local exec_status=$( \
            /usr/sbin/smartctl -c "${dev}" | \
                grep -i "self-test execution status" \
        )

        echo "${exec_status}" | grep -qi "in progress"
        if [ $? -eq 0 ]
        then
            # Continue waiting
            log_info "S.M.A.R.T ${check_mode} check of device \"${dev}\"" \
                "still in progress: Waiting ${waiting_time_min} min"
            sleep ${waiting_time_sec}
            continue
        fi

        exec_status=$( \
            echo "${exec_status}" | \
            sed 's/^.*([ \t]*\([0-9]\+\)).*$/\1/g' \
        )
        
        if [ -z "${exec_status}" ]
        then
            log_err "(${FUNCNAME}) Failed to receive execution status"
            return ${EXIT_FAILURE}
        fi

        if [ ${exec_status} -ne 0 ]
        then
            log_info "S.M.A.R.T ${check_mode} check of device \"${dev}\"" \
                "did not complete"
        fi
        break
    done

    return ${EXIT_SUCCESS}
}

##### START #####

# Set signal handlers to set return code from parallel subprocesses
trap "ret=${EXIT_FAILURE}" SIGUSR1
trap "ret=${EXIT_USAGE}" SIGUSR2
trap "log_info \"Received SIGTERM: Going to stop\" ; stop" SIGTERM
trap "log_info \"Received SIGINT: Going to stop\" ; stop" SIGINT

# Load config
source "${conf}"

# Initiate UUID label mapper
init_uuid_label_map || ret=$?
[ $? -ne ${EXIT_SUCCESS} ] && exit ${ret}

# Load current time specification
get_timespec_fields_current_values || ret=$?
[ $? -ne ${EXIT_SUCCESS} ] && exit ${ret}

# Run tests if argument is specified
if [ "$1" == "test" ]
then
    echo "Test case: \"$2\""
    eval_timespec "$2" || ret=$?
    exit ${ret}
fi

# Create log directory
mkdir -p "${log_dir}" || ret=$?
if [ ${ret} -ne ${EXIT_SUCCESS} ]
then
    log_err "Failed to create log directory \"${log_dir}\""
    exit ${EXIT_FAILURE}
fi

# Run S.M.A.R.T checks for each configured device
for dev_entry in "${devices[@]}"
do
    uuid=$(echo "${dev_entry}" | cut -d ':' -s -f 1)
    timespec_long=$(echo "${dev_entry}" | cut -d ':' -s -f 2)
    timespec_short=$(echo "${dev_entry}" | cut -d ':' -s -f 3)

    # Check if device with specified UUID exists
    dev="/dev/disk/by-uuid/${uuid}"
    if [ ! -e "${dev}" ]
    then
        log_err "Device \"${dev}\" not found"
        ret=${EXIT_FAILURE}
        continue
    fi

    # Check if a test according to the timespecs will be run
    is_match=1
    eval_timespec "${timespec_long}"
    if [ ${is_long} -ne 0 -a ${is_match} -ne 0 ]
    then
        # Run long check
        log_info "Running long check for device \"${dev}\""
        check_dev -l "${dev}" &
        is_long=0
        continue
    fi

    is_match=1
    eval_timespec "${timespec_short}"
    if [ ${is_short} -ne 0 -a ${is_match} -ne 0 ]
    then
        # Run short check
        log_info "Running short check for device \"${dev}\""
        check_dev -s "${dev}" &
        is_short=0
        continue
    fi

    log_info "No test for device \"${dev}\""
done

# Wait for all checks to finish and send E-mail notification
wait
send_mail_notification || ret=$?

exit ${ret}
