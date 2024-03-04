#!/bin/bash

config_dokuwiki_backup_data="/etc/dokuwiki/maintenance.conf"
config_dokuwiki_local="/etc/dokuwiki/local.php"

# Load variables from configurations
eval $(cat "${config_dokuwiki_backup_data}")
dir_dokuwiki_data=$( \
	grep 'savedir' ${config_dokuwiki_local} | \
	tr -d " ';" | \
	cut -d '=' -f 2 \
)
dir_dokuwiki_data=${dir_dokuwiki_data%%/}

### Cleanup ###

# purge files older than ${retention_days} days from attic and media_attic (old revisions)
find ${dir_dokuwiki_data}/{media_,}attic/ \
	-type f -mtime +${retention_days} -delete

# remove stale lock files (files which are 1-2 days old)
find ${dir_dokuwiki_data}/locks/ \
	-name '*.lock' -type f -mtime +1 -delete

# remove empty directories
find \
	${dir_dokuwiki_data}/attic/ \
	${dir_dokuwiki_data}/cache/ \
	${dir_dokuwiki_data}/index/ \
	${dir_dokuwiki_data}/locks/ \
	${dir_dokuwiki_data}/media/ \
	${dir_dokuwiki_data}/media_attic/ \
	${dir_dokuwiki_data}/media_meta/ \
	${dir_dokuwiki_data}/meta/ \
	${dir_dokuwiki_data}/pages/ \
	${dir_dokuwiki_data}/tmp/ \
	-mindepth 1 \
	-type d \
	-empty \
	-delete

# remove files older than ${retention_days} days from the cache
if [ -e "${dir_dokuwiki_data}/cache/?/" ]
then
	find ${dir_dokuwiki_data}/cache/?/ \
		-type f -mtime +${retention_days} -delete
fi

# Sync data
/usr/bin/rsync -acv --delete "$dir_dokuwiki_data/" "${target_backup}"
exit $?

