#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
echo "SCRIPTDIR: ${SCRIPTDIR}"

export XRD_REQUESTTIMEOUT=1200

ARGS_ALL="--session dump --shm-segment-size 16000000000"

WORKFLOW="o2-raw-tf-reader-workflow ${ARGS_ALL} --onlyDet MCH --input-data \"$1\" --remote-regex \"^alien://.+\" --loop 0 | "
WORKFLOW+="o2-mch-dump-pages-workflow ${ARGS_ALL} | "
WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --run"

echo $WORKFLOW
eval $WORKFLOW
