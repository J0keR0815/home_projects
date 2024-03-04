#!/bin/bash

# Databases to check
dbs=("./pwdb.kdbx" "./pwdb2.kdbx")

# Maximal number of threads
t_max=20

# File where the results are written to
file_results="./results"

# File containing the wordlist
file_wordlist="./wordlist"

# Checks if a password can be used for the password database
# param1: password
# param2: database
function try_password() {
	# Parameter 1 and 2 must be set
	[ -z "${1}" ] && return 255
	[ -z "${2}" ] && return 255

	local pw="$1"
	local db="$2"

	# Check password
	echo "$pw" | keepassxc-cli open -q "$db"

	if [ $? -eq 0 ]
	then
		# Password found: Set flag, write result and return 0
		found=1
		echo "${db}:${pw}" >> ${file_results}
		return 0
	else
		# Password not found: Return 1
		return 1
	fi
}

##### BEGIN #####

# Get number of wordlist entries
n_wordlist_entries=$(cat ${file_wordlist} | wc -l)

# Try to crack each database
for db in "${dbs[@]}"
do
	echo "Trying to find password for database \"${db}\"" \
		"using wordlist \"${file_wordlist}\" ..."

	# Thread counter
	t=0

	# Flag which is set if password was found
	found=0

	# Read password wordlist and check if a password can be used
	# for the password database
	while read pw
	do
		# Increment thread counter and check password
		# If password was found end this loop
		t=$(( $t + 1 ))
		try_password "$pw" "$db" &
		[ ${found} -ne 0 ] && break

		# Check if thread counter exceeds maximal number of threads
		# In this case print the counter and wait for all running
		# threads to finish
		if [ $(( $t % ${t_max} )) -eq 0 ]
		then
			echo "... ${t}/${n_wordlist_entries} tries"
			wait
		fi
	done < ${file_wordlist}

	# Password found or all passwords tried: Wait for all threads to finish
	wait

	# Print result
	if [ ${found} -eq 0 ]
	then
		echo "Finished: No password found!"
	else
		echo "Finished: Password found! See resultfile \"${file_results}\""
	fi
done
