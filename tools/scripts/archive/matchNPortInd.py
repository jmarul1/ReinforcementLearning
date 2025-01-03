#!/usr/bin/env python3.7.4
import python3; python3.move()
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2013, Intel Corporation.  All rights reserved.               #
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
#
# Author:
#   Mauricio Marulanda
#
# Description:
#   Type >> matchNPortInd.py -h
#
##############################################################################

def checkFile(path):
  if os.path.isfile(path): 
    if re.search(r'\.s\d+p$',path,flags=re.I): return os.path.realpath(path)
    else: return False
  else: raise argparse.ArgumentTypeError('File doesn\'t exist or is a directory: '+path)

def createNewCkt(tempDir,spFileName):
  import ride
  cktFile,spFile,logFile = map(lambda ff: tempDir+'/'+spFileName+ff,['.ckt','.sp','_match.log'])
  if all(map(os.path.isfile,[cktFile,spFile,logFile])):
    rObj = ride.read(cktFile);
    rObj.updateCkt(spFile,logFile)
    rObj.printCkt(tempDir+'/'+spFileName+'_next.ckt')
    return tempDir+'/'+spFileName+'_next.ckt'

def computeError(spFile,scsFile,srf,tempDir='.'):
  import sparameter, cmpIndCsv, subprocess as sb
  sp = sparameter.read(tempDir+'/'+spFile); freqs = numtools.numToStr(srf,0)
  qtol,ltol = map(str,args.recursive[1:])
  ## compute the csv for the sparameter
  sb.call('cd '+tempDir+'; ~jmarulan/work_area/utils/scripts/calculateQLSp.py -csv sparam -- '+spFile,shell=True,stderr=sb.PIPE)
  sb.call('cd '+tempDir+'; ~jmarulan/work_area/utils/scripts/calculateQLNetlist.py -csv ckt -maxfreq '+freqs+'G -- '+scsFile,shell=True,stderr=sb.PIPE)
  ref = tempDir+'/sparam_'+os.path.splitext(spFile)[0]+'_QL.csv'; test = tempDir+'/ckt_'+os.path.splitext(scsFile)[0]+'_QL.csv'
  ## compute the error
  result,errorStr = cmpIndCsv.mainExe([ref,test,'-qtol',qtol,'-ltol',ltol,'-range',freqs,'-ftol','0.5'])
  with open(tempDir+'/'+os.path.splitext(spFile)[0]+'_Error.csv','wb') as fout: fout.write('\n'.join(errorStr))
  return result

def reRun(spFile,cktFile,tempDir):
  import subprocess, ride
  iteration = str(args.recursive[0]-1); rObj = ride.read(cktFile); qOnly = rObj.getOption('qOnly');
  freqOvr = ' -override '+str(args.override) if args.override else ''
  qOnly = '1' if qOnly == '0' else '0' #revert to 0 or to 1  
  rObj.updateCktOptions(qOnly=qOnly,convertToY=qOnly); rObj.printCkt(cktFile)
  print >> sys.stderr,'Re-running: '+os.path.basename(os.path.splitext(spFile)[0])+': Iteration: - '+iteration+' / .qOnly='+qOnly
  cmd = os.path.expanduser('~jmarulan/work_area/utils/scripts/matchNPortInd.py')+' '+spFile+' -ckt '+nextCkt+' -tempdir '+tempDir+freqOvr
  cmd += ' -recursive '+iteration+' '+(' '.join(map(lambda ff: str(ff*100)+'%',args.recursive[1:])))
  subprocess.call(cmd,shell=True) ## 
    
def checkRecur(threeNums):
  import numtools
  iteration = int(threeNums[0])
  qtol = numtools.percToNum(threeNums[1]); ltol = numtools.percToNum(threeNums[2])
  return iteration,qtol,ltol
    
##############################################################################
# Argument Parsing
##############################################################################
import sys, os, tempfile, subprocess, re,shutil
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import sparameter as sp, netbatch as nb, argparse, numtools, cmpIndCsv, ride
argparser = argparse.ArgumentParser(description='This program matches sparameter to a given ckt netlist using RIDE')
argparser.add_argument(dest='spFiles', nargs='+', type=checkFile, help='Sparameter file(s)')
argparser.add_argument('-ckt', dest='ckt', required=True, type=ride.read, help='Circuit file used by ride to match the subckt')
argparser.add_argument('-override', dest='override', nargs='?', const=-1, type=float, help='Run up to this frequency (GHz), if no argument up to maxFreq of the sparameter')
argparser.add_argument('-recursive', dest='recursive', nargs=3, help='Run until PASS (cmpIndCsv.py method) or max iteration; \
arg1 -> alternate each iteration with sparameter(0)/DiffSe(1) matching;\
arg2->Qtolerance; arg3->Ltolerance. --- arg2,arg3 are percentage values, enter "10 or 10%%" for 10%%')
argparser.add_argument('-tempdir',dest='tempDir',type=os.path.realpath,help=argparse.SUPPRESS)       
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## if possible put a skew and prepare any iteration
skew = re.search(r'(pcss|tttt|pcff|prcs|prcf)',args.ckt.cktFile,flags=re.I)
suffixHelp = skew.group(1) if skew else ''
if args.recursive: args.recursive = checkRecur(args.recursive)

