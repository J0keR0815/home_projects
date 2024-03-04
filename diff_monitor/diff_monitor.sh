#!/bin/bash

function usage() {
	cat <<- EOF
		Usage:
		
		diff_monitor.sh init <dir> [output]
		diff_monitor.sh diff <dir> <initfile> [output]
	EOF
}

function err_exit() {
	local err=255

	if [ $# -eq 1 ]
	then
		if [ $1 -eq 1 ]
		then
			usage 2>&1
			exit $1
		fi
	fi

	if [ $# -eq 2 ]
	then
		if [ $1 -gt 1 ]
		then
			echo "Error in $(basename $0): $2" 2>&1
			exit $1
		fi
	fi
	
	echo "Usage: $FUNCNAME <err> [errmsg]" 2>&1
	exit $err
}

[ $# -lt 2 ] && err_exit 1

case $1 in
	init)
		dir=$2
		[ ! -d $dir ] && err_exit 2 "\"$dir does not exist\""

		[ $# -gt 3 ] && err_exit 1
		
		fout="out.txt"
		[ $# -eq 3 ] && fout=$3

		while read path
		do
			echo $(sha256sum "$path") >> $fout
		done < <( find $dir -xdev -type f )
		;;
	diff)
		dir=$2
		[ ! -d $dir ] && err_exit 2 "\"$dir does not exist\""

		[ $# -lt 3 -o $# -gt 4 ] && err_exit 1

		finit=$3
		[ ! -f $finit ] && err_exit 3 "\"$finit\" does not exist"
		
		fout="diff.txt"
		[ $# -eq 4 ] && fout=$4
		
		ftemp=$(mktemp)
		while read path
		do
			echo $(sha256sum "$path") >> $ftemp
		done < <( find $dir -xdev -type f )
		diff $finit $ftemp > $fout
		rm $ftemp
		;;
	*)
		err_exit 1
		;;
esac

exit 0
