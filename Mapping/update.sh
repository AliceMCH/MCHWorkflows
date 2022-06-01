#! /bin/bash

cat cru-*.map > temp-cru.map
./convert-map temp-cru.map > cru.map
cat fec-*.map > fec.map
