#!/usr/intel/bin/python2.7
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
#   Type >> cmpCsvPlots.py -h 
#
##############################################################################

def numberp(string):
  try: float(string); return True
  except ValueError: return False

  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='This program run spice to vary inductance in an MFC.')
argparser.add_argument(dest='csv', nargs='+', help='CSV files')
argparser.add_argument('-device', dest='device', choices=['ind','cap'], default='ind', help='specify whether to plot capacitance or inductance')
argparser.add_argument('-mode', dest='mode', choices=['diff','se'], help='specify to limit calculation to only single ended or differential')
args = argparser.parse_args()
##############################################################################

##############################################################################
# Main Begins
##############################################################################
import sys, re, tempfile, subprocess, math, csv
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import pylab as pl
import sparameter as sp

QList = {}; RList = {}; FList = {}
for iiCsvFile in args.csv:

## Get real path of the file and decide for how many ports
  if os.path.exists(iiCsvFile) and re.search(r'\.csv$',os.path.splitext(iiCsvFile)[1],flags=re.I):
    csvFileName = os.path.splitext(os.path.basename(iiCsvFile))[0]
  else: print('Csv file '+iiCsvFile+' either does not exists or is not a csv file'); continue

## Get the differential and single ended results from the labData
  with open(iiCsvFile) as csvFile:
    csvData = csv.reader(csvFile)
    Q_csv=dict(diff=[],se=[]); passive_csv=dict(diff=[],se=[]); freq_csv=[]
    for row in csvData:
      if not numberp(row[0]): continue
      freq_csv.append(row[0])
      Q_csv['diff'].append(float(row[1])); Q_csv['se'].append(float(row[3]))
      passive_csv['diff'].append(float(row[2])); passive_csv['se'].append(float(row[4]))   
  FList.update({csvFileName:freq_csv})
  QList.update({csvFileName:Q_csv})
  RList.update({csvFileName:passive_csv})

lista = QList.keys(); cnt=0
## decide what to print based on the inputs, diff or se or both
if args.mode: #if single or diff specified
  mode = args.mode
  figureQ = (pl.figure()).add_subplot(111,title=mode); pl.hold(True)
  figureR = (pl.figure()).add_subplot(111,title=mode); pl.hold(True)
  for ii in lista: 
    figureQ.plot(FList[ii],QList[ii][mode],label=ii)        
    figureR.plot(FList[ii],RList[ii][mode],label=ii)
    figureR.text(FList[ii][cnt],RList[ii][mode][cnt],ii,withdash=True,fontsize=9); cnt=cnt+0
else:
  mode = 'Both diff and se'
  figureQ = (pl.figure()).add_subplot(111,title=mode); pl.hold(True)
  figureR = (pl.figure()).add_subplot(111,title=mode); pl.hold(True)
  for ii in lista: 
    for mode in ['se','diff']:
      figureQ.plot(FList[ii],QList[ii][mode],label=mode+'_'+ii)        
      figureR.plot(FList[ii],RList[ii][mode],label=mode+'_'+ii)

## set the graph and plot
for iiGraph in [figureQ,figureR]:
  iiGraph.set_xlabel('Frequency (GHz)'); iiGraph.legend(loc='best'); iiGraph.grid(True,which='both')
figureQ.set_ylabel('Quality Factor'); 
if args.device == 'ind': figureR.set_ylabel('Inductance (nH)');
else: figureR.set_ylabel('Capacitance (fF)') 
figureQ.set_ylim(0,15);#figureQ.set_ylim(0,figureQ.get_ylim()[1]);
figureR.set_ylim(0,figureR.get_ylim()[1])
pl.show()
exit(0)
