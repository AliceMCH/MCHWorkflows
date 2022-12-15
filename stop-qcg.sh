#! /bin/bash

CCDBPID=$(ps ux | grep 'java -jar local.jar' | head -n 1 | tr -s ' ' | cut -d ' ' -f 2)
kill $CCDBPID

QCGPID=$(ps ux | grep 'node index.js' | head -n 1 | tr -s ' ' | cut -d ' ' -f 2)
kill $QCGPID
