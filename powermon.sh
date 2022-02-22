#!/bin/sh

# author: mathway

# SYNOPSIS
# powermon.sh [-min n%] [-s n%] [-d] [-h]
#
# DESCRIPTION
# The script will test current battery power,
# and if it's too low, it will decrease current
# lcd brightness to some low value, so that
# you can see easily when your laptop is almost
# discharged.
#
# OPTIONS
#    -min n%        Set a threshold, which is considered as a low power level.
#                   Default is 20%.
#    -b   n%        When the threshold is hit, lcd brightness will be changed to n%.
#    -d             Daemonize the process.
#    -h             Show help message.
#
# NOTES
# You may(or may not) also like brightmod.sh script.

err() {
    [ $# -gt 0 ] && echo $* || echo "Can't do the job. Sorry." && exit 1
}

show_help() {
    printf "Usage: %s [-min n%%] [-s n%%] [-h]\n" "$0"
    echo "    -min n%        Set a threshold, which is considered as a low power level."
    echo "                   Default is 20%."
    echo "    -b   n%        When the threshold is hit, lcd brightness will be changed to n%."
    echo "    -d             Daemonize the process."
    echo "    -h             Show help message."
}

set_brightness() {
    [ $# -eq 0 ] && err
    local mx_br=`cat "${BRIGHT_DIR}/max_brightness"`
    local norm="$1"
    [ "$1" -gt 100 ] && norm=100 || { [ "$1" -lt 10 ] && norm=10 ;}
    echo `expr $norm \* $mx_br / 100` > "${BRIGHT_DIR}/brightness"
}

do_the_job() {
    cur_power=`acpitool -b | cut -d, -f2 | cut -d. -f1 | tr -d '[:space:]'`
    is_discharging="`acpitool -b | grep Discharging >/dev/null 2>&1`"
    [ "$cur_power" -lt "$POWER_THRESHOLD" -a "$?" -eq 0 ] && set_brightness $LOW_BAT_BRIGHT
}

# FIXME: Current implementation looks only at one directory
# in /sys/class/backlight
BRIGHT_DIR=
[ -d /sys/class/backlight ] && BRIGHT_DIR="`find /sys/class/backlight -mindepth 1`"
[ -z "$BRIGHT_DIR" ] && err "Can't change brightness on your hardware. Sorry."

POWER_THRESHOLD=20
LOW_BAT_BRIGHT=10
DAEMONIZE=0
while [ "$#" -gt 0 ]; do
    case "$1" in
	-min) shift
	      echo $1 | sed -n '/^[0-1]\?[0-9]\{1,2\}%\?$/!q1' || err 'Bad argument specified.'
	      POWER_THRESHOLD=`echo $1 | tr -d '%'`
	      ;;
	-b) shift
	      echo $1 | sed -n '/^[0-1]\?[0-9]\{1,2\}%\?$/!q1' || err 'Bad argument specified.'
	      LOW_BAT_BRIGHT=`echo $1 | tr -d '%'`
	      ;;
	-d) DAEMONIZE=1
	    ;;
	-h) show_help "$0"
	    exit 0
	    ;;
	*) err "Invalid option specified. Use \`-h' for help."
	   ;;
    esac
    shift
done

[ "${DAEMONIZE}" -eq 0 ] && { do_the_job ; exit 0 ;}

while true; do
    do_the_job
    sleep 60
done
