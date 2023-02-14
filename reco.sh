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

RECO_MCH=${RECO_MCH:-1}
RECO_MID=${RECO_MID:-1}
RECO_MFT=${RECO_MFT:-1}

RUN_DIGITS_FILTER=${RUN_DIGITS_FILTER:-1}
RUN_PRECLUSTERING=${RUN_PRECLUSTERING:-1}
RUN_CLUSTERING=${RUN_CLUSTERING:-1}
RUN_TRACKING=${RUN_TRACKING:-1}
RUN_EVENT_DISPLAY=${RUN_EVENT_DISPLAY:-0}

L3_CURRENT=${L3_CURRENT:-30000}
DIPOLE_CURRENT=${DIPOLE_CURRENT:-6000}

MAX_TF=${MAX_TF:--1}
TFDELAY=${TFDELAY:-0}


if [ x"${RECO_MCH}" = "x1" ]; then
    RUN_DIGITS_FILTER=1
    RUN_PRECLUSTERING=1
    RUN_CLUSTERING=1
    RUN_TRACKING=1
fi
if [ x"${RUN_TRACKING}" != "x1" ]; then
    # disable matching if full reconstruction is not enabled
    RECO_MID=0
    RECO_MFT=0
fi

# list of detectors to be processed

DETECTORS_LIST="MCH"
if [ x"${RECO_MID}" = "x1" ]; then
    DETECTORS_LIST="${DETECTORS_LIST},MID"
fi
if [ x"${RECO_MFT}" = "x1" ]; then
    DETECTORS_LIST="${DETECTORS_LIST},MFT"
fi



USE_CUSTOM_MAPPING=${USE_CUSTOM_MAPPING:-0}



# Reconstruction configuration variables

CONFIG_TYPE=${CONFIG_TYPE:-pp}

if [ x"${CONFIG_TYPE}" = "xpp" ]; then

    DIGIT_FILTER_CONFIG="MCHDigitFilter.rejectBackground=true;MCHDigitFilter.timeOffset=120;MCHDigitFilter.minADC=1"
    TIME_CLUSTERING_CONFIG="MCHTimeClusterizer.onlyTrackable=true;MCHTimeClusterizer.peakSearchSignalOnly=true"
    CLUSTERING_CONFIG="MCHClustering.lowestPadCharge=10;MCHClustering.defaultClusterResolution=0.4"
    TRACKING_CONFIG="MCHTracking.chamberResolutionX=0.4;MCHTracking.chamberResolutionY=0.4;MCHTracking.sigmaCutForTracking=7.;MCHTracking.sigmaCutForImprovement=6."
    #CLUSTERING_CONFIG="MCHClustering.lowestPadCharge=10;MCHClustering.defaultClusterResolution=0.07"
    #TRACKING_CONFIG="MCHTracking.chamberResolutionX=0.07;MCHTracking.chamberResolutionY=0.07;MCHTracking.sigmaCutForTracking=7.;MCHTracking.sigmaCutForImprovement=6."

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
QC_TASK_TRACKS_MFTMCH_ENABLE=${QC_TASK_TRACKS_MFTMCH_ENABLE:-0}
QC_TASK_TRACKS_MCHMID_ENABLE=${QC_TASK_TRACKS_MCHMID_ENABLE:-0}
QC_TASK_TRACKS_MFTMCHMID_ENABLE=${QC_TASK_TRACKS_MFTMCHMID_ENABLE:-0}
QC_CYCLE_DURATION=${QC_CYCLE_DURATION:-300}


if [ x"$RUN_QC" = "x1" ]; then
    TEST_JQ=$(which jq 2> /dev/null)
    if [ -z "${TEST_JQ}" ]; then
	echo "The jq command is needed in order to generate the QC configuration"
	exit 1
    fi
fi


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
if [ x"$RUN_CLUSTERING" != "x1" ]; then
    RUN_TRACKING=0
fi

# disable tracks QC task if tracking is disabled in the reconstruction
if [ x"$RUN_TRACKING" != "x1" ]; then
    QC_TASK_TRACKS_ENABLE=0
