#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2016, Intel Corporation.  All rights reserved.               #
#                                                                            #
# This is the property of Intel Corporation and may only be utilized         #
# pursuant to a written Restricted Use Nondisclosure Agreement               #
# with Intel Corporation.  It may not be used, reproduced, or                #
# disclosed to others except in accordance with the terms and                #
# conditions of such agreement.                                              #
#                                                                            #
# All products, processes, computer systems, dates, and figures              #
# specified are preliminary based on current expectations, and are           #
# subject to change without notice.                                          #
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def getRunDir(process,ovrLib,ovrQA): # based on the env we know what qaLib to use
  import datetime,os,subprocess,qa
  temp = datetime.date.today().isocalendar(); workArea = str(temp[0])+'ww'+str(temp[1])+'p'+str(temp[2])
  if ovrLib: libName,libPath = ovrLib
  elif process == '1222': libName,libPath = 'b88libqa','/nfs/pdx/disks/x22a.disk.8/work_x22a/wict_de/official/b88libqa'
  else: raise IOError('Run in an environment')
  workArea = (ovrQA if ovrQA else qa.getQaArea(process))+'/'+workArea; timeout = '30' ### TIMEOUT
  if os.path.exists(workArea): subprocess.call('rm -rf '+workArea,shell=True)
  #print subprocess.call('groups',shell=True)
  os.mkdir(workArea);
  return libName,libPath,workArea,timeout

def removeOldDir(workArea):
  import os, re, subprocess
  dirname = os.path.dirname(workArea)
  lst = sorted([ff for ff in os.listdir(dirname) if re.search(r'\d+ww\d+p\d+',ff,flags=re.I) and ff != os.path.basename(workArea)])
  if len(lst) > 1: subprocess.call('cd '+dirname+'; rm -rf '+(' '.join(lst[:-1])),shell=True); return dirname+'/'+lst[-1]
  else: return False

def incCds(inc):
  import os
  with open(os.getenv('CDSLIB'),'ab') as fout: fout.write('\nINCLUDE '+os.path.realpath(inc)+'\n')
  return os.path.realpath(inc)

def checkEnv(dot=None):
  import os, qa, numtools
  if not(os.getenv('CDSLIB') and os.getenv('PROCESS_NAME')): print((qa.encode('ReRunMe'))); exit(1)
  if dot: os.environ['DR_PROCESS'] = 'dot'+numtools.numToWords(dot);
  os.environ['DR_MSR'] = 'yes'
#  import subprocess;  subprocess.call('ls -ltr $PDS_OVERRIDES/include',shell=True); exit(1)

##############################################################################
# Argument Parsing
##############################################################################
import os, sys; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/scripts'))
import argparse, re, qa, cadence, jobFeed, subprocess, numtools
checkEnv();
argparser = argparse.ArgumentParser(description='Runs QA for the representative tcs')
argparser.add_argument('-qalib', dest='qaLib', nargs=2, help='Overwrite QA library, give name and path')
argparser.add_argument('-include', dest='inc', type=incCds, help='Additional includes in CDSLIB')
argparser.add_argument('-runarea', dest='runArea', type=os.path.realpath, help='Use this for running the QA')
argparser.add_argument('-dot', dest='dot', type=str, help='Overwrite DR_PROCESS')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
checkEnv(dot=args.dot);
## prepare the environment lib and dir
libName,libPath,dirQa,timeout = getRunDir(os.getenv('PROCESS_NAME'),args.qaLib,args.runArea); refDir = removeOldDir(dirQa)
cdsObj = cadence.readCds('$CDSLIB'); cdsObj.addLibToCds([libName,libPath],force=True);
## read the qaConfig in the library and get the cellnames with flows
cellFlows = qa.readQaConfig(libPath,args.dot);
if cellFlows == False: raise IOError('Library has no qaConfig text files'+libPath)
## read the qaWaiver in the library and create the waiver.csv file
waivers = qa.readQaWaiver(libPath); waiverFile = dirQa+'/waivers.csv'
with open(waiverFile,'w')as fWaive: fWaive.write(waivers)
## run all the cellnames with flows
jobs = []; mainLog=open(dirQa+'/'+'batch.runlog','wb')
for cellName,tool,flows in cellFlows:
  with open(dirQa+'/'+cellName+'.tclog','w') as log:
    cellFiles = os.listdir(libPath+'/'+cellName)
    format = libPath+'/'+cellName+'/lnf/lnf.dat' if ('lnf' in cellFiles and 'layout' not in cellFiles) else False # provide the libpath for LNF else use default for GDS (GDS has priority over LNF)
    qaObj = qa.createrun(dirQa,libName,cellName,format)
    log.write(qaObj.prepTC(flows, cdl=True if os.getenv('PROCESS_NAME') == '1276' else False));    ## comment for debug
    jobs.append(qaObj.runQa(timeout)); ## comment for debug
