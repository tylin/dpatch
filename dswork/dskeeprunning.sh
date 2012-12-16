#!/bin/bash
# all output from a worker node gets piped through here.  Restarts the dsmpareducer thread
# when it receives an interrupt signal.
#b="Operation terminated by user during";
echo $2 > $1;
while read nextline
do
echo "$nextline"
#echo "hi";
if grep -q "Operation terminated by user during" <<< $nextline; then
  echo "dsmapreducer;" > $1;
fi
if grep -q "dskeeprunning:cuetoexit" <<< $nextline; then
  exit;
fi
#if grep -q "Op" <<< $nextline; then echo "1"; fi
done
