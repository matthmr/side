#!/usr/bin/env bash

case $1 in
	'-h'|'--help')
		echo "Usage:       edit-copy.sh [-e]"
		echo "Description: Uses the editor stored in the \`CLIPEDITOR' variable to edit a copy file.
If run with the \`-e' flag, it edits the latest file copy"
    echo "Variables:
    - CLIPEDITOR: editor-like command
    - XSEL: xsel-command"
		exit 1
		;;
esac

[[ -z $CLIPEDITOR ]] && CLIPEDITOR=emacsxc
[[ -z $XSEL ]] && XSEL=xsel

if [[ $1 = '-e' ]]
then
  xsel --logfile /dev/null --clipboard > /tmp/clipboard
fi

$CLIPEDITOR /tmp/clipboard
xsel --logfile /dev/null --clipboard -i < /tmp/clipboard
