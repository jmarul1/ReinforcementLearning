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
  libName,libPath = ovrLib if ovrLib else qa.getQaLib(process) 			      ## QA LIBRARY
  workArea = (ovrQA if ovrQA else qa.getQaArea(process))+'/'+workArea; timeout = '30' ## WORK AREA AND ## TIMEOUT in minutes
  if not(all([libName,libPath])): raise IOError('Run in an environment')
  if os.path.exists(workArea): subprocess.call('rm -rf '+workArea,shell=True)
  os.umask(0x002)
  os.mkdir(workArea);
  return libName,libPath,workArea,timeout

def removeOldDir(workArea):
  import os, re, subprocess
  dirname = os.path.dirname(workArea)
  lst = sorted([ff for ff in os.listdir(dirname) if re.search(r'\d+ww\d+p\d+',ff,flags=re.I) and ff != os.path.basename(workArea)])
  if len(lst) > 1: subprocess.call('cd '+dirname+'; rm -rf '+(' '.join(lst[:-1])),shell=True); return dirname+'/'+lst[-1]
  else: return False

def incCds(inc):
  import os, subprocess
  subprocess.run('addLib '+os.path.realpath(inc),shell=True)
  return os.path.realpath(inc)

def checkEnv(dot=None):
  import os, qa, numtools, env
  if os.environ['PROJECT'] in ['p1231','p1222']: os.environ['CDSLIB'],os.environ['PROCESS_NAME'] = env.getPath('$WARD/cds.lib'),(os.environ['PROJECT']).lstrip('p')
  if not(os.getenv('CDSLIB') and os.getenv('PROCESS_NAME')): print((qa.encode('ReRunMe'))); exit(1)
  if dot: os.environ['DR_PROCESS'] = 'dot'+numtools.numToWords(dot);
  os.environ['DR_MSR'] = 'yes'

##############################################################################
# Argument Parsing
##############################################################################
import os, sys, argparse, re, qa, cadence, jobFeed, subprocess, numtools, multiprocessing, qa
checkEnv();
argparser = argparse.ArgumentParser(description='Runs QA for the representative tcs')
argparser.add_argument('-qalib', dest='qaLib', nargs=2, help='Overwrite QA library, give name and path')
argparser.add_argument('-include', dest='inc', type=incCds, help=argparse.SUPPRESS)#help='Additional includes in CDSLIB')
argparser.add_argument('-runarea', dest='runArea', type=os.path.realpath, help='Working dir for running the QA')
argparser.add_argument('-dot', dest='dot', type=str, help='Overwrite DR_PROCESS')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
checkEnv(dot=args.dot);
## prepare the environment lib and dir
libName,libPath,dirQa,timeout = getRunDir(os.getenv('PROCESS_NAME'),args.qaLib,args.runArea); refDir = removeOldDir(dirQa) ##
cdsObj = cadence.readCds('$CDSLIB'); cdsObj.addLibToCds([libName,libPath],force=True);
## read the qaConfig in the library and get the cellnames with flows
cellFlows = qa.readQaConfig(libPath,args.dot);
if cellFlows == False: raise IOError('Library has no qaConfig text files'+libPath)
## read the qaWaiver in the library and create the waiver.csv file
waivers = qa.readQaWaiver(libPath); waiverFile = dirQa+'/waivers.csv'
with open(waiverFile,'w')as fWaive: fWaive.write(waivers)
## run all the cellnames with flows
pool = multiprocessing.Pool(len(cellFlows)); jobs = []; mainLog=open(dirQa+'/'+'batch.runlog','wb'); 
def asyncRun(job, *args): test = qaObj.runQa(*args); return test.communicate()
for cellName,tool,flows in cellFlows:
  with open(dirQa+'/'+cellName+'.tclog','w') as log:
    cellFiles = os.listdir(libPath+'/'+cellName)
    format = libPath+'/'+cellName+'/lnf/lnf.dat' if ('lnf' in cellFiles and 'layout' not in cellFiles) else False # provide the libpath for LNF else use default for GDS (GDS has priority over LNF)
    qaObj = qa.createrun(dirQa,libName,cellName,format);      cdl = {'1231':'sp','1222':'sp','1276':'cdl'}.get(os.getenv('PROCESS_NAME'),'sn')    
    log.write(qaObj.prepTC(flows,cdl=cdl)); ## comment for debug
    jobs.append(pool.apply_async(qaObj.runQa,(timeout,tool),{'interactive':True}))  ## comment for debug
for job in jobs: test = job.get(); mainLog.write(b' '.join([test.stdout,test.stderr]))  ## wait for the jobs to finish
mainLog.close() # update the main log
## use the cellFlows to copy the *stats files to the dirQa for PDSLOGS or just check that they are there
mainLog=open(dirQa+'/'+'mainRunlog.html','w'); mainLog.write('<table cellspacing="4" border="1"><tr><td><center><h3>'+('</h3></center></td><td><center><h3>'.join(['cellName','tool','flow','result']))+'</h3></center></td></tr>\n'); allClear = 0
for cellName,tool,flows in cellFlows:
  for flow in flows:   ## copy the cell to the directory and if it does not exist store it as fail or pass
    status = qa.runStatus(dirQa,tool,cellName,flow)     ## all clear knows if >= 1 there were fail tests
    mainLog.write('<tr><td><center>'+('</center></td><td><center>'.join([cellName,tool,flow,status]))+'</center></td></tr>\n'); allClear += (1 if re.search(r'FAIL',status,flags=re.I) else 0)
mainLog.write('</table>\n'); mainLog.close()
## choose the logs
if os.getenv('PDSLOGS'): #xchip
  logFiles = ' '.join([ff for ff in os.listdir(dirQa) if re.search(r'.stats$',ff)])
  cmd = 'cd '+dirQa+'; htmlReport.py -logs '+logFiles+' -logonly -waiverfile '+waiverFile; runset = os.getenv('ISSRUNSETS')
elif tool == 'icv': pass
else: cmd = f'cd {dirQa}; htmlCalReport.py * -logonly -waiverfile {waiverFile}'; runset=os.getenv('Calibre_RUNSET')#icv
## create the logs
logFiles = subprocess.run(cmd,shell=True,capture_output=True).stdout.decode().split() # realpath for the report + Pass|Fail
if allClear > 0: logFiles[1] = 'FAIL' ## check if any of the runs was aborted and change logFiles[1]  
fOutput = logFiles[0]+' '+mainLog.name+' '+os.path.basename(runset)+' '+logFiles[1]
print(qa.encode(fOutput))
