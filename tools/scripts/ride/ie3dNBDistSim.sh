#!/bin/sh
##############################################################################
#
#
#
# OBSOLETE DO NOT USE
#
#
#
#
#
# Author:
#   Mauricio Marulanda
# Description: Runs Inductor Simulations in batch mode
##############################################################################
echo 'DO NOT USE THIS SCRIPT, rework your code'
#jcol -x $1 #remove for 15.3
ie3dos --rma 2 --rmonly $1
jcol -r $1 &
jobPid=$!

#let the program do initializations worst case at 1 seconds
sleep 1 
jexe -e ready $1 --argv -m 201 -l 40

#number of network nodes
networkNodes=1

#send to the batch
for ii in `seq $networkNodes`
do
  parameters="start_app jexe -q $1 --argv -m 201 -l 40"
  temp=`nbq -P ch_vp -C SLES11_EM64T_8G -Q /ciaf/pck_max $parameters -noautostart &`
  nbPid[$ii]=`expr "$temp" : ".*[jJ][oO][bB][iI][dD] *\([0-9]*\).*"`
done

# Wait main job to finish
wait $jobPid
echo MAO2
#######################################################################################
# If jobs are still running KILL them since S-Parameter file has been created already #
# The removal takes advantage of IE3D's partial frequency convergance #################
# Wait for the batch to clear #########################################################
#######################################################################################

pollWait=2 # wait 2 seconds before each netbatch check
waitStr="\(Wait\|Run\|Send\)"
for ii in `seq $networkNodes`
do
  temp=`nbqstat -P ch_vp "jobid=${nbPid[$ii]}" | grep "${waitStr} *${nbPid[$ii]}"`
   if [ "$temp" != "" ]
   then
     nbjob remove --target ch_vp "jobid == ${nbPid[$ii]}" 
   fi
  while [ "$temp" != "" ]  
  do
    sleep $pollWait
    temp=`nbqstat -P ch_vp "jobid=${nbPid[$ii]}" | grep "${waitStr} *${nbPid[$ii]}"`

  done
done
exit 0
