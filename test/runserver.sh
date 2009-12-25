#!/bin/bash
#
set -x
#
PH=$(pwd)
echo "Project Home: $PH"
mtype=${QMEM:-.file}
CONFIG=$PH/test/stompserver${mtype}.conf
echo "Using Config: $CONFIG"
#
FLAGS="--log_level=debug --config=$CONFIG $*"
#
ruby -I $(pwd)/lib bin/stompserver $FLAGS
#
set +x

