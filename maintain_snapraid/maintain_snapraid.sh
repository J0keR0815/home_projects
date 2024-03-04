#!/bin/bash

EXIT_SUCCESS=0
EXIT_FAILURE=1
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

##### Configuration options #####

# Logfile where snapraid actions are reported
logfile="/var/log/snapraid.log"

# Percentage to randomly scrub:
# Snapraid remembers already scrubbed areas of the array.
# If the full array is scrubbed snapraid starts again.
declare -i scrub_perc=10

# Only scrub files older than 10 days:
declare -i scrub_age=10

##### BEGIN #####

# Create logfile if it does not exist
if [ ! -e "${logfile}" ]
then
	touch "${logfile}"
	chmod 640 "${logfile}"
	chown root:adm "${logfile}"
fi

# Error if logfile exists, but is not a regular file
if [ ! -f "${logfile}" ]
then
	logger -p syslog.err -t "snapraid" \
		"Error: \"${logfile}\" is not a regular file"
	exit ${EXIT_FAILURE}
fi

# Redirect error output to STDIN
exec >> "${logfile}" 2>&1

# Start maintainance job
declare -i n="$(cat "${logfile}" | wc -l)"

if [ $n -ne 0 ]
then
	echo -ne "\n"
fi
echo -e "##### BEGIN SNAPRAID MAINTENANCE #####\n\nDate: $(date)\n"

echo -e "##### TOUCH #####\n"
snapraid touch

echo -e "##### SYNC #####\n"
snapraid sync

echo -e "\n##### SCRUB #####\n"
snapraid scrub -p new
snapraid scrub -p ${scrub_perc} -o ${scrub_age}

echo -e "\n##### STATUS #####\n"
snapraid status

tail -n 1 "${logfile}" | grep -qE "^No error detected.$"
if [ $? -eq 0 ]
then
	exit ${EXIT_SUCCESS}
fi

echo -e "\n##### FIX #####\n"
snapraid -e fix

tail -n 1 "${logfile}" | grep -qE "^Everything OK$"
if [ $? -eq 0 ]
then
	exit ${EXIT_SUCCESS}
fi

echo -e "\n##### SCRUB BAD MARKED AREAS #####\n"
snapraid -p bad scrub
if [ $? -ne 0 ]
then
	exit ${EXIT_FAILURE}
fi

exit ${EXIT_SUCCESS}
