#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
echo "SCRIPTDIR: ${SCRIPTDIR}"

export XRD_REQUESTTIMEOUT=1200



# Type of input data. Possible values are:
# readout: data file with raw CRU pages stored directly from readout
# ctflist: text file with a list of local or remote CTF files (default)
# tflist:  text file with a list of local or remote TF files
INPUT_TYPE=${INPUT_TYPE:-ctflist}



# Reconstruction setup

RUN_FULL_RECO=${RUN_FULL_RECO:-0}
RUN_DIGITS_FILTER=${RUN_DIGITS_FILTER:-1}
RUN_PRECLUSTERING=${RUN_PRECLUSTERING:-1}
RUN_CLUSTERING=${RUN_CLUSTERING:-1}
RUN_TRACKING=${RUN_TRACKING:-1}
RUN_MATCHING_MID=${RUN_MATCHING_MID:-0}
RUN_MATCHING_MFT=${RUN_MATCHING_MFT:-0}
RUN_EVENT_DISPLAY=${RUN_EVENT_DISPLAY:-0}

L3_CURRENT=${L3_CURRENT:-30000}
DIPOLE_CURRENT=${DIPOLE_CURRENT:-6000}


if [ x"${RUN_FULL_RECO}" = "x1" ]; then
   RUN_DIGITS_FILTER=1
   RUN_PRECLUSTERING=1
   RUN_CLUSTERING=1
   RUN_TRACKING=1
fi

# list of detectors to be processed

DETECTORS_LIST="MCH"
if [ x"${RUN_MATCHING_MID}" = "x1" ]; then
    DETECTORS_LIST="${DETECTORS_LIST},MID"
fi
if [ x"${RUN_MATCHING_MFT}" = "x1" ]; then
    DETECTORS_LIST="${DETECTORS_LIST},MFT"
fi



USE_CUSTOM_MAPPING=${USE_CUSTOM_MAPPING:-0}



# Reconstruction configuration variables

CONFIG_TYPE=${CONFIG_TYPE:-pp}

if [ x"${CONFIG_TYPE}" = "xpp" ]; then

    DIGIT_FILTER_CONFIG="MCHDigitFilter.rejectBackground=true;MCHDigitFilter.timeOffset=126;MCHDigitFilter.minADC=20"
    TIME_CLUSTERING_CONFIG="MCHTimeClusterizer.onlyTrackable=false;MCHTimeClusterizer.peakSearchSignalOnly=true"
    CLUSTERING_CONFIG="MCHClustering.lowestPadCharge=20;MCHClustering.defaultClusterResolution=0.4"
    TRACKING_CONFIG="MCHTracking.chamberResolutionX=0.4;MCHTracking.chamberResolutionY=0.4;MCHTracking.sigmaCutForTracking=7.;MCHTracking.sigmaCutForImprovement=6."

fi

if [ x"${CONFIG_TYPE}" = "xcosmics" ]; then

    DIGIT_FILTER_CONFIG="MCHDigitFilter.rejectBackground=true;MCHDigitFilter.timeOffset=126;MCHDigitFilter.minADC=20"
    TIME_CLUSTERING_CONFIG="MCHTimeClusterizer.onlyTrackable=false;MCHTimeClusterizer.peakSearchSignalOnly=true"
    CLUSTERING_CONFIG="MCHClustering.lowestPadCharge=20;MCHClustering.defaultClusterResolution=0.4"
    TRACKING_CONFIG="MCHTracking.chamberResolutionX=0.4;MCHTracking.chamberResolutionY=0.4;MCHTracking.sigmaCutForTracking=7.;MCHTracking.sigmaCutForImprovement=6.;MCHTracking.bendingVertexDispersion=170;MCHTracking.nonBendingVertexDispersion=170"

fi


MAP_OPT=""
if [ x"${USE_CUSTOM_MAPPING}" = "x1" ]; then
    MAP_OPT="--cru-map \"${SCRIPTDIR}/Mapping/cru.map\" --fec-map \"${SCRIPTDIR}/Mapping/fec.map\""
