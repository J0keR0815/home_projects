#!/bin/bash
#
# DESCRIPTION:
#
# This script checks for the following conditions to be matched, before
# automatically sending this host to sleep.
#
# - Check if the current time is not within the specified exclusive
#   time range where the host must be running
# - Check for no logged in user
# - Check for no connected IP-addresses
# - Check for no active TCP connections on specified port
# - Check for no specified processes to be active
# - Check if smartd is running a device check if activated
#
# The "specified" options are found in the configuration file

# Set PATH
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Used exit codes
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_USAGE=255

# PID of this process
pid=$$

# Tag for logging
log_tag="autoshutdown"

# Default usage message
help_msg="Usage: $(basename $0)"

# Set default values for config options
declare -i debug=0
sleep_method="systemctl hybrid-sleep"
t_init=0
rounds=1
t_wait=0
t_range_excl_up=""
ip_addr=""
ports=""
procs=""
smart_check=0

config="/etc/autoshutdown.conf"
#config="$(dirname $0)/autoshutdown.conf"

# Established connections to this host: List of entries matching the template
# <src_ip>:<src_port>-<dest_ip>:<dest_port>
estab_conns=()

function check_connected_ports() {
    # This function explodes the specified ports or port-ranges from the config
    # option ${ports} and checks if there is a connection from another host to
    # at least one of the specified ports on this host.
    #
    # @return   "" if no connection is established, else the corresponding
    #           entry of the array ${estab_conns[@]}

    readarray -d ';' -t entries < <(echo -n "${ports}")
    for entry in "${entries[@]}"
    do
        # Check if entry is a range
        echo "${entry}" | grep -qE "^.+-.+$"
        if [ $? -ne 0 ]
        then
            # Entry is not a range: Single port or globbed port-sequence

            # Explode globbed entry
            entries_expl=($(eval echo "${entry}"))
            for p in "${entries_expl[@]}"
            do
                # Check port entry
                is_valid_port "$p"
                if [ $? -eq 0 ]
                then
                    error "Invalid port \"${entry}\""
                fi
                declare -i port="$p"

                for estab_conn in "${estab_conns[@]}"
                do
                    declare -i dest_port="$( \
                        echo "${estab_conn}" | \
                        cut -d "-" -f 2 | \
                        cut -d ":" -f 2 \
                    )"

                    if [ ${port} -eq ${dest_port} ]
                    then
                        echo "${estab_conn}"
                        return
                    fi
                done
            done
        else
            # Entry is a range

            # Check start-port
            local p="$(echo "${entry}" | cut -d "-" -f 1)"
            is_valid_port "$p"
            if [ $? -eq 0 ]
            then
                error "Invalid port-range \"${entry}\": Start port is invalid"
            fi
            declare -i p_start="$p"

            # Check end-port
            local p="$(echo "${entry}" | cut -d "-" -f 2)"
            is_valid_port "$p"
            if [ $? -eq 0 ]
            then
                error "Invalid port-range \"${entry}\": End port is invalid"
            fi
            declare -i p_end="$p"

            # Create sequence from port range
            local ports=()
            if [ ${p_start} -le ${p_end} ]
            then
                ports=($(seq ${p_start} 1 ${p_end}))
            else
                ports=($(seq ${p_end} -1 ${p_start}))
            fi

            # Check if there is a connection to one of these ports
            for estab_conn in "${estab_conns[@]}"
            do
                declare -i dest_port="$( \
                    echo "${estab_conn}" | \
                    cut -d "-" -f 2 | \
                    cut -d ":" -f 2 \
                )"

                echo "${ports[@]}" | tr ' ' '\n' | grep -qE "^${dest_port}$"
                if [ $? -eq 0 ]
                then
                    echo "${estab_conn}"
                    return
                fi
            done
        fi
    done

    echo ""
    return
}

