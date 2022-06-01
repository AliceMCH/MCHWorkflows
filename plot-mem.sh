#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
echo "SCRIPTDIR: ${SCRIPTDIR}"

rm -f /tmp/mem.log

PID=$(ps ux | grep "id $1" | tr -s " " | cut -d" " -f 2 | head -n 1)
echo "PID: $PID"

while [ true ]; do

    ps --pid $PID -o pid=,%mem=,vsz=,cmd= | head -n $((I+1)) | tail -n 1 >> /tmp/mem.log

    sleep 1

done
