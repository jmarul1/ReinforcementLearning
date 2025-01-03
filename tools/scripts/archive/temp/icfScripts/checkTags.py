#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret							     #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.  	     #
#									     #
# This is the property of Intel Corporation and may only be utilized	     #
# pursuant to a written Restricted Use Nondisclosure Agreement  	     #
# with Intel Corporation.  It may not be used, reproduced, or		     #
# disclosed to others except in accordance with the terms and		     #
# conditions of such agreement. 					     #
#									     #
# All products, processes, computer systems, dates, and figures 	     #
# specified are preliminary based on current expectations, and are	     #
# subject to change without notice.					     #
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
# Description:
#   Type >> readTags.py -h 
##############################################################################
import argparse, os, itertools, os, re, sys, subprocess, numtools,tempfile
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')

def setDefaults():
  env = os.getenv("PROJECT"); managed = os.getenv("FDK_MANAGED_AREA")
  if env == 'fdk73': oalibs = managed+'/fdk73/oalibs/common/custom/'+os.getenv('D8LIB_VERSION')+'/intel73custom'; 
  elif env == 'f1275': oalibs = managed+'/tld75/oalibs/common/custom/'+os.getenv('CUSTOMLIB_VERSION')+'/intel75custom'
  else: raise EnvironmentError("Run in an environment 1273/1275")
  return oalibs,'kittag_'+os.getenv('KIT_NAME')

def getFiles(path): #how to know if a cellview is given
   if os.path.exists(path):
     if isCellView(path): return [os.path.normpath(path)]
     elif os.path.isdir(path):
       files = map(os.path.normpath, os.listdir(path))
       fileLst = map(lambda ii: os.path.join(path,ii), files)
       if not fileLst: print >> sys.stderr,'The dir: "'+path+'" is empty'
       return fileLst
     else: return [os.path.normpath(path)]
   else: raise argparse.ArgumentTypeError('File or Dir doesn\'t exist: '+path)

def getHist(path,logId): #gets list of all versions, versionTags, authors, dateVals
  test = subprocess.Popen('dssc vhistory '+path,shell=True,stdout=subprocess.PIPE); logId.write(path+'\n')
  output = test.communicate()[0]; logId.write(output+'\n##\n\n'); logId.flush()
  syncDetails = [[],[],[],[]]
  for line in output.splitlines():
    test = re.search(r'^\s*Version:\s+(\d+\.\d+)',line,flags=re.I)
    if test:
      for ii in syncDetails[1:]: #check if all the others up to speed, if not increment to same length
	if not len(syncDetails[0])==len(ii): ii += ['' for jj in xrange(len(syncDetails[0]) - len(ii))]
      syncDetails[0].append(test.group(1)); continue
    for ii,regExp in enumerate(['^\s*Version tags:\s+(.+)','^\s*Author:\s+(.+)','^\s*Date:\s+(.+)']):
      test = re.search(r''+regExp,line)
      if test: syncDetails[ii+1].append(test.group(1)); break
  return syncDetails #version,versionTags,author,dateVal 

def isCellView(path):
  if not os.path.isdir(path): return False
  dirs = filter(lambda ff: os.path.isdir(os.path.join(path,ff)),os.listdir(path))
  if not(dirs and '.SYNC' in dirs): return False
  dirs = map(lambda ff: os.path.join(path,ff),dirs)
  for test in dirs: ## if any of the sub-directories have ".oa" files stop, it is a cell
    if any(map(lambda ff: os.path.splitext(ff)[1]=='.oa', os.listdir(test))): return True
  return False
 
##############################################################################
# Argument Parsing
##############################################################################
oalibs,kittag = setDefaults()
argparser = argparse.ArgumentParser(description='Prints cells/files with tags where kittag != latest')
argparser.add_argument(dest='input', nargs='+', type=getFiles, help='Dir/File to check')
argparser.add_argument('-tag', dest='tag', default=kittag, help='kittag to test for')
argparser.add_argument('-keeplog',dest='keeplog',action='store_true',help=argparse.SUPPRESS)  
args = argparser.parse_args();
##############################################################################
# Main Begins
##############################################################################
if not any(args.input): raise IOError('Input dir(s) is empty')
args.input = filter(lambda ff: not re.search(r'.SYNC',ff),set(itertools.chain(*args.input)))
outLst = ['############################','Collateral,'+args.tag+',Latest']; nn=0; 
## run for all inputs
print >> sys.stderr,'Checking for TAG: '+args.tag
##log
logFile = tempfile.mkstemp(suffix='_tagcheck.log',dir='.')[1]; logId=open(logFile,'wb')
if not logId: raise IOError('Could not open logfile '+os.path.normpath(logFile))
for iiIn in args.input:
  sys.stderr.write('... '+numtools.numToStr(float(nn)/len(args.input)*100,1)+'% complete\r'),
  if os.path.isdir(iiIn): 
    #get the components and filter the .SYNC
    components = os.listdir(iiIn);
    if not any(components): print >> sys.stderr,'The dir: "'+iiIn+'" is empty'; continue
    components = map(lambda ii: iiIn+'/'+ii, filter(lambda ff: ff!= '.SYNC', components)) # remove any sync
    #run for each component
    for cc in components:
      if os.path.isdir(cc): cc += '.sync.cds'
      versions,versionTags,authors,dateVals = getHist(cc,logId)      ## get the history
      ## check the length of all is the same
      if not all(map(lambda ff: ff==len(versions), map(len,[versions,versionTags,authors,dateVals]))): print >> sys.stderr,cc+' has mirror/history issues '; continue
      ## check if the tag exist in the history and get the index where is at
      for ii,vv in enumerate(versionTags):
        vv = map(str.strip, vv.split(','))
        if (args.tag in vv) and ii != len(versions)-1: # we have a tag not in the latest
	  outLst.append(','.join([cc.lstrip('./').rstrip('.sync.cds'),versions[ii],versions[-1]])); break  
  else:
    versions,versionTags,authors,dateVals = getHist(iiIn,logId)      ## get the history
    ## check the length of all is the same
    if not all(map(lambda ff: ff==len(versions), map(len,[versions,versionTags,authors,dateVals]))): print >> sys.stderr,iiIn+' has mirror/history issues'; continue
    ## check if the tag exist in the history and get the index where is at
    for ii,vv in enumerate(versionTags):
      vv = map(str.strip, vv.split(','))
      if (args.tag in vv) and ii != len(versions)-1: # we have a tag not in the latest
	outLst.append(','.join([iiIn.lstrip('./').rstrip('.sync.cds'),versions[ii],versions[-1]])); break  
  ## update progress
  nn+=1; sys.stderr.write('... '+numtools.numToStr(float(nn)/len(args.input)*100,1)+'% complete\r'),

## print the results
if len(outLst) == 2: outLst.append('ALL CLEAN')
print '\n'.join(outLst)

if not args.keeplog: subprocess.call('sleep 5 && rm -f '+logFile+' &',shell=True)      
