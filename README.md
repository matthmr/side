# Side projects
Just lil' pointless things, mostly scripts that are too useless to be on [scripts.d](https://github.com/matthmr/scripts) (check it out, by the way).

## tra.sh
For you Windows®©™ peeps who miss the recycle bin from that ***GOD-FORBIDDEN*** operating system.
### Installation and usage:
- put `tra.sh` into a `$PATH` directory (/usr/local/bin, for example).
- run `tra.sh init` or `tra.sh init [dir]` to instanciate a `tra.sh` directory.
- `tra.sh send [file]` or `tra.sh s [file]` to send, add the `-a` flag to pass an alias, as in:
```sh
tra.sh send file -a trash
# so that you can do
tra.sh rm \; -a trash
# and not have to remeber the full name of the file
```
- `tra.sh remove [file]` or `trash rm [file]` to remove.
- `tra.sh list` or `tra.sh ls` to list.
- `tra.sh restore [file]` ot `tra.sh rs [file]` to restore; also supports the `-a` flag.
- `tra.sh update` or `tra.sh up` to delete files **older** than a month (that can be changed by changing the `MAXTIME_DAYS` variable. This script is **NOT** scriptsd compliant (yet)).
- `tra.sh clean` or `tra.sh c` to clean **all** files.


## unit
"Unit test" with a shell script. Change `TESTS` to get proper testing and use `unit-template` as your unit.
This is **not** scriptsd compliant (yet).

## ffl
[unit](#unit) integration with [fzf](https://github.com/junegunn/fzf).

## orx
[clipmenu](https://github.com/cdown/clipmenu) integration with [xbindkeys](git://git.savannah.nongnu.org/xbindkeys.git/).
This was created because [X11](https://x.org/wiki) clears the clipboard when a window closes. This is **extremely** frustating (although being the intended behaviour) for tiling window manager users such as myself.
### Installation and usage:
- put `orx` into a `$PATH` directory (/usr/local/bin, for example).
- copy the contents of `orx.xbindkeysrc` to `~/.xbindkeysrc`.
- restart the `xbindkeys` daemon.
- `CRTL-ALT-V` to send the copy content to a memory buffer using `xsel`, then `CTRL-V` to paste (duh).

## ffc
[clipmenu](https://github.com/cdown/clipmenu) integration with [fzf](https://github.com/junegunn/fzf).
This is intended to execute a command with the cache file generated by clipmenu or with the content of that clip itself.

## down
A system update locker. Change the source to put in your shell and package manager for that to work. Also this is not `scriptsd` compliant.

## td
A framework for working with the tmpfs.
### Installation and usage:
- copy the `td` script to a `$PATH` directory
- run `td sync [file] -a [name]` to sync a file or directory as an instance.
- `td wrap [CMD] @[name]` to wrap an instance with a command.
- `td diff @[name]` to diff an instance.
- `td rm @[name]` to remove.
- `td rs @[name]` to restore (overwrite).
- `td kill` to remove everything about `td.lock`.
- `td ls` to list all intances.
- `td status` to see status about the lockfile (`td.lock`)
- See more by running `td -h`.
This script is **not** scripts.d compliant. Default tmpfs is `/tmp`

## clock
A dwm shell script for a cool® status bar.
It should look like this:
![Status Bar](assets/status-bar.png)
(minus the black box in the middle)
If it doesn't, install a [nerd font](https://github.com/ryanoasis/nerd-fonts) or patch dwm to render UTF-8.
