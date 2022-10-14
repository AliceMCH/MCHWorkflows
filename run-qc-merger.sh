#! /bin/bash

o2-qc --config $1 -b --remote --run #>& log-merger.txt
