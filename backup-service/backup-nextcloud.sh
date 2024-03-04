#!/bin/bash

path_config_backup="/etc/nextcloud/backup.conf"
path_app="/var/www/nextcloud"
path_config_app="${path_app}/config/config.php"
path_backup_tmp="/tmp/backup_nextcloud-$(date +"%Y%m%d")"
path_backup_db="${path_backup_tmp}/nextcloud-db.bak"
path_backup_app="${path_backup_tmp}/nextcloud"
path_backup_data="${path_backup_tmp}/data"
path_backup_arch="${path_backup_tmp}/backup_nextcloud.tar.bz2"

declare -A config_app

function error() {
	local msg="Error: $*"
	/usr/bin/logger -p syslog.err -t "backup-nextcloud" "${msg}"
	[ -d "${path_backup_tmp}" ] && rm -r "${path_backup_tmp}"
	exit 1
}

function log() {
	local msg="Info: $*"
	/usr/bin/logger -p syslog.info -t "backup-nextcloud" "${msg}"
}

function parse_config_app() {
	config_app=(
		[datadirectory]=""
		[dbtype]=""
		[dbname]=""
		[mysql.utf8mb4]=""
	)
	for key in "${!config_app[@]}"
	do
		config_app["$key"]="$( \
			grep "$key" ${path_config_app} | \
			sed "s/^.*=> \(.*\),$/\1/g" | \
			tr -d "\'" \
		)"
		
		if [ "${key}" != "mysql.utf8mb4" -a ${PIPESTATUS[0]} -ne 0 ]
		then
			return -1
		fi
	done
	
	if [ "${config_app["dbtype"]}" != "mysql" ]
	then
		unset config_app["mysql.utf8mb4"]
	fi

	return 0
}

function parse_config_backup() {
	local keys=(
		"dir_backup"
		"pw_enc"
	)
	. ${path_config_backup}
	for key in "${keys[@]}"
	do
		compgen -v | grep -q "${key}"
		if [ $? -ne 0 ]
		then
			return -1
		fi
	done

	return 0
}

function print_config_app() {
	for key in "${!config_app[@]}"
	do
		echo "${key} => ${config_app[$key]}"
	done
}

##### BEGIN #####

log "Starting Nextcloud backup ..."

log "Loading variables from backup configuration ..."
parse_config_backup
if [ $? -ne 0 ]
then
	error "Could not load config \"${path_config_backup}\"!"
fi

log "Loading config of nextcloud application ..."
parse_config_app
if [ $? -ne 0 ]
then
	error "Reading configuration \"${path_config_app}\" failed"
fi

log "Creating temporary backup directory \"${path_backup_tmp}\" ..."
mkdir "${path_backup_tmp}"
if [ $? -ne 0 ]
then
	error "Creating temporary directory" \
		"\"${path_backup_tmp}\" failed"
fi

log "Checking database type ..."
case "${config_app["dbtype"]}" in
	"mysql")
		opts="--single-transaction"
		if [ "${config_app["mysql.utf8mb4"]}" == "true" ]
		then
			opts="${opts} --default-character-set=utf8mb4"
		fi
		
		log "Database type is \"${config_app["dbtype"]}\":" \
			"Creating database backup ..."
		/usr/bin/mysqldump ${opts} \
			${config_app["dbname"]} > \
			"${path_backup_db}"
		if [ $? -ne 0 ]
		then
			error "Creating database backup failed"
		fi
		;;
	*)
		error "Invalid database type \"${config_app["dbtype"]}\""
		;;
esac

log "Creating backup of application directory \"${path_app}\"" \
	"in \"${path_backup_app}\" ..."
/usr/bin/rsync -a "${path_app}/" "${path_backup_app}"
if [ $? -ne 0 ]
then
	error "Creating backup of application directory failed"
fi

log "Creating backup of data directory" \
	"\"${config_app["datadirectory"]}\"" \
	"in \"${path_backup_data}\" ..."
/usr/bin/rsync -a \
	"${config_app["datadirectory"]}/" \
	"${path_backup_data}"
if [ $? -ne 0 ]
then
	error "Creating backup of data directory failed"
fi

log "Creating compressed backup archive \"${path_backup_arch}\" ..."
/usr/bin/tar -cjf "${path_backup_arch}" \
	"${path_backup_db}" \
	"${path_backup_app}" \
	"${path_backup_data}"
if [ $? -ne 0 ]
then
	error "Creating archive of backup failed"
fi

log "Encrypting backup archive ..."
# For decryption run:
#
# gpg --output <decrypted_file> \
#       --batch \
#       --yes \
#       --passphrase <pw> \
#       --decrypt <encrypted_file>
#
/usr/bin/gpg --cipher-algo AES256 \
	--symmetric \
	--passphrase "${pw_enc}" \
	--batch \
	--yes \
	--output "${path_backup_arch}.gpg" \
	"${path_backup_arch}"
if [ $? -ne 0 ]
then
	error "Creating encrypted backup failed"
fi

log "Transferring backup to backup-share ..."
mv "${path_backup_arch}.gpg" "${dir_backup}/"

log "Removing temporary backup directory \"${path_backup_tmp}\" ..."
rm -r "${path_backup_tmp}"
if [ $? -ne 0 ]
then
	error "Deleting \"${path_backup_tmp}\" failed"
fi

log "Done!"
exit 0
