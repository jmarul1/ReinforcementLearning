#!/usr/bin/env python3.7.4
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
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> calculateRLSp.py -h 
##############################################################################

def plotData(xList,RList,LList,mode,plotParam):
  import pylab as pl
  mWindow = pl.figure(); mWindow.clf()
  axR = (mWindow).add_subplot(111); pl.hold(True);
  axL = axR.twinx() if plotParam == 'both' else axR 
  modelList = [mode] if mode else ['diff','se']; markerList = dict(se='-',diff='-') if mode else dict(se='-',diff='.')
  if plotParam in ['R','both']: ## plot all the Qs
    ymax = 0
    for qq in modelList:
      for cc in xList:
        axR.plot(xList[cc],RList[cc][qq],markerList[qq],label='R'+qq+'_'+cc)
        axR.set_ylabel('Resistance'); axR.set_xlabel('Frequency (GHz)');
        #figure.set_yscale('log');  
        if max(RList[cc][qq]) >= ymax: ymax = max(RList[cc][qq])
    axR.legend(loc='best')
    #axR.set_ylim(0,1.1*ymax);
  if plotParam in ['L','both']: ## plot the Ls
    ymax = 0
    for qq in modelList:
      for cc in xList:
        axL.plot(xList[cc],LList[cc][qq],markerList[qq],label='L'+qq+'_'+cc)
        axL.set_ylabel('Inductance (nH)');
        if max(LList[cc][qq]) >= ymax: ymax = max(LList[cc][qq])
    axL.legend(loc='best')
    axL.set_ylim(0,ymax);
  pl.hold(False)
  pl.show()
  pl.close(mWindow)



##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='Calculates the inductances and resistances of an sparameter file.')
argparser.add_argument(dest='spFiles', nargs='+', help='sparameter file(s)')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "spfile"_QL.csv')
argparser.add_argument('-plot', dest='plotme', action='store_true', help='displays a plot picture for the sparameter file')
argparser.add_argument('-mode', dest='mode', choices=['diff','se'], help='specify to limit calculation to only single ended or differential')
argparser.add_argument('-only', dest='only', choices=['R','L'], help='specify only which parameter to plot')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import sys, re, math
import sparameter as sp

FList = {}; RList = {}; LList = {}
## run for each sparameter specified 
for iiSpFile in args.spFiles:
## Get real path of the file and decide for how many ports
  if os.path.exists(iiSpFile) and re.search(r'\.s\d+p$',os.path.splitext(iiSpFile)[1],flags=re.I):
    spFile = os.path.realpath(iiSpFile); spFileName = os.path.splitext(os.path.basename(spFile))[0]
    sparam = sp.read(spFile)
  else: print('Sparameter file '+iiSpFile+' either does not exists or is not an sparameter file'); continue

## Get the differential and single ended and losses
  R=dict(diff=[],se=[]); L=dict(diff=[],se=[]); Q=dict(diff=[],se=[]);
  Q['diff'],L['diff'],Q['se'],L['se'],R['diff'],R['se'] = sparam.getQLR()  

## Store all the Values
  FList.update({spFileName:sparam.freq})
  LList.update({spFileName:L})
  RList.update({spFileName:R})

# decide what to print based on the inputs, diff or se or both
  if args.mode: #if single or diff specified
    mode = args.mode
    results = 'Freq (GHz),Rdiff,Ldiff(nH)\n' if args.mode == 'diff' else 'Freq(GHz),Rse,Lse(nH)\n'
    for ii in range(len(sparam.freq)):
      results += ','.join([str(sparam.freq[ii]),str(R[mode][ii]),str(L[mode][ii])]) + '\n'
  else:
    results = 'Freq(GHz),Rdiff,Ldiff(nH),Rse,Lse(nH),\n'
    for ii in range(len(sparam.freq)):
      results += ','.join([str(sparam.freq[ii]),str(R['diff'][ii]),str(L['diff'][ii]),str(R['se'][ii]),str(L['se'][ii])]) + '\n'

## if csv enable print values in csv file ## else print to the prompt
  if args.csvFile:
    with open(spFileName+'_RL.csv','w') as fout:
      fout.write(results)
  else: print(results)

## show the plot if requested
plotParam = args.only if args.only else 'both' 
if args.plotme: plotData(FList,RList,LList,args.mode,plotParam)

exit(0)
