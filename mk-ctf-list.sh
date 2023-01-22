#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
#echo "SCRIPTDIR: ${SCRIPTDIR}"

BDIR=$1

DIRS=$(alien.py ls $BDIR)

while IFS= read -r line
do

  #echo "$line"
  DIR="$BDIR/$line"
  rm -f /tmp/ctflist.txt
  alien.py ls ${DIR}/*.root > /tmp/ctflist.txt
  sed -i "s|o2_ctf|alien://${DIR}/o2_ctf|g" /tmp/ctflist.txt
  cat /tmp/ctflist.txt

done < <(printf '%s\n' "$DIRS")
