#!/bin/ksh
# run on a linux system. 

FILENAME=$1
echo "user CPU ==="
egrep -v "procs|free" $FILENAME |awk '{print $13;}' |sort -k 1 -nr |uniq -c

echo "sys CPU ==="
egrep -v "procs|free" $FILENAME |awk '{print $14;}' |sort -k 1 -nr |uniq -c

echo "idle CPU ==="
egrep -v "procs|free" $FILENAME |awk '{print $15;}' |sort -k 1 -nr |uniq -c

echo "wait CPU ==="
egrep -v "procs|free" $FILENAME |awk '{print $16;}' |sort -k 1 -nr |uniq -c


