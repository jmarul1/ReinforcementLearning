#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2014, Intel Corporation.  All rights reserved.               #
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
# Description:
#   Type >> getDcMed.py -h 
##############################################################################

def getAllColMedian(keyedLst,mFreq):
  index = 0; 
  for ii in keyedLst['Freq(GHz)']:
    if ii <= mFreq: index+=1
    else: break
  if index==0: index+=1
  newLst = {}; 
  for ii in keyedLst:
    newLst[ii] = nu.median(keyedLst[ii][:index])
  del newLst['Freq(GHz)']; newLst['numPoints']=index
  return newLst

def getMaxFreq(fileOrNum):
  if os.path.isfile(fileOrNum):
    return csvUtils.dFrame(fileOrNum,text=True)
  else: fileOrNum = getScaleNum(fileOrNum)
  if isNumber(fileOrNum): return float(fileOrNum)
  else: raise argparse.ArgumentTypeError('Speficy a file or a number(metric units supported): '+fileOrNum)

def getDevMaxFreq(maxf,device):
  if type(maxf) != dict: maxFreq = maxf/1e9
  elif 'devices' in maxf.keys(): maxFreq = getScaleNum(maxf['topFreq'][maxf['devices'].index(device)])/1e9
  else: maxFreq = -1
  return maxFreq

def getDevLoc(strIn):
  devLetts = '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]'; 
  test1 = re.search(r'.*?_('+devLetts+')_(?P<device>\w+(_'+devLetts+'_)?)(mmDe|DE)',strIn)    #takes care of location with de-emb
  test2 = re.search(r'.*?_('+devLetts+')_(?P<device>\w+(_'+devLetts+'_)?)(QC|QL|RC|RL)',strIn)    #takes care of location with raw
  if test1: location = test1.group(1).strip('_'); device = test1.group('device').strip('_')
  elif test2: location = test2.group(1).strip('_'); device = test2.group('device').strip('_')
  else: location = 'N/A'; device = devInDies[0]
  return location,device

## Import arguments
import sys, os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import argparse, re, plotUtils, csvUtils, numpy as nu; from numtools import getScaleNum, isNumber; import pylab as plt; import matplotlib, itertools
devLetts = '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]';
inChoices = ['Qd','Ld','Qse','Lse','Cd','Cse','Rd','Rse','C11','C22']
## Argument Parsing
argparser = argparse.ArgumentParser(description='Get the average value up to the given freq (freqs must be in GHz)')
argparser.add_argument(dest='input', nargs='+', type=csvUtils.targetFiles, help='Files to average')
argparser.add_argument('-device', dest='device', default='X-?\d+Y-?\d+.*?'+devLetts, help='Device or Regex to use for grouping')
argparser.add_argument('-param', dest='param', choices = inChoices, help='Parameter to get Cd, Device or Regex to use for grouping')
argparser.add_argument('-maxfreq', dest='maxF', type=getMaxFreq, default=-1, help='Csv file with max freqs or actual max freq (metric units supported)')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: median_<device>.csv')
args = argparser.parse_args()
if args.param: args.param =  plotUtils.getPltKeys(args.param)[0]
################ MAIN ###############

## Group the files as 2 dim array following prefix pattern
lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();
if not any(lstFiles): raise argparse.ArgumentTypeError('File(s) or Dir(s) given aren\'t or don\'t contain ANY csv files')
topList=plotUtils.group(lstFiles,prefix='.*'+args.device); rowMax = len(topList)

## Run for each group based on the prefix pattern
duts = {}
for fList in topList:
  ## Group the devices based on the die/position if device was specified if not nothing happens
  sList = plotUtils.group(fList,prefix='.*X-?\d+Y-?\d+');
  for devInDies in sList: # At this point the only difference are the dies
    location,device = getDevLoc(devInDies[0])
    if device not in duts.keys(): duts[device]={}
    duts[device][location]={}    
    mFreq = getDevMaxFreq(args.maxF,device);
    for cDie in devInDies:
      test = re.search(r'(X-?\d+Y-?\d+)(.*)',cDie)
      die = test.group(1) if test else cDie
      duts[device][location][die] = getAllColMedian(csvUtils.dFrame(cDie),mFreq)

## prepare data and print
if args.param and args.param not in duts[device][location][die].keys(): raise LookupError('Parameter does not exist in data: '+args.param)
spaces = ''.join([',' for ii in xrange(len(duts[device][location][die].keys())+1)])
if args.param: results = 'Median Values:,,'+','.join([args.param for ii in duts[device].keys()])+'\n'; spaces=','
else: results = 'Median Values:,,'+',,'.join([','.join(sorted(duts[device][location][die].keys())) for ii in duts[device].keys()])+'\n'
results += 'Device,Die,'+spaces.join(map(lambda ff: 'Loc '+ff, (ii for ii in sorted(duts[device].keys()))))+'\n'
for iiDev in sorted(duts.keys()):
  for iiDie in sorted(duts[iiDev][location].keys()):
    results += iiDev+','+iiDie
    for iiLoc in sorted(duts[iiDev].keys()):
      if args.param: results += ','+str(duts[iiDev][iiLoc][iiDie][args.param])
      else: results += ','+','.join([str(duts[iiDev][iiLoc][iiDie][key]) for key in sorted(duts[iiDev][iiLoc][iiDie].keys())])+','
    results = results.rstrip(',')+'\n' 

## if csv enable print values in csv file ## else print to the prompt
if args.csvFile:
  outFileName = 'median_'+args.device+'.csv' if args.device != 'X-?\d+Y-?\d+.*?'+devLetts else 'devicesMedian.csv'
  with open(outFileName,'w') as fout:
    fout.write(results)
else: print(results)
