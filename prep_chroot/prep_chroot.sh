#!/bin/bash
#
# Usage: prepare-chroot.sh <NEWROOT> <PROGRAM1> [<PROGRAM2> ...]
# 
# DESCRIPTION:
# - NEWROOT cannot be "/"

# err_exit() prints error message and exits script with 
# provided exit code.
#
# Usage: err_exit <ERRMSG> <ERRCODE>
#
function err_exit() {
	local err_code=1
	typeset -i err_code

	local err_msg="Usage error: $FUNCNAME <ERRMSG> <ERRCODE>"

	if [ $# -eq 2 ]
	then
		err_code=$2
		err_msg="$1"
	fi

	echo $err_msg
	exit $err_code
}

[ $# -lt 2 ] && \
	err_exit "Usage Error: $0 <NEWROOT> <PROGRAM1> [<PROGRAM2> ...]" 2 >&2

[ $1 == "/" ] && \
	err_exit "Error: NEWROOT cannot be \"/\"" 3 >&2

# Remove trailing "/"
new_root=${1%/}

# Shift 1st commandline argument: progs = [$2, ...]
shift 1
progs=("$@")

# If NEWROOT exists, it cannot be a directory, else it will be created.
if [ -e $new_root ]
then
	[ ! -d $new_root ] && \
		err_exit "Error: \"$new_root\" is a directory!" >&2
else
	mkdir -p $new_root
fi

for prog in "${progs[@]}"
do
	# Check, if $prog exists under directories of $PATH
	prog_path=$(which $prog)
	[ $prog_path == "" ] && \
		err_exit \
			"Error in \"$0\": The program \"$PROGRAM\" does not exist" \
			2 >&2

	# Set default umask
	umask_bk=$(umask -p)
	umask 022

	# Create directory tree for chroot-Jail
	mkdir -p "${new_root}/$(dirname $prog_path)"
	cp $prog_path "${new_root}/${prog_path}"
	
	# Evaluate needed libs for $prog
	libs=($( \
			ldd $prog_path | \
			grep -v 'linux-vdso' | \
			tr -d ' \t' | \
			sed 's/^.*=>\(.*\)/\1/g' | \
			sed 's/^\(.*\)(.*$/\1/g' \
	))
	
	# Copy libs to chroot-jail-directory
	for lib in "${libs[@]}"
	do
		mkdir -p "${new_root}/$(dirname $lib)"
		cp $lib "${new_root}/${lib}"
	done

	# Reset umask
	$umask_bk
done

exit 0
