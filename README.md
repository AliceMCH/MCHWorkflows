# MCHWorkflows
Reference O2 workflows to test the MCH data processing

Some examples:

### Full MCH reconstruction, process CTFs from a list in a text file

`./reco.sh ctflist.txt`

### Full MCH reconstruction, process TFs from a list in a text file

`INPUT_TYPE=tflist ./reco.sh tflist.txt`

### Specify the magnets currents

`L3_CURRENT=-30000 DIPOLE_CURRENT=-6000 ./reco.sh ctflist.txt`

### Disable the QC

`RUN_QC=0 ./reco.sh ctflist.txt`

### Disable all processing steps starting from the clustering

`RUN_CLUSTERING=0 ./reco.sh ctflist.txt`

### Set the QC cycle duration (in seconds)

`QC_CYCLE_DURATION=60 ./reco.sh ctflist.txt`

### Create a list of CTF from a grid folder

`./mk-ctf-list.sh /alice/data/2022/LHC22e/519041/raw/1120 > ctflist.txt`

### Create a list of TF from a grid folder

`./mk-tf-list.sh /alice/data/2022/JUN/517824/raw/1450 > tflist.txt`