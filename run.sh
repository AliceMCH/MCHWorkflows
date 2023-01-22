#! /bin/bash

RUN=$1
CTFLIST=Outputs/run00${RUN}/ctflist.txt
NCTF=$(cat "${CTFLIST}" | wc -l)
echo "Total number of CTF is $NCTF"
D=100
CTF=0
I=1

rm -f Outputs/run00${RUN}/*.root.*

while [ $CTF -lt $NCTF ]; do

  CTF=$((CTF+D))
  cat "${CTFLIST}" | head -n $CTF | tail -n $D > /tmp/ctflist.txt
  echo "Reading CTFs from $((CTF-D+1)) to $CTF"

  rm /dev/shm/fmq_327079f0_m*
  for F in qc-mch-digits.root qc-mchmid-tracks.root qc-mch-preclusters.root qc-mch-tracks.root qc-mftmchmid-tracks.root; do
    rm -f "${F}"
  done

  RUN_QC=1 RECO_MCH=1 RECO_MFT=1 RECO_MID=1 QC_CYCLE_DURATION=600 MAX_TF=-1 TFDELAY=10 INPUT_TYPE=ctflist ./reco.sh /tmp/ctflist.txt

  for F in qc-mch-digits.root qc-mchmid-tracks.root qc-mch-preclusters.root qc-mch-tracks.root qc-mftmchmid-tracks.root; do
    if [ ! -e "$F" ]; then
      continue
    fi
    cp -a "$F" "Outputs/run00${RUN}/${F}.${I}"
    rm -f "Outputs/run00${RUN}/${F}"
    hadd "Outputs/run00${RUN}/${F}" Outputs/run00${RUN}/${F}.*
  done
  echo "Iteration $I finished"

  I=$((I+1))
  sleep 10m
  echo ""

done
