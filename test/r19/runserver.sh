#!/bin/bash
#
set -x
#
PH=$(pwd)
echo "Project Home: $PH"
CONFIG=$PH/test/r19/stompserver.conf
echo "Using Config: $CONFIG"
#
FLAGS="--debug --config=$CONFIG"
#
ruby -I $(pwd)/lib bin/stompserver $FLAGS
#
set +x

