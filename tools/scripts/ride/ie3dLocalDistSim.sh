#!/bin/sh
##############################################################################
# Author:
#   Mauricio Marulanda
# Description: Runs Inductor Simulations in distributed mode
##############################################################################

#jcol -x $1  ##remove for 15.3
ie3dos --rma 2 --rmonly $1
jcol -r $1 &
jobPid=$!

#let the program do initializations worst case at 1 second
sleep 1 
jexe -e ready $1 --argv -m 201 -l 40

#number of network nodes
nodes=4

#start local jobs
for ii in `seq $nodes`
do
  jexe -q $1 --argv -m 201 -l 40 &
done

#wait main job to finish
wait $jobPid