fi

# disable MCH/MID matched tracks QC task if matching is disabled in the reconstruction
if [ x"$RECO_MFT" == "x1" -a x"$RECO_MID" == "x1" ]; then
    QC_TASK_TRACKS_MFTMCHMID_ENABLE=1
else
    if [ x"$RECO_MFT" == "x1" ]; then
	QC_TASK_TRACKS_MFTMCH_ENABLE=1
    fi
    if [ x"$RECO_MID" == "x1" ]; then
	QC_TASK_TRACKS_MCHMID_ENABLE=1
    fi
fi

echo "RUN_TRACKING=${RUN_TRACKING}"
echo "RECO_MID=${RECO_MID}"
echo "QC_TASK_TRACKS_ENABLE=${QC_TASK_TRACKS_ENABLE}"
echo "QC_TASK_TRACKS_MCHMID_ENABLE=${QC_TASK_TRACKS_MCHMID_ENABLE}"
echo "QC_TASK_TRACKS_MFTMCHMID_ENABLE=${QC_TASK_TRACKS_MFTMCHMID_ENABLE}"

CONFIG_DIR="config"
#CONFIG_DIR="config-ref"

QCCONF="${CONFIG_DIR}/qc-base.json "
QCCONFREM=""
if [ x"$QC_TASK_DIGITS_ENABLE" = "x1" ]; then
    QCCONF+="${CONFIG_DIR}/qc-digits.json "
    if [ x"${RUN_QC_MERGER}" = "x1" ]; then
	QCCONFREM+="${CONFIG_DIR}/qc-digits-remote.json "
    fi
fi
if [ x"${INPUT_TYPE}" = "xreadout" ]; then
    QCCONF+="${CONFIG_DIR}/qc-errors.json "
    if [ x"${RUN_QC_MERGER}" = "x1" ]; then
	QCCONFREM+="${CONFIG_DIR}/qc-errors-remote.json "
    fi
fi
if [ x"$QC_TASK_ROFS_ENABLE" = "x1" ]; then
    QCCONF+="${CONFIG_DIR}/qc-rofs.json "
    if [ x"${RUN_QC_MERGER}" = "x1" ]; then
	QCCONFREM+="${CONFIG_DIR}/qc-rofs-remote.json "
    fi
fi
if [ x"$QC_TASK_PRECLUSTERS_ENABLE" = "x1" ]; then
    QCCONF+="${CONFIG_DIR}/qc-preclusters.json "
    if [ x"${RUN_QC_MERGER}" = "x1" ]; then
	QCCONFREM+="${CONFIG_DIR}/qc-preclusters-remote.json "
    fi
fi
if [ x"${RUN_TRACKING}" = "x1" ]; then
    QCCONF+="${CONFIG_DIR}/qc-tracks-mch.json "
fi
if [ x"$QC_TASK_TRACKS_MFTMCH_ENABLE" = "x1" ]; then
    QCCONF+="${CONFIG_DIR}/qc-tracks-mftmch.json "
fi
if [ x"$QC_TASK_TRACKS_MCHMID_ENABLE" = "x1" ]; then
    QCCONF+="${CONFIG_DIR}/qc-tracks-mchmid.json "
fi
if [ x"$QC_TASK_TRACKS_MFTMCHMID_ENABLE" = "x1" ]; then
    QCCONF+="${CONFIG_DIR}/qc-tracks-mftmchmid.json "
fi
QCCONF+="${CONFIG_DIR}/qc-quality.json "
ARGS_QC=""

jq -n 'reduce inputs as $s (input; .qc.tasks += ($s.qc.tasks) | .qc.checks += ($s.qc.checks) | .qc.aggregators += ($s.qc.aggregators)  | .qc.externalTasks += ($s.qc.externalTasks) | .qc.postprocessing += ($s.qc.postprocessing)| .dataSamplingPolicies += ($s.dataSamplingPolicies))' $QCCONF > qc-temp.json
if [[ $? != 0 ]]; then
    echo "Merging QC workflow failed"
    exit 1