fi


# QC setup

RUN_QC=${RUN_QC:-1}
RUN_QC_MERGER=${RUN_QC_MERGER:-0}
QC_TASK_DIGITS_ENABLE=${QC_TASK_DIGITS_ENABLE:-1}
QC_TASK_ERRORS_ENABLE=${QC_TASK_ERRORS_ENABLE:-1}
QC_TASK_ROFS_ENABLE=${QC_TASK_ROFS_ENABLE:-1}
QC_TASK_PRECLUSTERS_ENABLE=${QC_TASK_PRECLUSTERS_ENABLE:-1}
QC_TASK_TRACKS_ENABLE=${QC_TASK_TRACKS_ENABLE:-1}
QC_CYCLE_DURATION=${QC_CYCLE_DURATION:-300}


# disable errors QC task when processing CTFs
if [ x"$INPUT_TYPE" = "xctflist" ]; then
    QC_TASK_ERRORS_ENABLE=0
fi

# disable pre-clusters QC task if pre-clustering is disabled in the reconstruction
if [ x"$RUN_PRECLUSTERING" != "x1" ]; then
    QC_TASK_PRECLUSTERS_ENABLE=0
    RUN_CLUSTERING=0
    RUN_TRACKING=0
fi

# disable tracks QC task if tracking is disabled in the reconstruction
if [ x"$RUN_TRACKING" != "x1" ]; then
    QC_TASK_TRACKS_ENABLE=0
fi


# Set-up QC environment
if [ x"${RUN_QC_MERGER}" = "x1" ]; then
    QCCONF=config/qc-reco-remote.json
    ARGS_QC="--local --host localhost"
else
    QCCONF=config/qc-reco.json
    ARGS_QC=""
fi


# create the QC configuration from template
cat "$QCCONF" | \
    sed "s/%QC_TASK_DIGITS_ENABLE%/${QC_TASK_DIGITS_ENABLE}/g" | \
    sed "s/%QC_TASK_ERRORS_ENABLE%/${QC_TASK_ERRORS_ENABLE}/g" | \
    sed "s/%QC_TASK_ROFS_ENABLE%/${QC_TASK_ROFS_ENABLE}/g" | \
    sed "s/%QC_TASK_PRECLUSTERS_ENABLE%/${QC_TASK_PRECLUSTERS_ENABLE}/g" | \
    sed "s/%QC_TASK_TRACKS_ENABLE%/${QC_TASK_TRACKS_ENABLE}/g" | \
    sed "s/%QC_CYCLE_DURATION%/${QC_CYCLE_DURATION}/g" > qc.json

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
    WORKFLOW+="o2-mch-raw-to-digits-workflow ${ARGS_ALL} --dataspec readout:RDT/RAWDATA --ignore-dist-stf --severity warning --configKeyValues \"MCHCoDecParam.minDigitOrbitAccepted=-10;MCHCoDecParam.maxDigitOrbitAccepted=-1;HBFUtils.nHBFPerTF=128\" --time-reco-mode bcreset ${MAP_OPT} ${DECODER_PROF} | "
fi

if [ $INPUT_TYPE = ctflist ]; then
    WORKFLOW="o2-ctf-reader-workflow ${ARGS_ALL} --ctf-input \"$1\" --remote-regex \"^alien://.+\" --copy-cmd no-copy --onlyDet ${DETECTORS_LIST} --max-tf -1 | "
    WORKFLOW+="o2-tfidinfo-writer-workflow ${ARGS_ALL} | "
fi

if [ $INPUT_TYPE = tflist ]; then
    WORKFLOW="o2-raw-tf-reader-workflow ${ARGS_ALL} --onlyDet ${DETECTORS_LIST} --input-data tflist.txt --remote-regex \"^alien://.+\" --delay 1 --loop 0 | "
    WORKFLOW+="o2-mch-raw-to-digits-workflow ${ARGS_ALL} --configKeyValues \"MCHCoDecParam.minDigitOrbitAccepted=-10;MCHCoDecParam.maxDigitOrbitAccepted=-1;HBFUtils.nHBFPerTF=128\" --time-reco-mode bcreset | "
