#! /bin/bash

(cd Software/alice/sw/BUILD/O2-latest/O2 && ctest -N -L mch -R Raw && ctest -L mch -R Raw --show-only=json-v1 --output-on-failure) || exit 1
(cd Software/alice/sw/BUILD/O2-latest/O2 && ctest -N -L mch && ctest -L mch --output-on-failure) || exit 1
