#!/usr/bin/env python2.7

def getFiles(path,ext): 
  import os
  if not os.path.isdir(path): raise IOError('Bad dir: '+path)
  files = filter(lambda ff: os.path.splitext(ff)[1]==ext, os.listdir(path))
  files = map(lambda ff: os.path.join(path,ff), files)
  return files

def getPairs(mainLst,testLst):
  import re, os
  pairs = [];
  for main in mainLst:
    mainEff = os.path.splitext(os.path.basename(main))[0]; success = False
    for test in testLst:
      if re.search(r''+mainEff,os.path.basename(test)): pairs.append([main,test]); success = True; break
    if not(success) and args.cktDef: pairs.append([main,args.cktDef])
  return pairs

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, csv, subprocess
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import jobFeed, netbatch as nb
argparser = argparse.ArgumentParser(description='Run matchNPortInd.py on SparameterDir with CktDir, files are matched with name.\
SparameterDir used as reference, if ckt does not have a matching pair, the default ckt is used (if exists) otherwise is skipped')
argparser.add_argument('-spdir',dest='spDir',required=True,type=os.path.realpath,help='Sparameter Directory')
argparser.add_argument('-cktdir',dest='cktDir',required=True,type=os.path.realpath,help='Ckt Directory')
argparser.add_argument('-cktdefault',dest='cktDef',default=False,help='Ckt default file')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

spFiles = getFiles(args.spDir,'.s2p')
cktFiles = getFiles(args.cktDir,'.ckt')
if args.cktDef:
  if not os.path.isfile(args.cktDef): raise IOError('Bad cktdefault: '+args.cktDef)
  else: args.cktDef = os.path.realpath(args.cktDef)

## get the pairs with full path
pairs = getPairs(spFiles,cktFiles)

## split in batch of 100
maxRun = 100; listOfPairs = []; 
tempSp = []; tempCkt = []; jobs = []
for nn,(sp,ckt) in enumerate(pairs): 
  tempSp.append(sp); tempCkt.append(ckt)
  if (nn+1)%maxRun == 0 or nn == len(pairs)-1: listOfPairs.append([tempSp,tempCkt]); tempSp=[]; tempCkt=[];
## run in batch of 100
jobs = []
for spLst,cktLst in listOfPairs:
  cmd = 'runRideFitPairs.py -splst '+(' '.join(spLst))+' -cktlst '+(' '.join(cktLst))
  jobs.append(nb.submit(cmd,interactive=True))
print 'Submitted '+str(len(jobs))+' jobs to the batch'
## any lingering jobs
with open('mainLog','wb') as fout:
  while len(jobs) > 0: jobFeed.waitForJobs(jobs,fout)  
exit(0)
