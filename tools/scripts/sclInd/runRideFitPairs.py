#!/usr/bin/env python2.7

##############################################################################
# Argument Parsing
##############################################################################
import argparse, subprocess, sys, os
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import jobFeed
argparser = argparse.ArgumentParser(description='Run matchNPortInd.py on spFiles vs cktFiles, in the order given')
argparser.add_argument('-splst',dest='spLst',required=True,nargs='+',help='Sparameter Files')
argparser.add_argument('-cktlst',dest='cktLst',required=True,nargs='+',help='Ckt Files')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
if len(args.spLst) != len(args.cktLst): raise IOError('Bad count of files: '+str(len(args.spLst))+' - '+str(len(args.cktLst)))
## run all
jobs = []
for sp,ckt in zip(args.spLst, args.cktLst): 
  cmd  = 'matchNPortInd.py -ckt '+ckt+' -override 20 -- '+sp
  jobs.append(subprocess.Popen(cmd,shell=True))
## wait for jobs to end
while len(jobs) > 0: jobFeed.waitForJobs(jobs,False)  
