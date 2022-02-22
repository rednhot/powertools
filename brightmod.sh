#!/bin/sh

# author: mathway

# SYNOPSIS
# brightmod.sh [-min|-max] [-n%|+n%] [-get] [-set _perc_] [-h]
#
# DESCRIPTION
#
# OPTIONS
#       -max        Set maximum brightness.
#       -min        Set minimum brightness.
#       -n%         Decrease brightness by `n' percents.
#       +n%         Increase brightness by `n' percents.
#       -get        Get current brightness level.
#       -set _perc_ Set brightness level to _perc_.
#       -h          Show help.
#
# EXAMPLES
#
# Set minimal, still operatable brightness.
# brightmod.sh -min   OR   brightmod.sh -set 10%
#
# Set maximum hardware-supported value.
# brightmod.sh -max   OR   brightmod.sh -set 100%
#
# Get current brightness, as well as the maximal one.
# brightmod.sh -get



err() {
    [ $# -gt 0 ] && echo $* || echo "Can't do the job. Sorry." && exit 1
}

show_help() {
    echo "Usage: brightmod.sh [-min|-max|-n%|+n%] [-h]"
    echo "\t-max\tSet maximim brightness."
    echo "\t-min\tSet minimum brightness."
    echo "\t-n% \tDecrease brightness by \`n' percents."
    echo "\t+n% \tIncrease brightness by \`n' percents."
    echo "\t-get\tGet current brightness level."
    echo "\t-set n%\tSet current brightness level to \`n' percents of maximum."
    echo "\t-h  \tShow help."
}

get_cur_brightness() {
    cat "$BRIGHT_DIR"/brightness
}

get_max_brightness() {
    cat "$BRIGHT_DIR"/max_brightness
}

set_brightness() {
    [ $# -eq 0 ] && err
    local mx_br=`cat "${BRIGHT_DIR}/max_brightness"`
    local norm="$1"
    [ "$1" -gt 100 ] && norm=100 || { [ "$1" -lt 10 ] && norm=10 ;}
    echo `expr $norm \* $mx_br / 100` > "${BRIGHT_DIR}/brightness"
}

# FIXME: Current implementation looks only at one directory
# in /sys/class/backlight
BRIGHT_DIR=
[ -d /sys/class/backlight ] && BRIGHT_DIR="`find /sys/class/backlight -mindepth 1`"
[ -z "$BRIGHT_DIR" ] && err "Can't change brightness on your hardware. Sorry."

while [ "$#" -gt 0 ]; do
    case "$1" in
	-max) set_brightness 100
	      exit 0 ;;
	-min) set_brightness 10
	      exit 0 ;;
	-h) show_help  exit 0 ;;
	-get) echo "Current brightness is `get_cur_brightness` (max `get_max_brightness`)"
	      exit 0;;
	-set) shift
	      echo $1 | sed -n '/^[0-9]\{1,3\}%\?$/!q1' || err 'Bad argument specified.'     
	      set_brightness `echo $1 | tr -d '%'`
	      ;;
	[+-][0-9]*)
	    dry=`echo $1 | tr -d '+%-'`
	    echo $1 | sed -n '/^\(-\|+\)[0-9]\{1,3\}%\?$/!q1' || err 'Bad argument specified.'
	    cur_br=`cat "${BRIGHT_DIR}/brightness"`
	    mx_br=`cat "${BRIGHT_DIR}/max_brightness"`
	    new_perc=`expr $cur_br \* 100 / $mx_br`
	    case "$1" in
		+*) set_brightness `expr $new_perc + $dry` ;;
		*) set_brightness `expr $new_perc - $dry` ;;
	    esac
	    exit 0;;
	*) err "Invalid option provided. Use \`-h' for help." ;;
    esac
    shift
done
