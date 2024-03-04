#!/bin/bash
#
# Usage:	get_dot_cert.sh <ns_ip> <tls_port>

# Timeout for SSL-connection
t=3

# Check arguments
if [ $# -ne 2 ]
then
	echo "Usage: $(basename $0) <ns_ip> <tls_port>" >&2
	exit 1
fi

ip_regex="^(([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}"
ip_regex="${ip_regex}([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
ns_ip=$( \
	echo "$1" | \
	grep -E "${ip_regex}" \
)

if [ -z "${ns_ip}" ]
then
	echo "Usage: $(basename $0) <ns_ip> <tls_port>" >&2
	exit 1
fi

typeset -i tls_port=$(echo "$2" | grep -E "^[0-9]+$")

# Get SSL-information
ssl_info=$( \
	echo | \
	timeout -k $t $t \
		openssl s_client -connect ${ns_ip}:${tls_port} 2>/dev/null \
)
if [ $? -ne 0 ]
then
	echo "Reached timeout connecting to ${ns_ip}:${tls_port}" >&2
	exit 1
fi

# Get sha256-digest
echo "${ssl_info}" | \
	openssl x509 -pubkey -noout | \
	openssl pkey -pubin -outform der | \
	openssl dgst -sha256 -binary | \
	openssl enc -base64

# Get cn for certificate
echo "${ssl_info}" | \
	grep "subject=CN" | \
	cut -d " " -f 3

exit 0
