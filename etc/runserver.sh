#!/bin/sh
cd /home/stompserver
>stompserver.log
echo Start >>stompserver.log
x=$(ruby -v)
echo $x >>stompserver.log
# 
# Set command line options.
#
sopts="$*"
#
# Start the server.
#
echo Start server >>stompserver.log
stompserver_ng $sopts
set +x
exit 0
