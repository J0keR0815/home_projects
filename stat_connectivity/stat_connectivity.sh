#!/bin/bash

# Command paths
host="/usr/bin/host"
logger="/usr/bin/logger"
nc="/bin/nc"
timeout="/usr/bin/timeout"

# Globals

# Reference domain name
dn_ref="<DOMAIN_NAME>"

# Reference ip address
ip_ref="<IP_ADDR>"

# timeout for host command
t=10

# Logfile for statistic
flog="/var/log/stat_connectivity"

################# Start #################

# Check if path for logfile is a directory
if [ -d ${flog} ]
then
	${logger} -p syslog.debug -t "stat_connectivity" \
		"${flog} is not a regular file"
	exit 1
fi

# Check if logfile exists
if [ ! -e ${flog} ]
then
	touch ${flog}
	chmod 600 ${flog}
fi

# No Output on STDOUT or STDERR
exec >> ${flog}

# Check connection
date=$(date +"%d.%m.%Y %H:%M")
check=$(${nc} -vnzw $t ${ip_ref} 53 2>&1)
if [ $? -eq 0 ]
then
	echo "[$date]$check"
else
	echo "[$date]Connection to ${ip_ref} cannot be established"
fi

# Check name resolution
check=$(${timeout} -k $t $t ${host} -t A ${dn_ref} 2>&1)
if [ $? -eq 0 ]
then
	echo "[$date]$check"
else
	echo "[$date]Name ${ip_ref} cannot be resolved"
fi

exit 0