fi



if [ x"${RUN_FULL_RECO}" = "x1" ]; then

    WORKFLOW+="o2-mch-reco-workflow ${ARGS_ALL} --disable-mc --disable-root-input --configKeyValues \"${DIGIT_FILTER_CONFIG};${TIME_CLUSTERING_CONFIG};${CLUSTERING_CONFIG};${TRACKING_CONFIG}\" | "

    if [ x"${RUN_MATCHING_MID}" = "x1" ]; then
	WORKFLOW+="o2-mid-reco-workflow ${ARGS_ALL} --disable-mc --mid-tracker-keep-best | "
    fi
    WORKFLOW+="o2-muon-tracks-matcher-workflow ${ARGS_ALL} --disable-mc | "
    #WORKFLOW+="o2-muon-tracks-writer-workflow ${ARGS_ALL} | "

    if [ x"${RUN_EVENT_DISPLAY}" = "x1" ]; then
	WORKFLOW+="o2-eve-export-workflow ${ARGS_ALL} --display-tracks MCH,MID --display-clusters MCH,MID --jsons-folder EventDisplay --disable-mc --disable-root-input | "
    fi
else
    
    if [ x"$RUN_DIGITS_FILTER" = "x1" ]; then
	WORKFLOW+="o2-mch-digits-filtering-workflow ${ARGS_ALL} --input-digits-data-description \"DIGITS\" --input-digitrofs-data-description \"DIGITROFS\" --disable-mc true --configKeyValues \"${DIGIT_FILTER_CONFIG}\" | "
    fi
    
    WORKFLOW+="o2-mch-digits-to-timeclusters-workflow ${ARGS_ALL} --input-digits-data-description \"F-DIGITS\" --input-digitrofs-data-description \"F-DIGITROFS\" --configKeyValues \"${TIME_CLUSTERING_CONFIG}\" | "
    
    if [ x"$RUN_PRECLUSTERING" = "x1" ]; then
	WORKFLOW+="o2-mch-digits-to-preclusters-workflow ${ARGS_ALL} --input-digits-data-description \"F-DIGITS\" --check-no-leftover-digits off | "
	
	if [ x"$RUN_CLUSTERING" = "x1" ]; then
	    WORKFLOW+="o2-mch-preclusters-to-clusters-original-workflow ${ARGS_ALL} | "
	    WORKFLOW+="o2-mch-clusters-transformer-workflow ${ARGS_ALL} | "
	    
	    if [ x"$RUN_TRACKING" = "x1" ]; then
		WORKFLOW+="o2-mch-clusters-to-tracks-workflow ${ARGS_ALL} --l3Current ${L3_CURRENT} --dipoleCurrent ${DIPOLE_CURRENT} | "
		
		if [ x"${RUN_MATCHING_MID}" = "x1" ]; then
		    WORKFLOW+="o2-mid-reco-workflow ${ARGS_ALL} --disable-mc --mid-tracker-keep-best | "
		fi
		WORKFLOW+="o2-muon-tracks-matcher-workflow ${ARGS_ALL} --disable-mc | "

		if [ x"${RUN_EVENT_DISPLAY}" = "x1" ]; then
		    WORKFLOW+="o2-eve-export-workflow ${ARGS_ALL} --display-tracks MCH,MID --display-clusters MCH,MID --jsons-folder EventDisplay --disable-mc --disable-root-input | "
		fi
	    fi
	fi
    fi

fi


if [ x"${RUN_QC}" = "x1" ]; then
    WORKFLOW+="o2-qc ${ARGS_ALL} ${ARGS_QC} --config json:/${SCRIPTDIR}/qc.json | "
fi

WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --run"

echo $WORKFLOW
eval $WORKFLOW
