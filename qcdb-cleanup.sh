#! /bin/bash

NOBJECTS=${NOBJECTS:-2}

while [ true ]; do

find /tmp/flp/QC/ -type f -name "*.properties" > /tmp/flp/qcdb.txt

while read line; do

    dir1=$(dirname "$line")
    dir2=$(dirname "$dir1")
    #echo "DIR: $dir2"

    while [ true ]; do

        versions=$(ls -1rt "$dir2")
        #echo "versions: $versions"
        nv=$(ls -1rt "$dir2" | wc -l)
        #echo "NV: $nv"

        if [ $nv -le ${NOBJECTS} ]; then
            break
        fi
        v1=$(ls -1rt "$dir2" | head -n 1)
        echo "rm -rf \"$dir2/$v1\""
        rm -rf "$dir2/$v1"

    done

done < /tmp/flp/qcdb.txt

sleep 60m

done