fi
if [ x"${RUN_QC_MERGER}" = "x1" ]; then
    jq -n 'reduce inputs as $item ({}; . *= $item)' qc-temp.json $QCCONFREM > qc-temp2.json
    if [[ $? != 0 ]]; then
	echo "Merging QC workflow failed"
	exit 1
    fi
    cp qc-temp2.json qc-temp.json
fi

# create the QC configuration from template
cat "qc-temp.json" | \
    sed "s/%QC_CYCLE_DURATION%/${QC_CYCLE_DURATION}/g" > qc.json

# start merger process if requested
if [ x"${RUN_QC_MERGER}" = "x1" ]; then
    xterm -bg black -fg white -geometry 100x50+0+100 -e ./run-qc-merger.sh json://${SCRIPTDIR}/qc.json &
    sleep 10
fi



ARGS_ALL="--session default --shm-segment-size 16000000000"

DECODER_PROF=""
#DECODER_PROF="--child-driver 'valgrind --tool=callgrind'"

CLUSTERING_PROF=""
#CLUSTERING_PROF="--child-driver 'valgrind --tool=callgrind'"

QC_PROF=""
#QC_PROF="--child-driver 'valgrind --tool=callgrind'"
#QC_PROF="--child-driver 'valgrind --tool=memcheck'"

CONDITION_REMAP=""
#CONDITION_REMAP="--condition-remap file://.=GLO/Config/GeometryAligned"

if [ $INPUT_TYPE = ctflist ]; then
    WORKFLOW="o2-ctf-reader-workflow ${ARGS_ALL} --ctf-input \"$1\" --remote-regex \"^alien://.+\" --copy-cmd no-copy --onlyDet ${DETECTORS_LIST} --max-tf ${MAX_TF} --delay $TFDELAY ${CONDITION_REMAP} | "
    WORKFLOW+="o2-tfidinfo-writer-workflow ${ARGS_ALL} | "
fi

if [ $INPUT_TYPE = tflist ]; then
    WORKFLOW="o2-raw-tf-reader-workflow ${ARGS_ALL} --onlyDet ${DETECTORS_LIST} --input-data tflist.txt --remote-regex \"^alien://.+\" --delay 1 --loop 0 | "
    WORKFLOW+="o2-mch-raw-to-digits-workflow ${ARGS_ALL} --configKeyValues \"MCHCoDecParam.minDigitOrbitAccepted=-10;MCHCoDecParam.maxDigitOrbitAccepted=-1;HBFUtils.nHBFPerTF=128\" --time-reco-mode bcreset | "
fi

if [ $INPUT_TYPE = readout ]; then
    WORKFLOW="o2-mch-cru-page-reader-workflow ${ARGS_ALL} --infile \"$1\" --full-tf | " #--print | "
    WORKFLOW+="o2-mch-raw-to-digits-workflow ${ARGS_ALL} --dataspec readout:RDT/RAWDATA --ignore-dist-stf --severity warning --configKeyValues \"MCHCoDecParam.minDigitOrbitAccepted=-10;MCHCoDecParam.maxDigitOrbitAccepted=-1;HBFUtils.nHBFPerTF=128\" --time-reco-mode bcreset ${MAP_OPT} ${DECODER_PROF} | "
fi


if [ x"${RECO_MCH}" = "x1" ]; then

    WORKFLOW+="o2-mch-reco-workflow ${ARGS_ALL} --disable-mc --disable-root-input --disable-root-output --digits --configKeyValues \"${DIGIT_FILTER_CONFIG};${TIME_CLUSTERING_CONFIG};${CLUSTERING_CONFIG};${TRACKING_CONFIG}\" | "