function check_estab_conns() {
    # This function explodes the specified IP-addresses or nets from the config
    # option ${ip_addr} and checks if there is a matching connection from
    # at least on of the specified addresses.
    #
    # @return   "" if no connection is found or
    #           the IP-address of the first found established connection

    readarray -d ';' -t entries < <(echo -n "${ip_addr}")
    for entry in "${entries[@]}"
    do
        # Check entry with sipcalc
        local out=$(sipcalc "${entry}")
        echo -e "${out}" | grep -q "ERR"
        if [ $? -ne 0 ]
        then
            # Valid entry: Check output
            declare -i mask=$( \
                echo -e "${out}" | \
                    grep "mask (bits)" | \
                    cut -d "-" -f 2 | \
                    tr -d " " \
            )
            if [ ${mask} -lt 32 ]
            then
                # Entry is a net: Check if the IP-address of the established
                # connections is within the net range.

                # Get usable range
                local range="$( \
                    echo -e "${out}" | \
                        grep "Usable range" | \
                        tr -d "\t " | \
                        cut -d "-" -f 2- \
                )"

                # Check, if a source-IP-address of the established connections
                # is within the range
                for estab_conn in "${estab_conns[@]}"
                do
                    # Get source-IP-address
                    local src="$( \
                        echo "${estab_conn}" | \
                            cut -d "-" -f 1 | \
                            cut -d ":" -f 1 \
                    )"

                    # Create usable range from IP-address and mask
                    # and compare to the usable range of the config entry
                    local out_estab_conn="$(sipcalc "${src}/${mask}")"
                    echo -e "${out_estab_conn}" | grep -q "ERR"
                    if [ $? -eq 0 ]
                    then
                        local err_msg="Invalid source-entry for "
                        err_msg+="established connection: \"${src}/${mask}\""
                        error "${err_msg}" 
                    else
                        local range_estab_conn="$( \
                            echo -e "${out_estab_conn}" | \
                                grep "Usable range" | \
                                tr -d "\t " | \
                                cut -d "-" -f 2- \
                        )"
                        if [ "${range}" == "${range_estab_conn}" ]
                        then
                            echo "${src}"
                            return
                        fi
                    fi
                done
            else
                # Entry is a single IP-address: Check this IP-address is within
                # the source addresses of the established connection.
                
                # Get host address of specified config entry
                local host_addr="$( \
                    echo -e "${out}" | \
                        grep "Host address" | \
                        grep -vE "(decimal|hex)" | \
                        tr -d "\t " | \
                        cut -d "-" -f 2 \
                )"

                is_in_estab_conns "${host_addr}"
                if [ $? -ne 0 ]
                then
                    echo "${host_addr}"
                    return
                fi
            fi
        else
            # Explode globbed entry
            entries_expl=($(eval echo "${entry}"))
            for entry_expl in "${entries_expl[@]}"
            do
                # Check, if entry is valid
                out=$(sipcalc "${entry_expl}")
                echo -e "${out}" | grep -q "ERR"
                if [ $? -eq 0 ]
                then
                    error "Invalid config entry \"${entry}\""
                fi

                # Check, if entry is a singel IP-address
                declare -i mask=$( \
                    echo -e "${out}" | \
                        grep "mask (bits)" | \
                        cut -d "-" -f 2 | \
                        tr -d " " \
                )
                if [ ${mask} -ne 32 ]
                then
                    error "Invalid config entry \"${entry}\""
                fi

                # Check if specified config IP-address is within the
                # source addresses of established connections.

                # Get host address of specified config entry
                local host_addr="$( \
                    echo -e "${out}" | \
                        grep "Host address" | \
                        grep -vE "(decimal|hex)" | \
                        tr -d "\t " | \
                        cut -d "-" -f 2 \
                )"

                is_in_estab_conns "${host_addr}"
                if [ $? -ne 0 ]
                then
                    echo "${host_addr}"
                    return
                fi
            done
        fi
    done

    echo ""
    return
}

function check_procs() {
    # This function checks if at least one of the specified processes is
    # running.
    #
    # @return   "", if none of the specified process is running, else the
    #           process name

    readarray -d ';' -t entries < <(echo -n "${procs}")
    for p in "${entries[@]}"
    do
        # Check if there is a running process with the name matching ${p}
        pgrep -f "${p}" > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            echo "${p}"
            return
        fi
    done

    echo ""
    return
}

