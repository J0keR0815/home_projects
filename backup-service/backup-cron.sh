#!/bin/bash

EXIT_SUCCESS=0
EXIT_FAILURE=1

borgbackup="/usr/local/bin/borgbackup.sh"
dir_backup_config="/etc/backup.d"

function error() {
	local err_msg="Error: "
	
	if [ $# -lt 1 ]
	then
		err_msg+="An unspecified error occured"
	else
		err_msg+="$*"
	fi
	
	logger -p syslog.error -t backup "${err_msg}"
	exit ${EXIT_FAILURE}
}

##### BEGIN #####

while read config_file
do
	# Read config file
	. "${config_file}"
	[ -z "${ssh_hostname}" ] && \
		error "\"ssh_hostname\" not set"
	[ -z "${dir_backup_src}" ] && \
		error "\"dir_backup_src\" not set"
	[ -z "${dir_backup_target}" ] && \
		error "\"dir_backup_target\" not set"
	[ -z "${user}" ] && \
		error "\"user\" not set"
	[ -z "${group}" ] && \
		error "\"group\" not set"

	# Remove trailing "/" from directory pathes
	dir_backup_src="${dir_backup_src:a}"
	dir_backup_target="${dir_backup_target:a}"

	# Do backup
	rsync -a --delete -e "ssh" \
		"${ssh_hostname}:${dir_backup_src}/" "${dir_backup_target}"
	[ $? -ne 0 ] && \
		error "Syncing \"${ssh_hostname}:${dir_backup_src}\" to" \
			"\"${dir_backup_target}\" failed"

	# Set user, group and permissions
	chown -R "${user}:${group}" "${dir_backup_target}"
	[ $? -ne 0 ] && \
		error "Could not set user and group \"${user}:${group}\"" \
			"for \"${dir_backup_target}\""
	find "${dir_backup_target}" -type f -print0 | xargs -0 chmod 600
	[ $? -ne 0 ] && \
		error "Could not set permissions \"600\"" \
			"for files in \"${dir_backup_target}\""
done < <(find "${dir_backup_config}" -name "*.conf" -type f)

$borgbackup backup1
$borgbackup storagebox