## wait for the jobs to finish, python waits on the cleanPdsLogs background job
while jobs: jobFeed.waitForJobs(jobs,mainLog);
mainLog.close()
## use the cellFlows to copy the *stats files to the dirQa
logDir = os.getenv('PDSLOGS'); mainLog=open(dirQa+'/'+'mainRunlog.html','w'); mainLog.write('<table cellspacing="4" border="1"><tr><td><center><h3>'+('</h3></center></td><td><center><h3>'.join(['cellName','tool','flow','result']))+'</h3></center></td></tr>\n'); allClear = 0
for cellName,tool,flows in cellFlows:
  for flow in flows:   ## copy the cell to the directory and if it does not exist store it as fail or pass
    testF = logDir+'/'+cellName+'.'+flow+'.stats'; abortF = logDir+'/'+cellName+'.'+flow+'.iss.log.abort'; currentF = logDir+'/'+cellName+'.'+flow+'.iss.current';
    testL = logDir+'/'+cellName+'.'+flow+'.icvlvs.stats' if flow == 'trclvs' else ''
    if os.path.exists(testF) and (flow!='trclvs' or os.path.exists(testL)):
      subprocess.call('cp '+testF+' '+testL+' '+dirQa,shell=True); status = 'SUCCESS\n'
    elif os.path.exists(abortF): subprocess.call('cp '+abortF+' '+dirQa,shell=True); status = '<font color="red">FAIL</font>\n'
    elif os.path.exists(currentF): subprocess.call('cp '+currentF+' '+dirQa,shell=True); status = '<font color="red">FAIL</font>\n'
    else: status= '<font color="red">FAIL</font>\n'
    mainLog.write('<tr><td><center>'+('</center></td><td><center>'.join([cellName,tool,flow,status]))+'</center></td></tr>\n'); allClear += (1 if re.search(r'FAIL',status,flags=re.I) else 0)
mainLog.write('</table>\n'); mainLog.close()
## create the logs
logFiles = ' '.join([ff for ff in os.listdir(dirQa) if re.search(r'.stats$',ff)])
if logFiles:
  logFiles = subprocess.run('cd '+dirQa+'; htmlReport.py -logs '+logFiles+' -logonly -waiverfile '+waiverFile,shell=True,capture_output=True); 
  logFiles = logFiles.stdout.decode().split() # realpath for the report + Status
  if allClear > 0: logFiles[1] = 'FAIL' ## check if any of the runs was aborted and change logFiles[1]
  print((qa.encode(logFiles[0]+' '+os.path.realpath(mainLog.name)+' '+os.path.basename(os.getenv('ISSRUNSETS'))+' '+logFiles[1])))
else:
  print((qa.encode(os.path.realpath(dirQa)+' '+os.path.realpath(mainLog.name)+' '+os.path.basename(os.getenv('ISSRUNSETS')))))
exit(0)
