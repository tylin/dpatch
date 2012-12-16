#!/bin/bash
ps -ef | grep dskeeprunning | grep -v grep | awk '{print $2}' | xargs kill -9
ps -ef | grep dsinterruptor | grep -v grep | awk '{print $2}' | xargs kill -9
ps -ef | grep qsubfile | grep -v grep | awk '{print $2}' | xargs kill -9
for f in `ls $1/pid*`
do
  kill -9 `head -n 1 $f`
done
for f in `ls $1/matpid*`
do
  kill -9 `head -n 1 $f`
done