function check_smart() {
    # This function checks if smartd is running a device check
    #
    # @return   "", if smartd is not running a device check, else the UUID of
    #           the device

    if [ ${smart_check} -eq 0 ]
    then
        echo ""
        return
    fi

    # Get device UUIDs and check for each device if smartd is running a check
    local uuids=($(blkid | sed 's/^.*UUID=\([^\t ]\+\).*$/\1/g' | tr -d '\"'))
    for uuid in "${uuids[@]}"
    do
        local exec_status="$( \
            smartctl -c "/dev/disk/by-uuid/${uuid}" | \
                grep -i "self-test execution status" \
        )"

        echo "${exec_status}" | grep -qi "in progress"
        if [ $? -eq 0 ]
        then
            echo "/dev/disk/by-uuid/${uuid}"
            return
        fi
    done

    echo ""
    return
}

function check_time() {
    # This function checks if the current time is within the exclusive time
    # range where the host must be up.
    #
    # @return   1, if current time is within the specified range, else 0

    # Get current time
    declare -i t_now="$(date +"%s")"
    if [ $? -ne 0 ]
    then
        error "Could not get current timestamp"
    fi

    ##### Check specified time range #####

    # Check for default value
    if [ -z "${t_range_excl_up}" ]
    then
        return 0
    fi

    # Check for valid template
    echo "${t_range_excl_up}" | \
        grep -qE '^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$'
    if [ $? -ne 0 ]
    then
        error "Invalid value \"${t_range_excl_up}\" for option t_range_excl_up"
    fi

    # Check if start-value is valid
    local t="$(echo "${t_range_excl_up}" | cut -d "-" -f 1)"
    declare -i t_start="$(date +"%s" -d "${t}")"
    if [ $? -ne 0 ]
    then
        local err_msg="Invalid value \"${t_range_excl_up}\" for option"
        err_msg+="t_range_excl_up: Start time is invalid"
        error "${err_msg}"
    fi

    # Check if end-value is valid
    local t="$(echo "${t_range_excl_up}" | cut -d "-" -f 2)"
    declare -i t_end="$(date +"%s" -d "${t}")"
    if [ $? -ne 0 ]
    then
        local err_msg="Invalid value \"${t_range_excl_up}\" for option"
        err_msg+="t_range_excl_up: Start time is invalid"
        error "${err_msg}"
    fi

    # Check if there is an overrun by one day
    if [ ${t_start} -gt ${t_end} ]
    then
        if [ ${t_now} -gt ${t_end} ]
        then
            t_end="$(date +"%s" -d "23:59:59")"
            if [ $? -ne 0 ]
            then
                error "Could not get midnight-timestamp and end"
            fi
        elif [ ${t_now} -lt ${t_start} ]
        then
            t_start="$(date +"%s" -d "00:00:00")"
            if [ $? -ne 0 ]
            then
                error "Could not get midnight-timestamp as start"
            fi
        fi
    fi

    ##### Check if current timestamp is inbetween the time-range #####

    [ ${t_start} -gt ${t_now} ] && return 0
    [ ${t_end} -lt ${t_now} ] && return 0
    return 1
}

function error() {
    # This function logs the specified error message.
    # After that the process exits with EXIT_USAGE.
    #
    # Usage: error <err_msg>
    if [ -z "$1" ]
    then
        usage "${FUNCNAME} <err_msg>"
    else 
        logger -t "${log_tag}" -p syslog.err "Error: ${1}"
    fi

    kill -SIGUSR1 $pid
    exit ${EXIT_FAILURE}
}

function debug() {
    # This function prints a debug message to STDERR.
    #
    # Usage: debug <msg>

    if [ -z "$1" ]
    then
        usage "${FUNCNAME} <msg>"
    fi

    echo -e "DEBUG: $1" >&2
}

function exit_failure() {
    # This function exits the program using the exit-code ${EXIT_FAILURE}.
    exit ${EXIT_FAILURE}
}

function exit_usage() {
    # This function exits the program using the exit-code ${EXIT_USAGE}.
    exit ${EXIT_USAGE}
}