else
    
    if [ x"$RUN_DIGITS_FILTER" = "x1" ]; then
	WORKFLOW+="o2-mch-digits-filtering-workflow ${ARGS_ALL} --severity warning --input-digits-data-description \"DIGITS\" --input-digitrofs-data-description \"DIGITROFS\" --disable-mc true --configKeyValues \"${DIGIT_FILTER_CONFIG}\" | "
    fi
    
    WORKFLOW+="o2-mch-digits-to-timeclusters-workflow ${ARGS_ALL} --severity warning --input-digits-data-description \"F-DIGITS\" --input-digitrofs-data-description \"F-DIGITROFS\" --configKeyValues \"${TIME_CLUSTERING_CONFIG}\" | "
    
    if [ x"$RUN_PRECLUSTERING" = "x1" ]; then
	WORKFLOW+="o2-mch-digits-to-preclusters-workflow ${ARGS_ALL} --input-digits-data-description \"F-DIGITS\" --check-no-leftover-digits off | "
	
	if [ x"$RUN_CLUSTERING" = "x1" ]; then
	    WORKFLOW+="o2-mch-preclusters-to-clusters-original-workflow ${ARGS_ALL} --configKeyValues \"${CLUSTERING_CONFIG}\" ${CLUSTERING_PROF} | "
	    #WORKFLOW+="o2-mch-clusters-transformer-workflow ${ARGS_ALL} --mch-disable-geometry-from-ccdb --geometry o2sim_geometry-alignedReAlign7.root | "
	    WORKFLOW+="o2-mch-clusters-transformer-workflow ${ARGS_ALL} --mch-disable-geometry-from-ccdb --geometry o2sim_geometry-aligned.root | "
	    
	    if [ x"$RUN_TRACKING" = "x1" ]; then
		WORKFLOW+="o2-mch-clusters-to-tracks-workflow ${ARGS_ALL} --digits --l3Current ${L3_CURRENT} --dipoleCurrent ${DIPOLE_CURRENT} --configKeyValues \"${TRACKING_CONFIG}\" | "
		WORKFLOW+="o2-mch-tracks-writer-workflow ${ARGS_ALL} | "
		#WORKFLOW+="o2-mch-tracks-out-workflow ${ARGS_ALL} | "
	    fi
	fi
    fi
fi


if [ x"${RECO_MID}" = "x1" ]; then

    WORKFLOW+="o2-mid-reco-workflow ${ARGS_ALL} --disable-mc --disable-root-output --mid-tracker-keep-best | "
    WORKFLOW+="o2-muon-tracks-matcher-workflow ${ARGS_ALL} --disable-mc --disable-root-input --disable-root-output | "
    #WORKFLOW+="o2-muon-tracks-writer-workflow ${ARGS_ALL} | "

fi

if [ x"${RECO_MFT}" = "x1" ]; then

    WORKFLOW+="o2-mft-reco-workflow ${ARGS_ALL} --clusters-from-upstream --disable-mc --disable-root-output --configKeyValues \"MFTTracking.LTFclsRCut=0.01; MFTTracking.forceZeroField=false\" | "

    if [ x"${RECO_MID}" = "x1" ]; then
	MFTMCHConf="FwdMatching.useMIDMatch=true;"
    else
	MFTMCHConf="FwdMatching.useMIDMatch=false;"
    fi
    #MFTMCHConf+="FwdMatching.matchFcn=\"matchNeedsName\";"
    MFTMCHConf+="FwdMatching.cutFcn=\"cut3SigmaXYAngles\";"
    WORKFLOW+="o2-globalfwd-matcher-workflow ${ARGS_ALL} --disable-mc --disable-root-input --enable-match-output --disable-root-output --configKeyValues \"$MFTMCHConf\" | "

fi


if [ x"${RUN_EVENT_DISPLAY}" = "x1" ]; then
    WORKFLOW+="o2-eve-export-workflow ${ARGS_ALL} --display-tracks MCH,MID --display-clusters MCH,MID --jsons-folder EventDisplay --disable-mc --disable-root-input | "
fi


if [ x"${RUN_QC}" = "x1" ]; then
    WORKFLOW+="o2-qc ${ARGS_ALL} ${ARGS_QC} --config json:/${SCRIPTDIR}/qc.json ${QC_PROF} | "
fi

WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --run"
#WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --dump"

echo $WORKFLOW > workflow.txt
eval $WORKFLOW
