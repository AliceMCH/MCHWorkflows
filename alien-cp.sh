#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
echo "SCRIPTDIR: ${SCRIPTDIR}"

export XRD_REQUESTTIMEOUT=4800

while read -r line; do 

    if [ x"$line" != "x" ]; then
	OUT=$(basename $line)
	echo "alien_cp $line file://./$OUT"
	#alien_cp $line file://./$OUT
	alien.py cp $line file://./$OUT
    fi

done < "$1"
