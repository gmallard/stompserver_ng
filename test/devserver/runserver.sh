#!/bin/bash
#
set -x
#
PH=$(pwd)
echo "Project Home: $PH"
mtype=${QMEM:-.file}
CONFIG=$PH/test/devserver/stompserver_ng${mtype}.conf
echo "Using Config: $CONFIG"
#
FLAGS="--log_level=debug --config=$CONFIG $*"
#
ruby -I $(pwd)/lib bin/stompserver_ng $FLAGS
#
set +x