## create temp Dir or use given
tempDir = args.tempDir if args.tempDir else tempfile.mkdtemp(dir='.',prefix='match', suffix=suffixHelp)
## start working, send all runs simultaneously
runRideLst=[]
for spFile in filter(lambda ff: ff != False,set(args.spFiles)):
  ## Check files exist
  if not os.path.isfile(args.ckt.cktFile): raiseIOError('Given circuit file does not exists:'+args.ckt.cktFile)
  ## get files ready 
  spFileName,spFileExt = os.path.splitext(os.path.basename(spFile))
  if not(os.path.isfile(tempDir+'/'+spFileName+spFileExt) and os.path.samefile(spFile,tempDir+'/'+spFileName+spFileExt)): shutil.copy(spFile,tempDir+'/'+spFileName+spFileExt)
  sparam = sp.read(spFile)
  srf={'diff':sparam.getIndSRF()}
  if srf['diff'] == False and not args.override: print >> sys.stderr,'Sparam must reach differential SRF, skipping:'+spFile;  
  else: ## chose the lower value of srf or args.override
    if srf['diff'] == False: srf['diff'] = sparam.freq[-1]
    if args.override and srf['diff'] > args.override and args.override > sparam.freq[0]: 
      test = numtools.closestNum(sparam.freq,args.override,0.5)
      if test == -1: raise IOError('Override frequency not close enough to any value: '+str(args.override))
      srf['diff'] = sparam.freq[test]
  ## append the new frequency and put the files in the tempdir
    maxFreqI = sparam.freq.index(srf['diff'][0]); args.ckt.updateCktOptions(maxFreqIndex=maxFreqI); 
    args.ckt.printCkt(tempDir+'/'+spFileName+'.ckt');
    ## run ride command
    rideCmd = 'cd '+tempDir+' ; /nfs/site/eda/group/SYSNAME/tcad/RFDesigner/ride/ride -match='+spFileName+spFileExt+' -circuit='+spFileName+'.ckt -output='+spFileName+'_ckt'+spFileExt+' > '+spFileName+'_match.log'
    runRideLst.append(tuple([spFileName,spFileExt,subprocess.Popen(rideCmd,shell=True),srf['diff'][0]]))
## Wait for completion
for spFileName,spFileExt,runRide,srf in runRideLst:
  runRide.communicate()
#  print spFileName,runRide
  if os.path.isfile(tempDir+'/'+spFileName+'.sp'):
    ## fix the model names inside the output netlist and change the pins with p_ehv n_ehv
    subprocess.call('cd '+tempDir+'; '+os.path.expanduser('~jmarulan/work_area/utils/scripts/convertSpFile.py')+' '+spFileName+'.sp',shell=True)
    ## create the new ckt file for future run if necessary
    nextCkt = createNewCkt(tempDir,spFileName)
    ## Check the passing criteria if requested to iterate keep going
    if args.recursive:
      result = computeError(spFileName+spFileExt,spFileName+'.scs',srf,tempDir) ## if True we achieved SUCCESS
      if result: subprocess.call('cp '+tempDir+'/'+spFileName+'.scs ./; echo Finished '+spFileName+' PASS criteria, see ./'+tempDir+' >> mainMatchRide.log',shell=True)
      elif args.recursive[0] > 0: reRun(tempDir+'/'+spFileName+spFileExt,nextCkt,tempDir) ## keep going for one more with new ckt and swap the qOnly
      else: subprocess.call('echo Finished '+spFileName+' FAIL criteria >> mainMatchRide.log',shell=True) ## we are done with no good result
    else: subprocess.call('echo Finished '+spFileName+' >> mainMatchRide.log',shell=True) ## requested to only run once
  else:
    print >> sys.stderr,'Something went wrong with Ride for: '+tempDir+'/'+spFileName+'_match.log'
