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
#   Type >> plotQL.py -h
#
##############################################################################
import sys, os, re
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import pylab, csv

##############################################################################
# Argument Parsing
##############################################################################
import argparse
argparser = argparse.ArgumentParser(description='This program plots Q and L for all combinations in the given outputList.csv')
argparser.add_argument(dest='inputFile', help='The outputList.csv file produced by simSpList.m file from matlab')
args = argparser.parse_args()
##############################################################################

##############################################################################
# Main Begins
##############################################################################

## Open the file
try:
  fidIn = open(args.inputFile, 'r')
except IOError:
  print('## error: The inputFile \"%s\" does not exist\n' % args.inputFile)
  exit(1)

## Read the file for each simulation
## first find the columns with the sequence Freq,Qdiff,Ldiff,etc
foundCol = False
for row in fidIn:
  fCol = 0;
  for col in row.split(','):
    if re.search(r'^\s*f|freq|frequency',col,flags=re.I):
      foundCol = True; break
    fCol+=1
  if foundCol: break
## get the first freq value and store all the values in an array of values in spData
spData=[]; rowList = (fidIn.next()).split(',')
freq=[rowList[fCol]]; qdiff=[rowList[fCol]]; qse=[rowList[fCol]]; ldiff=[rowList[fCol]]; lse=[rowList[fCol]]
for row in fidIn:
  rowList = row.split(',')
  if rowList[fCol] != freq[0]:
    freq.append(rowList[fCol]); qdiff.append(rowList[fCol+1]); ldiff.append(rowList[fCol+2])
    qse.append(rowList[fCol+3]); lse.append(rowList[fCol+4]); name = rowList[0] if fCol== 0 else rowList[fCol-1]
  else:
    labelStr = rowList[0] if fCol != 0 else 'Entry_'
    spData.append(dict(freq=freq,qdiff=qdiff,ldiff=ldiff,qse=qse,lse=lse,name=name)); freq=[];qdiff=[];qse=[];lse=[]
    freq=[rowList[fCol]]; qdiff=[rowList[fCol]]; qse=[rowList[fCol]]; ldiff=[rowList[fCol]]; lse=[rowList[fCol]]
labelStr = rowList[0] if fCol != 0 else 'Entry_'
spData.append(dict(freq=freq,qdiff=qdiff,ldiff=ldiff,qse=qse,lse=lse,name=name)) # get the last data    

## plot the values
index=1; qYMax=[]; lYMax=[]; xMax = [];
figure = pylab.figure(); pylab.hold(True);
qplot = figure.add_subplot(111); lplot = qplot.twinx()
for iiSim in spData:
  freq = iiSim['freq']; name = str(index); name = iiSim['name']
  qdiff = iiSim['qdiff']; qse = iiSim['qse']; ldiff = iiSim['ldiff']; lse = iiSim['lse']
# Check the range given
#  if float(lse[25]) > 0.22 or float(lse[25]) < 0.18: continue
# plot the quality factors  
  qplot.plot(freq,qdiff,label='Qdiff_'+name); #qplot.plot(freq,qse,label='Qse_'+str(index));
  qplot.set_xlabel(r'Frequency (GHz)'); qplot.set_ylabel(r'Quality Factor'); qplot.legend(loc='best')
  qYMax.append(max(map(float,iiSim['qdiff']))); # get the maximum of quality factor axis

# plot the inductances on a different axis
  lplot.plot(freq,ldiff,label='Ldiff_'+name); #lplot.plot(freq,lse,label='Lse_'+str(index));
  lplot.set_xlabel(r'Frequency (GHz)'); lplot.set_ylabel(r'Inductance (nH)'); #lplot.legend(loc='best')
  lYMax.append(max(map(float,iiSim['ldiff']))); # get the maximum of inductances axis

# set general parameters
  index+=1; # for label
  xMax.append(max(map(float,iiSim['freq']))) # get the maximum of all the x-axis

## set axis
#qplot.set_xlim(0,max(xMax))
qplot.set_xlim(0,max(xMax)*1.01)
lplot.set_ylim(0,max(lYMax)*1.1); qplot.set_ylim(0,max(qYMax)*1.1)
pylab.show()
exit(0)
