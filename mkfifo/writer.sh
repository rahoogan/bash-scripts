#!/bin/bash
echo $$ > /tmp/pid
pipe=/tmp/datapipe

rm $pipe
# Create Data pipe if it doesn't exist
if [[ ! -p $pipe ]]; then
   echo "Pipe does not exist. Creating..."
   mkfifo $pipe
fi

echo "Hello" >$pipe

function write_data {
   echo "Writing data"
   echo "Here is some data" >$pipe &
}

function kill {
   echo "Exiting"
   exit
}

# Listen for signals
trap write_data SIGINT 
trap kill KILL

while true; do
   sleep 1;
done
