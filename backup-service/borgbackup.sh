#!/bin/bash
#
# Usage: borgbackup.sh <backup1|backup2|storagebox>

config_file=/etc/borgbackup.conf

function err_exit() {
	if [ $# -lt 1 ]
	then
		echo "Usage error: $FUNCNAME <errmsg> [tmpfile]"
	else
		echo $1
	fi

	exit 1
}

function load_ssh_key() {
	# Start SSH-agent and add SSH-key to the agent
	eval $($ssh_agent -s)
expect << EOF
	spawn $ssh_add $ssh_key
	expect "Enter passphrase for key \'$ssh_key\': "
	send -- "$ssh_key_pass\r"
	expect eof
EOF
}

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=""
if [ $# -ne 1 ]
then
	err_exit "Usage Error: $0 <backup1|backup2|storagebox>" >&2
else
	case $1 in
		backup1|backup2)
			export BORG_REPO="/mnt/crypto-dev_$1/$1"
			;;
		storagebox)
			# Load configuration and SSH-key into ssh-agent
			eval $(grep -v "^#" $config_file)
			load_ssh_key
			;;
		*)
			err_exit "Usage Error: $0 <backup1|backup2|storagebox>" >&2
			;;
	esac
fi

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" | tee -a /var/log/borgbackup.log; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

borg create \
    --verbose \
    --filter AME \
    --list \
    --stats \
    --show-rc \
    --compression auto,zlib,6 \
    --exclude-caches \
    ::"$1-storage-{now}" \
    /mnt/storage/DIR1 \
     /mnt/storage/DIR2 \
    2>&1 | tee -a /var/log/borgbackup.log

backup_exit=$?

info "Pruning repository"

borg prune \
    --list \
    --glob-archives "$1-storage-*" \
    --show-rc \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 3 \
    2>&1 | tee -a /var/log/borgbackup.log

prune_exit=$?

if [ ! -z $SSH_AGENT_PID ]
then
	$ssh_add -D
	kill $SSH_AGENT_PID
fi

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 1 ];
then
    info "Backup and/or Prune finished with a warning"
fi

if [ ${global_exit} -gt 1 ];
then
    info "Backup and/or Prune finished with an error"
fi

exit ${global_exit}
