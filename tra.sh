#!/usr/bin/sh
# Made by mH (https://github.com/matthmr)

# Fallbacks
MAXTIME=30 # in days; change this to the amount you want
trash=$HOME/.trash # standard trash; i'm not gonna be bothered to make this dynamic

function datediff {
	local date=$(( ($1 - $2) / 86400 )) # in days
	echo $date
}

[[ $# = 1 ]] && {
	case $1 in
		'init')
			[ ! -d $trash ] && {
				mkdir -p $trash
				touch $trash/CLEANME
				printf "[ OK ] \033[32mOK\033[0m: Initialize a tra.sh instance at $trash\n"
				exit 0
			} || {
				alrfiles=$(ls -A1 ~/.trash)
				date=$(date -d "+$MAXTIME days" +%s)

				while read file; do
					TRASHFILE="$TRASHFILE$file: $date\n"
				done <<< "$(echo -e "$alrfiles")"

				printf "$TRASHFILE" > $trash/CLEANME
				printf "[ OK ] \033[32mOK\033[0m: Initialize a tra.sh instance at existing $trash\n"
				exit 0
			};;

		'clean')
			FILE=$(cat $trash/CLEANME)

			while read line; do
				file=$(echo $line | cut -d ':' -f 1)
				rm -r $trash/$file
			done <<< "$(echo -e "$FILE")"

			printf "" > $trash/CLEANME
			printf "[ OK ] \033[32mOK\033[0m: $trash cleaned\n"

			exit 0;;

		'update')
			FILE=$(cat $trash/CLEANME)
			now=$(date -d 'now' +%s)

			while read line; do
				file=$(echo $line | cut -d ':' -f 1)
				date=$(echo $line | cut -d ':' -f 2)
				[[ $date -le 0 ]] && {
					rm $trash/$file
				}
			done <<< "$(echo -e "$FILE")"

			printf "[ OK ] \033[32mOK\033[0m: $trash updated\n"

			exit 0;;

		'--help'|'-h')
			printf "Made by mH (https://github.com/matthmr)
	tra.sh\t\t\t => Recycle bin for linux\n
Usage:\ttra.sh del        [file] => (Permanently) deletes a file
	tra.sh send       [file] => Sends a file to trash
	tra.sh restore    [file] => Restores a file
	tra.sh init              => Creates a recycle bin
	tra.sh update          \t => Updates bin. Files over 1 Month are deleted
	tra.sh clean\t\t => Cleans bin\n
Info:\ttra.sh [--help/-h]\t => Displays this message and exit
	tra.sh [--version/-v]\t => Displays version and exits\n
Note:\tThe default [dir] is $trash
\n"
			exit 0;;

		'--version'|'-v')
			printf "tra.sh v0.1.0\n"
			exit 0;;

		*)
			printf "[ !! ] \033[31mErr\033[0m: Bad usage. See tra.sh --help\n"
			exit 1;;
	esac
}

[[ $# = '2' ]] && {
	case $1 in
		'del')
			FILE=$(cat $trash/CLEANME)
			LINE=0

			while read line; do

				LINE=$(($LINE + 1))
				file=$(echo $line | cut -d ':' -f 1)
				[[ "$file" = $2 ]] && {
					[ -f $trash/$file ] && rm -r $trash/$file
					sed -i "$LINE"d  $trash/CLEANME
					break
				}
			done <<< "$(echo -e "$FILE")"

			printf "[ OK ] \033[32mOK\033[0m: $2 removed from $trash\n"

			exit 0;;

		'send')
			file=$(basename $2)
			date=$(date -d "+$MAXTIME days" +%s)
			mv $2 $trash
			printf "$file: $date: $(readlink --canonicalize $2)\n" >> $trash/CLEANME
			printf "[ OK ] \033[32mOK\033[0m: done\n"
			;;

		'restore')
			FILE=$(cat $trash/CLEANME)
			LINE=0

			while read line; do

				LINE=$(($LINE + 1))
				file=$(echo $line | cut -d ':' -f 1)
				path=$(echo $line | cut -d ':' -f 3)
				[[ "$file" = $2 ]] && {
					[ -f $trash/$file ] && mv $trash/$file $path
					sed -i "$LINE"d  $trash/CLEANME
					break
				}
			done <<< "$(echo -e "$FILE")"

			printf "[ OK ] \033[32mOK\033[0m: $2 restored\n"

			exit 0;;

		*)
			printf "[ !! ] \033[31mErr\033[0m: Bad usage. See tra.sh --help\n"
			exit 1;;
	esac
} || {
	printf "[ !! ] \033[31mErr\033[0m: Bad usage. See tra.sh --help\n"
	exit 1
}
