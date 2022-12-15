#! /bin/bash

rm -f /tmp/flp/ccdb.txt
nohup ./start-ccdb.sh > /dev/null&

while [ ! -f /tmp/flp/ccdb.txt ]; do
    sleep 1
done
sleep 5

cd ~/alibuild-test/WebUi/QualityControl/
nohup npm start > /dev/null&
