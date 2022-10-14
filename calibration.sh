#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
echo "SCRIPTDIR: ${SCRIPTDIR}"

export XRD_REQUESTTIMEOUT=1200

INPUT_TYPE=readout
#INPUT_TYPE=tflist



# Decoding setup
DECOD_INSPEC="TF:MCH/RAWDATA"
if [ x"$INPUT_TYPE" = "xreadout" ]; then
    DECOD_INSPEC="readout:RDT/RAWDATA"
fi

USE_CUSTOM_MAPPING=${USE_CUSTOM_MAPPING:-0}

RUN_CALIBRATOR=${RUN_CALIBRATOR:-0}

MAP_OPT=""
if [ x"${USE_CUSTOM_MAPPING}" = "x1" ]; then
    MAP_OPT="--cru-map \"${SCRIPTDIR}/Mapping/cru.map\" --fec-map \"${SCRIPTDIR}/Mapping/fec.map\""
fi


CALIBRATOR_CONFIG="MCHBadChannelCalibratorParam.minRequiredNofEntriesPerChannel=100;MCHBadChannelCalibratorParam.minRequiredCalibratedFraction=0.4;MCHBadChannelCalibratorParam.onlyAtEndOfStream=false"


# QC setup

RUN_QC=${RUN_QC:-1}
RUN_QC_MERGER=${RUN_QC_MERGER:-0}



# Set-up QC environment
if [ x"${RUN_QC_MERGER}" = "x1" ]; then
    QCCONF=config/qc-calib-remote.json
    ARGS_QC="--local --host localhost"
else
    QCCONF=config/qc-calib.json
    ARGS_QC=""
fi


# create the QC configuration from template
cat "$QCCONF" > qc.json

# start merger process if requested
if [ x"${RUN_QC_MERGER}" = "x1" ]; then
    xterm -bg black -fg white -geometry 100x50+0+100 -e o2-qc --config json://${SCRIPTDIR}/qc.json -b --remote --run &
    sleep 10
fi



ARGS_ALL="--session default --shm-segment-size 16000000000"

DECODER_PROF=""
#DECODER_PROF="--child-driver 'valgrind --tool=callgrind'"

if [ $INPUT_TYPE = readout ]; then
    WORKFLOW="o2-mch-cru-page-reader-workflow ${ARGS_ALL} --infile \"$1\" --full-tf | "
fi

if [ $INPUT_TYPE = tflist ]; then
    WORKFLOW="o2-raw-tf-reader-workflow ${ARGS_ALL} --onlyDet MCH --input-data \"$1\" --remote-regex \"^alien://.+\" --delay 1 --loop 0 | "
fi

WORKFLOW+="o2-mch-pedestal-decoding-workflow ${ARGS_ALL} --input-spec \"${DECOD_INSPEC}\" --logging-interval 1 ${MAP_OPT} | "
#WORKFLOW+="o2-mch-pedestal-decoding-workflow ${ARGS_ALL} --logging-interval 1 ${MAP_OPT} | "

if [ x"${RUN_CALIBRATOR}" = "x1" ]; then
    WORKFLOW+="o2-calibration-mch-badchannel-calib-workflow  ${ARGS_ALL} --configKeyValues=\"${CALIBRATOR_CONFIG}\" --condition-tf-per-query -1 | "
fi


if [ x"${RUN_QC}" = "x1" ]; then
    WORKFLOW+="o2-qc ${ARGS_ALL} ${ARGS_QC} --config json:/${SCRIPTDIR}/qc.json | "
fi

WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --run"

echo $WORKFLOW
eval $WORKFLOW
