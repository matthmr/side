#!/usr/bin/env bash
# Made by mH (https://github.com/matthmr)

#*****************************************************
# change anything that is followed by "#change this" #
#*****************************************************

# tra.sh: recycle bin for linux

# Fallbacks
MAXTIME_DAYS=30 # change this
trash=/home/$USER/.trash # change this
#                   ... unless I've made this scriptsd compliant
#                   ... in which case download that instead

VERSION="v0.2.0"

### BEGIN ABOUT ###
function about {
		printf "\nMade by mH (https://github.com/matthmr)
	tra.sh\t\t\t\t => Recycle bin for linux\n
Usage:\ttra.sh remove  [file] [-a alias] [-t trash]
	\t\t\t\t \`- (Permanently) deletes a file
	tra.sh send    [file] [-a alias] [-t trash]
	\t\t\t\t \`- Sends a file to trash, with an alias if passed through
	tra.sh restore [file] [-a alias] [-t trash]
	\t\t\t\t \`- Restores a file

	tra.sh init    [dir]  \t\t => Instanciates a recycle bin
	tra.sh list    [dir]  \t\t => Lists files in trash with their aliases
	tra.sh update  [dir]  \t\t => Updates bin. Files over $MAXTIME_DAYS days are deleted
	tra.sh clean   [dir]  \t\t => Cleans bin\n
Info:\ttra.sh [--help/-h]\t\t => Displays this message and exit
	tra.sh [--version/-v]\t\t => Displays version and exits\n
Note:\tThe default [trash] is $trash
     \tAll commands have shortcuts. See tra.sh short
\n"
}

function shortcut {
	printf "\nShortcuts:
	remove  => rm
	send    => s
	restore => rs
	init    => i
	list    => ls
	update  => up
	clean   => c
	short   => smol\n
"
}
### END ABOUT ###

### BEGIN UTILITIES ###
function diff_date {
	local date=$(( ($1 - $2) / 86400 )) # in days
	echo $date
}

function usage {
	printf "[ !! ] Bad usage. See tra.sh --help\n"
	exit 1
}

function die {
	printf "[ !! ] Nothing was done. See tra.sh --help\n"
	exit 1
}

function hotfixnotrash {
	read -p ans "[ !! ] No trash at $trash. Make one? [Y/n]"
	if [[ $ans = [Yy][Ee][Ss] || ! $ans ]]; then
		init $trash
	else
		die
	fi
}

function prevent_under {
	if (( $1 < $2 )); then $3; fi
}

function prevent_over {
	if (( $1 > $2 )); then $3; fi
}
### END UTILITIES ###

[[ $# = 0 ]] && usage && exit 1

### BEGIN FUNCTIONALITY ###
# tra.sh remove [file] [-a alias] [-f trash]
function remove {
	prevent_under $# 2 'usage'
	prevent_over  $# 6 'usage'

	has_alias=false

	if [[ $# = 2 ]]; then
		if [ ! -d $trash ]; then
			hotfixnotrash
			if [ ! -f $trash/.trash ]; then
				init $trash
			fi
		fi
	fi

	if [[ $# -ge 4 ]]; then
		[[ $3 = '-a' ]] || usage
		_alias=$4
		has_alias=true
	fi

	if  [[ $# -ge 6 ]]; then
		[[ $5 = '-f' ]] || usage
		trash=$6
	fi

	trashfile=$trash/.trash

	[ ! -f $trashfile ] && die

	lineno=1

	file=$2

	while read line; do
		__file=$(echo $line | grep -o 'file:.*;' | cut -d ':' -f 2 | cut -d ';' -f 1 | sed 's/;//g')
		__file=${__file/ /}
		__alias=$(echo $line | grep -o 'alias:.*$' | cut -d ':' -f 2 | sed 's/;//g')
		__alias=${__alias/ /}

		if [[ $has_alias = false ]]; then
			if [[ $__file == $file ]]; then
				rm -r $trash/$__file 2>/dev/null && {
					sed -in "$lineno"d $trashfile
					printf "[ OK ] removed $__file from $trash\n"
					exit 0
				} || die
			fi
		elif [[ $__alias == $_alias ]]; then
			rm -r $trash/$__file 2>/dev/null && {
				sed -in "$lineno"d $trashfile
				printf "[ OK ] removed $__file from $trash\n"
				exit 0
			} || die
		fi

		lineno=$(($lineno+1))
	done <<< $(cat $trashfile)

	printf "[ !! ] No matches found in $trash. Nothing was done\n"

}

# tra.sh send [file] [-a alias] [-f trash]
function send {
	prevent_under $# 2 'usage'
	prevent_over  $# 6 'usage'

	if [[ $# = 2 ]]; then
		if [ ! -d $trash ]; then
			hotfixnotrash
			if [ ! -f $trash/.trash ]; then
				init $trash
			fi
		fi
	fi

	if [[ $# -ge 4 ]]; then
		[[ $3 = '-a' ]] || usage
		_alias=$4
	fi

	if  [[ $# -ge 6 ]]; then
		[[ $5 = '-f' ]] || usage
		trash=$6
	fi

	file=$(basename $2)
	expire=$(date -d "+$MAXTIME_DAYS days" +%s)

	mv $2 $trash 2> /dev/null || die
	printf "file: $file; from: $(dirname $(readlink --canonicalize $2)); exp: $expire; alias: $_alias\n" >> $trash/.trash
	printf "[ OK ] moved $file into $trash\n"

}

# tra.sh restore [file] [-a alias] [-t trash]
function restore {
	prevent_under $# 2 'usage'
	prevent_over  $# 6 'usage'

	has_alias=false

	if [[ $# = 2 ]]; then
		if [ ! -d $trash ]; then
			hotfixnotrash
			if [ ! -f $trash/.trash ]; then
				init $trash
			fi
		fi
	fi

	if [[ $# -ge 4 ]]; then
		[[ $3 = '-a' ]] || usage
		_alias=$4
		has_alias=true
	fi

	if  [[ $# -ge 6 ]]; then
		[[ $5 = '-f' ]] || usage
		trash=$6
	fi

	trashfile=$trash/.trash

	[ ! -f $trashfile ] && die

	lineno=1

	file=$2

	while read line; do
		__file=$(echo $line | grep -o 'file:.*;' | cut -d ':' -f 2 | cut -d ';' -f 1 | sed 's/;//g')
		__file=${__file/ /}
		__from=$(echo $line | grep -o 'from:.*;' | cut -d ':' -f 2 | cut -d ';' -f 1 | sed 's/;//g')
		__from=${__from/ /}
		__alias=$(echo $line | grep -o 'alias:.*$' | cut -d ':' -f 2 | sed 's/;//g')
		__alias=${__alias/ /}

		if [[ $has_alias = false ]]; then
			if [[ $__file == $file ]]; then
				mv $trash/$__file $__from 2>/dev/null && {
					printf "[ OK ] restored $__file from $trash\n"
					sed -in "$lineno"d $trashfile
					exit 0
				} || die
			fi
		elif [[ $__alias == $_alias ]]; then
			mv $trash/$__file $__from 2>/dev/null && {
				printf "[ OK ] restored $__file from $trash\n"
				sed -in "$lineno"d $trashfile
				exit 0
			} || die
		fi

		lineno=$(($lineno+1))
	done <<< $(cat $trashfile)

	printf "[ !! ] No matches found in $trash. Nothing was done\n"
}

# tra.sh init [dir]
function init {
	if (( $# > 2 )); then usage && exit 1; fi
	[ ! $2 ] && trash=$trash || trash=$2

	[ ! -d $trash ] && {
		trash=$trash
		mkdir -p $trash
		touch $trash/.trash
		printf "[ OK ] Initialize a tra.sh instance at $trash\n"
		exit 0
	} || {
		existing_files=$(ls -A1 $trash)
		expire=$(date -d "+$MAXTIME_DAYS days" +%s)
		static_alias=0

		while read file; do
			[ ! $file ] && continue
			static_alias=$(($static_alias+1))
			TRASH_ENTRY="$TRASH_ENTRY\nfile: ; from: ; exp: $expire; alias: $static_alias;"
		done <<< "$(echo -e "$existing_files")"

		printf "$TRASH_ENTRY" > $trash/.trash
		printf "[ OK ] Initialize a tra.sh instance at existing $trash; reseting expire dates & restore data\n"
		exit 0
	}
}

# tra.sh list [dir]
function list {
	prevent_over $# 2 'usage'
	if [[ $# = 2 ]]; then
		if [ ! -d $2 ]; then
			die
		else
		trash=$2
		fi
	fi

	trashfile=$trash/.trash

	[ ! -f $trashfile ] && die

	while read line; do

		__file=$(echo $line | grep -o 'file:.*;' | cut -d ':' -f 2 | cut -d ';' -f 1 | sed 's/;//g')
		__file=${__file/ /}
		__alias=$(echo $line | grep -o 'alias:.*$' | cut -d ':' -f 2 | sed 's/;//g')
		__alias=${__alias/ /}

		echo file: $__file, alias: $__alias

	done <<< $(cat $trashfile)

}

# tra.sh update [dir]
function update {
	prevent_over $# 2 'usage'
	if [[ $# = 2 ]]; then
		if [ ! -d $2 ]; then
			die
		else
		trash=$2
		fi
	fi

	trashfile=$trash/.trash

	[ ! -f $trashfile ] && die

	while read line; do

		__exp=$(echo $line | grep -o 'exp:.*;' | cut -d ':' -f 2 | cut -d ';' -f 1 | sed 's/;//g')
		__exp=${__exp/ /}
		__file=$(echo $line | grep -o 'file:.*;' | cut -d ':' -f 2 | cut -d ';' -f 1 | sed 's/;//g')
		__file=${__file/ /}

		today=$(date +%s)

		diff=$(diff_date $__exp $today)

		if (( $diff <= 0 )); then
			printf "[ OK ] $__file was removed\n"
			remove $__file
		fi

	done <<< $(cat $trashfile)
	printf "[ !! ] $trash is already clean. Nothing was done\n"
}

# tra.sh clean [dir]
function clean {
	
	prevent_over $# 2 'usage'

	if (( $# <= 2 )); then
		_trash=$2; [ ! $_trash ] && _trash=$trash
		[ ! -d $_trash ] && die
	fi

	[[ ! $(ls $_trash) ]] && printf "[ !! ] $_trash is already clean. Nothing was done\n" && exit 1

	rm -r $_trash/*
	rm -r $_trash/.* 2> /dev/null

	printf "" > $_trash/.trash
	printf "[ OK ] $_trash cleaned\n"

}
### END FUNCTIONALITY ###

case $1 in
	'remove'|'rm')
		remove $@
		exit 0;;

	'send'|'s')
		send $@
		exit 0;;

	'restore'|'rs')
		restore $@
		exit 0;;

	'init'|'i')
		init $@
		exit 0;;

	'list'|'ls')
		list $@
		exit 0;;

	'update'|'up')
		update $@
		exit 0;;

	'clean'|'c')
		clean $@
		exit 0;;

	'short'|'smol')
		shortcut
		exit 0;;

	'--help'|'-h')
		about
		exit 0;;

	'--version'|'-v')
		printf "tra.sh $VERSION\n"
		exit 0;;

	*)
		usage
		exit 1;;
esac
