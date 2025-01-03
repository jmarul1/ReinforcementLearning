#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def cleanPdsLogs(cellFlowLst,logDir,duration):
  import os, re, time, subprocess
  maxTime = time.time() + duration*60 #maximum time to keep running
  while cellFlowLst and (time.time() < maxTime):
    lst = os.listdir(logDir)
    if not lst: continue
    for ii,(cell,flow) in enumerate(cellFlowLst):
      erase = []
      if any([os.path.exists(logDir+'/'+cell+'.'+flow+ff) for ff in ['.stats','.iss.log.abort']]): ## run is done
        tgt = [ff for ff in lst if not(re.search(r'(stats|abort|cmpall|current)$',ff)) and re.search(r'^'+cell+'.'+flow,ff)]
        cmd = 'cd '+logDir+' ; rm -rf '+(' '.join(tgt)); subprocess.call(cmd,shell=True)
        erase.append(ii)
    if erase: [cellFlowLst.pop(ii) for ii in sorted(erase,reverse=True)]
    else: subprocess.call('sleep 20',shell=True) ## wait a little

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess, re, time
argparser = argparse.ArgumentParser(description='Keep only the *.stats for given inputs')
argparser.add_argument(dest='cellflow', nargs = '+', help='cell flow pairs')
argparser.add_argument('-maxduration', dest='duration', type=int, default=1,help='minutes to keep trying')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))

if len(args.cellflow)%2 != 0: raise IOError('wrong number of inputs')
inputs = []
for ii in range(0,len(args.cellflow),2): inputs.append([args.cellflow[ii],args.cellflow[ii+1]])
cleanPdsLogs(inputs[:],os.getenv('PDSLOGS'),args.duration);  
logs = ['-'.join(ff) for ff in inputs]
print('\nCleaned up:\n'+('\n'.join(logs)))
