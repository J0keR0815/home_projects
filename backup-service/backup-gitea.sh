#!/bin/bash

EXIT_SUCCESS=0
EXIT_FAILURE=1

gitea="/usr/local/bin/gitea"
config_gitea="/etc/gitea/app.ini"
target_backup="/mnt/backup/gitea"
path_backup="/home/git/gitea-dump.zip"
path_working="/home/git/.backup"
path_backup_tmp="/tmp/gitea-dump-*"

# Do backup using gitea
cmd_backup="${gitea} dump "
cmd_backup+="-c ${config_gitea} "
cmd_backup+="-f ${path_backup} "
cmd_backup+="-w ${path_working}"
su -c "${cmd_backup}" - git
if [ $? -ne 0 ]
then
	echo "Error: Creating backup \"${path_backup}\" failed!" >&2
	rm -r "${path_backup_tmp}"
	exit ${EXIT_FAILURE}
fi

# Move backup to target directory
/bin/mv "${path_backup}" "${target_backup}"
if [ $? -ne 0 ]
then
	echo "Error: Moving backup \"${path_backup}\""
		"to \"${target_backup}\" failed!" >&2
	rm -r "${path_backup_tmp}"
	exit ${EXIT_FAILURE}
fi
exit ${EXIT_SUCCESS}
