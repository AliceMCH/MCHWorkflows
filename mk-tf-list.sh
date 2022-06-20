#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
#echo "SCRIPTDIR: ${SCRIPTDIR}"

DIR=$1

rm -f /tmp/tflist.txt
alien.py ls ${DIR}/*.tf > /tmp/tflist.txt
sed -i "s|o2_raw|alien://${DIR}/o2_raw|g" /tmp/tflist.txt
cat /tmp/tflist.txt