function init_estab_conns() {
    # This function assembles a sequence of established connections to this
    # host in the global array "${estab_conns[@]}". The entries match the
    # following template:
    #
    #   <src_ip>:<src_port>-<dest_ip>:<dest_port>

    # Get IP-address of this host:
    local ips_host=($( \
        ip addr show | \
            grep "inet.*brd" | \
            tr -s "\t " " " | \
            cut -d " " -f 3 | \
            cut -d "/" -f 1 | \
            sort -t "." -k 1,1n -k 2,2n -k 3.3n -k 4,4n | \
            uniq \
    ))

    # Get all established connections using ss
    while read entry
    do
        # Get source and destination entry of connection
        local dest="$(echo "${entry}" | tr -s "\t " " " | cut -d " " -f 4)"
        local src="$(echo "${entry}" | tr -s "\t " " " | cut -d " " -f 5)"

        # Check if destination IP-address is this host
        local dest_ip="$(echo "${src}" | cut -d ":" -f 1)"
        echo "${ips_host[@]}" | tr " " "\n" | grep -qF "${dest_ip}"
        if [ $? -ne 0 ]
        then
            if [ ${#estab_conns[@]} -eq 0 ]
            then
                # Add array to empty array
                estab_conns=("${src}-${dest}")
            else
                # Add element to none-empty array
                estab_conns=("${estab_conns[@]}" "${src}-${dest}")
            fi
        fi
    done < <(ss -tn | grep "ESTAB")
}

function is_in_estab_conns() {
    # This function checks if the specified value is within the
    # source addresses of the established connections.
    #
    # Usage: is_in_estab_conns <IP-address>
    #
    # @return   1, if value is within source addresses of the established
    #           connections, else 0

    if [ -z "$1" ]
    then
        usage "${FUNCNAME} <IP-address>"
    fi

    # Check, if a source-IP-address of the established connections
    # equals the host address
    for estab_conn in "${estab_conns[@]}"
    do
        # Get source-IP-address
        local src="$( \
            echo "${estab_conn}" | \
                cut -d "-" -f 1 | \
                cut -d ":" -f 1 \
        )"

        # Check if source IP-address is valid
        local out_estab_conn="$(sipcalc "${src}")"
        echo -e "${out_estab_conn}" | grep -q "ERR"
        if [ $? -eq 0 ]
        then
            local err_msg="Invalid source-entry for "
            err_msg+="established connection: \"${src}\""
            error "${err_msg}"
        fi
        
        # Compare addresses
        if [ "${1}" == "${src}" ]
        then
            return 1
        fi
    done

    return 0
}

function is_numeric() {
    # This function checks if the specified argument is a number n,
    # with n in N U {0}.
    #
    # Usage: is_numeric <n>
    #
    # @return   1 if n is in N U {0}, else 0

    if [ -z "$1" ]
    then
        usage "${FUNCNAME} <n>"
    fi

    # Check if commandline parameter is numeric
    echo "$1" | grep -qE '^[0-9]*$'
    if [ $? -ne 0 ]
    then
        return 0
    fi
    return 1
}

function is_valid_port() {
    # This function checks if the specified port is within the range
    # {0..65535}.
    #
    # Usage: is_valid_port <port>
    #
    # @return   1, if the port is valid, else 0

    local usg_msg="${FUNCNAME} <port>"
    if [ -z "$1" ]
    then
        usage "${usg_msg}"
    fi

    # Check if commandline parameter is numeric
    is_numeric "$1"
    if [ $? -eq 0 ]
    then
        usg_msg+="\n\nInvalid argument \"${1}\" for ${FUNCNAME}, "
        usg_msg+="port must be an integer >= 0"
        usage "${usg_msg}"
    fi

    declare -i p="$1"
    if [ $p -lt 0 -o $p -gt $(( 2 ** 16 - 1 )) ]
    then
        return 0
    fi

    return 1
}

function log() {
    # This function logs the specified info-message.
    #
    # Usage: log <msg>
    if [ -z "$1" ]
    then
        usage "${FUNCNAME} <msg>"
    else
        logger -t "${log_tag}" -p syslog.info "$1"
    fi
}

function usage() {
    # This function logs either the default usage string or a specified one.
    # After that the process exits with EXIT_USAGE.
    #
    # Usage: usage [err_msg]
    if [ -z "$1" ]
    then
        logger -t "${log_tag}" -p syslog.err "${help_msg}"
    else
        logger -t "${log_tag}" -p syslog.err "Usage: ${1}"
    fi

    kill -SIGUSR2 $pid
    exit ${EXIT_USAGE}
}

##### BEGIN #####

# Set traps for exiting on error
trap exit_failure SIGUSR1
trap exit_usage SIGUSR2

# Load configuration options
[ ! -f ${config} ] && error "File \"${config}\" not found"
source ${config}

[ ${debug} -eq 1 ] && log "Debugging mode activated"

# Check if config option ${t_init} is valid
is_numeric "${t_init}"
if [ $? -eq 0 ]
then
    error "Invalid value \"${t_init}\" for option t_init"
fi
log "Process initiated: Waiting ${t_init} s before first check"
sleep ${t_init}

# Check if config option ${t_wait} is valid
is_numeric "${t_wait}"
if [ $? -eq 0 ]
then
    error "Invalid value \"${t_wait}\" for option t_wait"
fi

# Check config option ${rounds} and initiate counter $r
is_numeric "${rounds}"
if [ $? -eq 0 ]
then
    error "Invalid value \"${rounds}\" for option rounds"
fi

if [ ${rounds} -le 0 ]
then
    error "Invalid value \"${rounds}\" for option rounds: rounds must be > 0"
fi

# Check config option ${smart_check}
is_numeric "${smart_check}"
if [ $? -eq 0 ]
then
    error "Invalid value \"${smart_check}\" for option smart_check"
fi

declare -i r=${rounds}
declare -i is_init=1
declare -i is_match=0
while [ $r -gt 0 ]
do
    is_match=0

    # Sleep before next check
    if [ ${is_init} -ne 1 ]
    then
        log "Waiting ${t_wait} s before next check"
        sleep ${t_wait}
    else
        is_init=0
    fi

    # Check if current time is inbetween the exclusive time range
    check_time
    if [ $? -eq 1 ]
    then
        msg="Host must be up at the moment: $(date +"%H:%M") is within "
        msg+="the specified time range ${t_range_excl_up}"
        log "${msg}"

        [ ${debug} -eq 0 ] && continue
        is_match=1
    fi

    # Check for logged in user
    users="$(users)"
    if [ ! -z "${users}" ]
    then
        log "Logged in users: ${users}"

        [ ${debug} -eq 0 ] && continue
        is_match=1
    fi

    # Init established connection stored in the array ${estab_conns[@]}
    estab_conns=()
    init_estab_conns

    # Check for connections from the specified IP-addresses
    estab_conn="$(check_estab_conns)"
    if [ ! -z "${estab_conn}" ]
    then
        log "Found connection from ${estab_conn}"

        [ ${debug} -eq 0 ] && continue
        is_match=1
    fi

    # Check for connections on specified ports
    estab_conn="$(check_connected_ports)"
    if [ ! -z "${estab_conn}" ]
    then
        src="$(echo "${estab_conn}" | cut -d "-" -f 1)"
        dest_port="$(echo "${estab_conn}" | cut -d "-" -f 2 | cut -d ":" -f 2)"
        log "Found connection on specified port ${dest_port} from ${src}"

        [ ${debug} -eq 0 ] && continue
        is_match=1
    fi

    # Check for specified processes
    proc_running="$(check_procs)"
    if [ ! -z "${proc_running}" ]
    then
        log "Found specified process \"${proc_running}\""

        [ ${debug} -eq 0 ] && continue
        is_match=1
    fi

    # Check if smartd is running a device check
    smart_check_running="$(check_smart)"
    if [ ! -z "${smart_check_running}" ]
    then
        log "Found running smartd device check \"${smart_check_running}\""

        [ ${debug} -eq 0 ] && continue
        is_match=1
    fi

    # Decrement counter
    if [ ${is_match} -eq 0 ]
    then
        r=$(( $r - 1 ))
    else
        r=${rounds}
    fi
done

# If no condition matches send this host to sleep
log "Going to sleep"
[ ${debug} -eq 0 ] && ${sleep_method}

exit ${EXIT_SUCCESS}