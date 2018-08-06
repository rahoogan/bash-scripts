#!/bin/bash
pipe=/tmp/datapipe
pid=`cat /tmp/pid`  # Read the pid

if [[ ! -p $pipe ]]; then
   mkfifo $pipe
fi

#kill -s INT $pid

if read line <$pipe; then
   echo $line
fi
