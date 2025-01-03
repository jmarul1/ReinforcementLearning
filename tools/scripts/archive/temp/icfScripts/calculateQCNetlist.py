#!/usr/bin/env python2.7
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
#   Type >> calculateQLNetlist.py -h 
##############################################################################

def plotData(xArray,plotArgs,mode):
  import plotUtils, pylab as pl
  modelList = [mode] if mode else ['diff','se']; 
  markerList = dict(se='-b',diff='-k')  
  [Figs,Layouts] = plotUtils.layoutPlt(len(plotArgs)); 
  for ii,iiKey in enumerate(plotArgs):
    iiAx = Layouts[ii]; iiAx.hold(True)
    if iiKey in ['C','Q','R']: 
      for qq in modelList:
        iiAx.plot(xArray,plotArgs[iiKey][qq],markerList[qq],label=iiKey+qq)
      iiAx.set_ylim(0,iiAx.get_ylim()[1]);      iiAx.legend(loc='best')
    else: 
      iiAx.plot(xArray,plotArgs[iiKey])      
    iiAx.set_ylabel(plotUtils.getPltKeys(iiKey)[1]);
    iiAx.set_xlabel('Frequency(GHz)');   
    iiAx.hold(False)
  for iiFig in Figs: iiFig.tight_layout();
  pl.show()

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math 
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
argparser = argparse.ArgumentParser(description='This program calculates the capacitance of a capacitor subcircuit file.')
argparser.add_argument(dest='cktFiles', nargs='+', help='subcircuit file')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "spfile"_QL.csv')
argparser.add_argument('-plot', dest='plotme', nargs='*', choices=['Q','C','R','all'], help='displays a plot picture for the sparameter.')
argparser.add_argument('-mode', dest='mode', choices=['diff','se'], help='specify to limit calculation to only single ended or differential')
argparser.add_argument('-maxfreq', dest='maxFreq', nargs='+', default = ['50G'], help='Maximum frequency with units attached, default=65G. [You can also give "start stop" or "start step stop"; with units attached i.e. 10G 1G 50G]')
argparser.add_argument('-sim', dest='sim',default='scs',choices=['scs','hsp'], help=argparse.SUPPRESS)
argparser.add_argument('-ac', dest='AC',action='store_true', help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import sparameter as sp, ckt, numtools

## run for each file specified 
for iiCktFile in args.cktFiles:
  ## Get real path of the file and decide for how many ports
  if os.path.exists(iiCktFile) and re.search(r'\.(scs|sp|hsp|spf)$',os.path.splitext(iiCktFile)[1],flags=re.I):
    cktFile = os.path.realpath(iiCktFile); cktFileName = os.path.splitext(os.path.basename(cktFile))[0]
    cktParam = ckt.read(cktFile)
  else: print('Subcircuit file '+iiCktFile+' either does not exists or is not a spectre/hspice file'); continue

  ## Set freqs
  if len(args.maxFreq) == 1: mFreq = args.maxFreq[0]; fFreq = 0.01*numtools.getScaleNum(mFreq); sFreq = fFreq
  elif len(args.maxFreq) == 2: fFreq, mFreq = args.maxFreq; sFreq = 0.01*numtools.getScaleNum(mFreq)
  elif len(args.maxFreq) == 3: fFreq, sFreq, mFreq = args.maxFreq
  else: raise IOError('Wrong number of frequencies fool')

  ## Get the differential and single ended and losses
  Q=dict(diff=[],se=[]); C=dict(diff=[],se=[]); R=dict(diff=[],se=[])
  if args.sim == 'scs':  #spectre
    if args.AC: #AC analysis
      freq,Q['diff'],C['diff'],R['diff'] = cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='cap',sim='scs',rEnd=1e9)
      freq,Q['se'],C['se'],R['se'] = cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='cap',sim='scs',rEnd=1e-6)
    else: #Sparameter analysis
      freq,Q['diff'],C['diff'],Q['se'],C['se'],R['diff'],R['se'] = cktParam.getQPR(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='cap')#,tmpTarget='.')
  else: #Hspice
    freq,Q['diff'],C['diff'],R['diff'] = cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='cap',sim='hsp',rEnd=1e9)
    freq,Q['se'],C['se'],R['se'] = cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='cap',sim='hsp',rEnd=1e-6)

  ## decide what to print based on the inputs, diff or se or both
  if args.mode: #if single or diff specified
    results = 'Freq(GHz),Qdiff,Cdiff(fF),Rdiff(Ohms)\n' if args.mode == 'diff' else 'Freq(GHz),Qse,Cse(fF),Rse(Ohms)\n'
    for ii in range(len(freq)):
      results += ','.join([str(freq[ii]),str(Q[args.mode][ii]),str(C[args.mode][ii]),str(R[args.mode][ii])]) + '\n'
  else:
    results = 'Freq(GHz),Qdiff,Cdiff(fF),Qse,Cse(fF),Rdiff(Ohms),Rse(Ohms)\n'
    for ii in range(len(freq)):
      results += ','.join([str(freq[ii]),str(Q['diff'][ii]),str(C['diff'][ii]),str(Q['se'][ii]),str(C['se'][ii]),str(R['diff'][ii]),str(R['se'][ii])]) + '\n'

  ## if csv enable print values in csv file ## else print to the prompt
  if args.csvFile:
    with open(cktFileName+'_QC.csv','w') as fout:
      fout.write(results)
  else: print(results)

  ## show the plot if requested
  if type(args.plotme) == list:
    getPlotArg = lambda ff: {'Q':Q,'C':C,'R':R}.get(ff)
    if any(args.plotme):
      if args.plotme[0] == 'all': plotArgs = {'Q':Q,'C':C,'R':R} #if all is asked for
      else:
        plotArgs = {}
        for ii in set(args.plotme): plotArgs.update({ii:getPlotArg(ii)}) 
    else: plotArgs = {'Q':Q,'C':C}
    plotData(freq,plotArgs,args.mode)
exit(0)
