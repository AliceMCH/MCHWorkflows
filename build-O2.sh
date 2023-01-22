#! /bin/bash

mkdir -p Software
cd Software

export ALIBUILD_WORK_DIR="$(pwd)/alice/sw"
eval "`alienv shell-helper`"

O2_BRANCH=$(cd O2 && git rev-parse --abbrev-ref HEAD)
QC_BRANCH=$(cd QualityControl && git rev-parse --abbrev-ref HEAD)

#DEFAULTS=o2-dataflow
DEFAULTS=o2-epn

aliBuild init O2@${O2_BRANCH} --defaults ${DEFAULTS}
aliBuild init QualityControl@${QC_BRANCH} --defaults ${DEFAULTS}
aliBuild init DataDistribution@dev --defaults ${DEFAULTS}

aliBuild -j 4 build O2Suite --defaults ${DEFAULTS} $1
