#!/usr/bin/env python2.7
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
#   Type >> calculateTCoilNetlist.py -h 
##############################################################################

def plotData(xArray,plotArgs):
  import plotUtils, pylab as pl
  [Figs,Layouts] = plotUtils.layoutPlt(len(plotArgs)); 
  for ii,iiKey in enumerate(plotArgs):
    iiAx = Layouts[ii]; iiAx.hold(True)
    iiAx.plot(xArray,plotArgs[iiKey],label=iiKey)
    iiAx.set_ylim(0,iiAx.get_ylim()[1]);      iiAx.legend(loc='best')
    iiAx.set_ylabel(plotUtils.getPltKeys(iiKey)[1]);
    iiAx.set_xlabel('Frequency(GHz)');   
    iiAx.hold(False)
  for iiFig in Figs: iiFig.tight_layout();
  pl.show()

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='This program calculates the inductances of a tcoil inductor subcircuit file.')
argparser.add_argument(dest='cktFiles', nargs='+', help='subcircuit file')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "spfile"_QL.csv')
argparser.add_argument('-plot', dest='plotme', help='displays a plot picture for the results')
argparser.add_argument('-maxfreq', dest='maxFreq', nargs='+', default = ['50G'], help='Maximum frequency with units attached, default=65G. [You can also give "start stop" or "start step stop"; with units attached i.e. 10G 1G 50G]')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import sys, re, math
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import ckt,numtools

## run for each file specified 
for iiCktFile in args.cktFiles:

  ## Get real path of the file and decide for how many ports
  if os.path.exists(iiCktFile) and re.search(r'\.(scs|sp)$',os.path.splitext(iiCktFile)[1],flags=re.I):
    cktFile = os.path.realpath(iiCktFile); cktFileName = os.path.splitext(os.path.basename(cktFile))[0]
    indckt = ckt.read(cktFile)
  else: print('Subcircuit file '+iiCktFile+' either does not exists or is not a spectre file'); continue

  ## Set freqs
  if len(args.maxFreq) == 1: mFreq = args.maxFreq[0]; fFreq = 0.01*numtools.getScaleNum(mFreq); sFreq = fFreq
  elif len(args.maxFreq) == 2: fFreq, mFreq = args.maxFreq; sFreq = 0.01*numtools.getScaleNum(mFreq)
  elif len(args.maxFreq) == 3: fFreq, sFreq, mFreq = args.maxFreq
  else: raise IOError('Wrong number of frequencies fool')

  ## Get the differential, center tap components and losses
  freq,Ldiff,L1ToCt,R1ToCt,L2ToCt,R2ToCt,kL1L2,C11,C22,C33 = indckt.getTCoilFns(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq)
  
  ## Compile the results in a string
  results = 'Freq(GHz),Ldiff(nH),L1ToCt(nH),L2ToCt(nH),R1ToCt(Ohms),R2ToCt(Ohms),kL1L2,C11(fF),C22(fF),C33(fF)\n'
  for ii in range(len(freq)):
    results += ','.join([str(freq[ii]),str(Ldiff[ii]),str(L1ToCt[ii]),str(L2ToCt[ii]),str(R1ToCt[ii]),str(R2ToCt[ii]),str(kL1L2[ii]),str(C11[ii]),str(C22[ii]),str(C33[ii])])
    results += '\n'

  ## if csv enable print values in csv file ## else print to the prompt
  if args.csvFile:
    with open(cktFileName+'_TCoil.csv','w') as fout:
      fout.write(results)
  else: print(results)

## show the plot if requested
  if type(args.plotme):
    plotArgs = {'L1':L1ToCt,'L2':L2ToCt,'R1':R1ToCt,'R2':R2ToCt,'k':kL1L2,'C1':C11,'C2':C22,'C3':C33}
    plotData(freq,plotArgs)
exit(0)
