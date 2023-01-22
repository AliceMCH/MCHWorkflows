#! /bin/bash

(cd Software/alice/sw/BUILD/O2-latest/O2 && cmake --build . -- -j 4 install) || exit 1
(cd Software/alice/sw/BUILD/QualityControl-latest/QualityControl/ && cmake --build . -- -j 4 install) || exit 1
