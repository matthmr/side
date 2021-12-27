#!/usr/bin/env bash
# Made by mH (https://github.com/matthmr)

#*****************************************************
# change anything that is followed by "#change this" #
#*****************************************************

# td: a framework for working with the linux tmpfs

TMP=/tmp # change this
LOCKFILE=$TMP/td.lock # change this

VERSION="v0.2.2"

### BEGIN ABOUT ###
function about {
		printf "\nMade by mH (https://github.com/matthmr)
	td\t\t\t => A framework for tmpfs usage\n
Usage:\ttd sync [file] -a [name] => Instantiates a file to the tmpfs
\ttd wrap [CMD]    @[name] => Wraps an instance with a command
\ttd diff @[name]\t\t => Diffs against an instance
\ttd rm   @[name]\t\t => Removes an instance from the tmpfs
\ttd rs   @[name]\t\t => Restores an instance from the tmpfs

\ttd kill\t\t\t => Kills all instances
\ttd ls\t\t\t => Lists all instances

Info:\ttd status\t\t => Displays whether there is a lockfile
	td [--help/-h]\t\t => Displays this message and exits
	td [--version/-v]\t => Displays the version and exits

Note:\tNot scriptsd compliant yet, default tmpfs is $TMP
\n"
}
### END ABOUT ###

case $1 in
	'--help'|'-h')
		about
		exit 0;;

	'--version'|'-v')
		printf "td $VERSION\n"
		exit 0;;
esac

### BEGIN UTILITIES ###
function usage {
	printf "[ !! ] Bad usage. See td --help\n"
	exit 1
}

function ensure-lock {
	if [ ! -f $LOCKFILE ]; then
		touch $LOCKFILE
	fi
}

function check-lockfile {
	if [ ! -f $LOCKFILE ]; then
		printf "[ !! ] No lockfile found. Did you run 'td sync'?\n"
		exit 1
	fi
}

function prevent-under {
	if [[ $2 -lt  $1 ]]; then
		usage
		exit 1
	fi
}

function prevent-over {
	if [[ $2 -gt  $1 ]]; then
		usage
		exit 1
	fi
}

function resolute {
	ENTRY=$1
	ENTRYBASE=$(echo $ENTRY | cut -f 1 -d '/')

	[[ "$ENTRY" == "$ENTRYBASE" ]] &&
		FROM=$(grep -w "$ENTRY\$" $LOCKFILE | awk '{print $1}') ||
		FROM=$(grep -w "$ENTRYBASE\$" $LOCKFILE | awk '{print $1}')

	if [[ -z "$FROM" ]]; then
		if [[ "$ENTRY" == "$ENTRYBASE" ]]; then
			printf "[ !! ] No origin file for '$ENTRY'\n"
			exit 1
		else
			printf "[ !! ] No origin file for '$ENTRYBASE'\n"
			exit 1
		fi
	else
		echo $FROM
	fi
}

function lock {

	case $1 in

		'add') # [origfile] [entry]

			ensure-lock

			ORIGFILE=$2
			ENTRY=$3

			EXISTING=$(awk '{print $2}' $LOCKFILE | grep "$ENTRY")
			EXISTING_ORIGIN=$(grep "$ENTRY" $LOCKFILE | awk '{print $1}')

			if [[ -n "$EXISTING" ]]; then
				if [[ "$ORIGFILE" != "$EXISTING_ORIGIN" ]]; then
					printf "[ !! ] '$ENTRY' already exists with a different origin file\n"
					exit 1
				else
					printf "[ OK ] Updated '$ENTRY'\n"
					cp -r $ORIGFILE $TMP/$ENTRY
					return 1
				fi
			fi

			echo "$ORIGFILE $ENTRY" >> $LOCKFILE;;

		'rm') # [entry]
			ENTRY=$2

			ENTRYBASE=$(echo $ENTRY | cut -f 1 -d '/')

			if [[ "$ENTRY" == "$ENTRYBASE" ]]; then

				LINE=$(cat $LOCKFILE | awk '{print $2}' | grep -nw "$ENTRY\$" | cut -f1 -d:)

				if [[ -z $LINE ]]; then
					printf "[ !! ] No instance '$ENTRY' found in '$TMP'\n"
					exit 1

				else
					sed -i "$LINE"d $LOCKFILE
				fi
			else
				local file=$(cat $LOCKFILE | awk '{print $2}' | grep -nw "$ENTRYBASE\$" | cut -f1 -d:)

				[[ -z "$file" ]] &&
					printf "[ !! ] No sub-instance '$ENTRY' found in '$ENTRYBASE'\n"

			fi;;

		'del') # []
			[ ! -f $LOCKFILE ] && {
				echo [ !! ] No lockfile found
				exit 1
			}

			while read line; do
				ENTRIES="$ENTRIES $(echo $line | awk '{print $2}')"
			done < $LOCKFILE

			pushd $TMP &>/dev/null

			rm -rf $ENTRIES  2>/dev/null
			rm -f  $LOCKFILE;;

	esac
}
### END UTILITIES ###

