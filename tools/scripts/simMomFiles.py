#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> simMomFiles.py -h
##############################################################################

def dsName(fpath):  
  if os.path.isfile(fpath+"/proj.opt"):
    with open(fpath+"/proj.opt") as fin:
      for line in fin: 
        test = re.search(r'DS_NAME\s+"?(.*?)"?\s*;',line)
        if test: print((test.group(1))); return test.group(1)
  return False

def setCalToNone(fpath):
  import xlm
  xlmObj = xlm.read(fpath+'/proj.prt'); xlmObj.remove(['calibration_group_list','calibration_group_ref']) #first file
  xlmObj.write(fpath+'/proj.prt')
  with open(fpath+'/emStateFile.xml') as fin: 
    newString = re.sub(r'(type.*?\>\s*)TML(\s*)',r'\1None\2',fin.read()) ## second file
    newString = re.sub(r'(type.*?\>\s*)Auto(\s*)',r'\1Direct\2',newString) ## second file    
  with open(fpath+'/emStateFile.xml','w') as fout: fout.write(newString)

def getOutNames(fpath):
  fpath = os.path.realpath(ff)
  test = re.search(r'(.*)/simulation/.*/layout/',fpath,flags=re.I)
  outDir = test.group(1)+'/data' if test else '.'
  outName = dsName(fpath)
  if outName == False:
    test = re.search(r'.*/simulation/.*/(.*)/layout/',fpath,flags=re.I)
    outName = test.group(1) if test else os.path.basename(fpath)
    test = re.search(r'(lowQ|typQ|highQ|tttt|pcff|pcss)',os.path.basename(fpath),flags=re.I)
    skew = test.group(1) if test else ''
    outName = outName+'_'+skew
  return outDir,outName

def callWithFeeder(jobs,inputs):
  import subprocess
  cmd = 'jobFeed.py '+str(jobs)+' -batch -cmd simMomFiles.py -files '+(' '.join(inputs))
  subprocess.call(cmd,shell=True)
    
##############################################################################
# Argument Parsing
##############################################################################
import os, sys; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import shutil, re, subprocess, argparse, time, numtools
argparser = argparse.ArgumentParser(description='This program uses ADS HFSS to run simulation already created')
argparser.add_argument(dest='simDirs', nargs='+', help='Sim Dirs from Momentum created in (simulation/libName/<names*>/layout/<emSims*>)')
argparser.add_argument('-outdir', dest='outDir', help='This options lets you specify the output directory (default to adsWorkspace/data')
argparser.add_argument('-batch', dest='batch', nargs='?', const=1, type = int, help='Uses the batch to run jobs in parallel by value given, value defaults to 1 if nothing given')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
if args.batch: callWithFeeder(args.batch,args.simDirs); exit(0)
for ff in args.simDirs:
  ## Get the name and skew
  outDir,dataSet = getOutNames(ff)
  ## Set calibration to None POR
  setCalToNone(ff)
  ##  prepare the comand
  if args.outDir: outDir = args.outDir
  cmd = 'cd '+ff+'; adsMomWrapper -O -3D --dsName='+dataSet+' --dsDir='+outDir+' proj proj'
  ## run simulations  
  print(('Running ', ff, dataSet)); start = time.time()
  test = subprocess.call(cmd, shell=True); duration = ('%6s' % numtools.numToStr((time.time() - start)/60.0,2))+' minutes'
  print(('#FINISHED ('+duration+'),\t'+('SUCCESS' if test==0 else '   FAIL')+',\t'+dataSet))
exit(0)