[[ $# = 0 ]] && usage && exit 1

### BEGIN FUNCTIONALITY ###
# td sync [path] -a [name]
function sync {

	prevent-over  5 $#

	case $# in
	'3'|'2')

		[[ $# == 2 ]] && {
			FILE=$PWD
			FLAG=$1
			VALUE=$2
		} || {
			FILE=$1
			FLAG=$2
			VALUE=$3
		}

		if [[ $FLAG == '-a' ]]; then
			ORIGFILE=$(readlink --canonicalize $FILE 2>/dev/null)
			ENTRY="@$VALUE"

		else
			usage
			exit 1
		fi;;

	'1'|'0')
		[[ $# == 1 ]] && FILE=$1 || FILE=$PWD

		ORIGFILE=$(readlink --canonicalize "$FILE" 2>/dev/null)
		ENTRY="@$(basename $ORIGFILE)";;

	*)
		usage
		exit 1;;
	esac

	lock add $ORIGFILE $ENTRY && {

		cp -r $ORIGFILE $TMP/$ENTRY && {
				echo [ OK ] Instantiated \'$ORIGFILE\' in \'$TMP\' as \'$ENTRY\' ||
				echo [ !! ] Couldn\'t instantiate \'$ORIGFILE\'
		}

	}
}

# td { rm [@name], rs [@name] }
function wrap-arround {

	prevent-over 2 $#
	prevent-under 1 $#

	check-lockfile

	ENTRY=$2

	if [[ ${ENTRY::1} != '@' ]]; then
		printf "[ !! ] Wrong format. See td --help\n"
		exit 1
	fi

	if [[ $1 == 'remove' ]]; then
		rm -rf $TMP/$ENTRY && echo [ OK ] Removed \'$ENTRY\' from \'$TMP\' || echo [ !! ] Couldn\'t remove \'$ENTRY\'

	elif [[ $1 == 'restore' ]]; then
		mv $TMP/$ENTRY $(resolute $ENTRY) && echo [ OK ] Restored \'$ENTRY\' from \'$TMP\' || echo [ !! ] Couldn\'t restore \'$ENTRY\'

	fi

	lock rm $ENTRY

}

# td ls
function list {

	prevent-over 0 $#

	check-lockfile
	cat $LOCKFILE | sed 's/ / -> /g' | sed "s/\-> $/\-> ${TMP//\//\\/}/g"
}

# td wrap [CMD] [@name]
function wrap {
	check-lockfile

	ENTRY=${@:(-1)}
	COMMAND=${@//$ENTRY/}

	if [[ ${ENTRY::1} != '@' ]]; then
		printf "[ !! ] Wrong format. See td --help\n"
		exit 1
	fi

	if [[ -z $ENTRY || -z $COMMAND ]]; then
		usage
		exit 1
	fi

	$COMMAND $TMP/$ENTRY
}

# td diff [@name]
function diff {

	prevent-over 1 $#

	check-lockfile
	
	ENTRY=$1

	if [[ ${ENTRY::1} != '@' ]]; then
		printf "[ !! ] Wrong format. See td --help\n"
		exit 1
	fi

	if [[ -z $ENTRY ]]; then
		usage
		exit 1
	fi

	ORIGFILE=$(resolute $ENTRY)

	[[ -z $ORIGFILE ]] && printf "[ !! ] No origin file for '$ENTRY'\n" && exit 1

	$(which diff) --color -u $TMP/$ENTRY $ORIGFILE
}
### END FUNCTIONALITY ###

case $1 in

	'status') # done
		[ -f $LOCKFILE ] &&
		echo [ OK ] lockfile found || {
			echo [ !! ] No lockfile found
			exit 1
		};;

	'kill') # done
		lock del && echo [ OK ] Cleaned \'$TMP\', removed lockfile
		popd &>/dev/null
		exit 0;;

	'sync') # done
		sync ${@:2};;

	'diff') # done
		diff ${@:2};;

	'wrap') # done
		wrap ${@:2};;

	'ls') # done
		list ${@:2};;

	'rm') # done
		wrap-arround remove ${@:2};;

	'rs') # done
		wrap-arround restore ${@:2};;

	*)
		usage
		exit 1;;

esac

[[ -z "$(cat $LOCKFILE)" ]] && rm -rf $LOCKFILE
