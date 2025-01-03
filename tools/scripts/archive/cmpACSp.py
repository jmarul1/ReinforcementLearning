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
#   Type >> calculateQLSp.py -h 
##############################################################################

def plotData(xArray,plotArgs,mode):
  import plotUtils, pylab as pl
  [Figs,Layouts] = plotUtils.layoutPlt(len(plotArgs)); 
  markLst = ['-','o','*']
  for ii,pltLine in enumerate(plotArgs):
    iiAx = Layouts[ii]; iiAx.hold(True)
    for jj,iiKey in enumerate(pltLine.keys()): iiAx.plot(xArray,pltLine[iiKey][mode],markLst[jj],label=iiKey+mode,lw=3,fillstyle='none')
    iiAx.set_ylim(0,iiAx.get_ylim()[1]);      iiAx.legend(loc='best')
    iiAx.set_ylabel(plotUtils.getPltKeys(iiKey)[1]);
    iiAx.set_xlabel('Frequency(GHz)');   
    iiAx.hold(False)
  for iiFig in Figs: iiFig.tight_layout();
  pl.show()

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math
argparser = argparse.ArgumentParser(description='This program compares Spectre Sparam to Spectre AC analysis if scs file is given, or compares Spectre Sparam to Scs/Hsp AC analysis if hsp file is given')
argparser.add_argument(dest='cktFiles', nargs='+', help='subcircuit file')
argparser.add_argument('-mode', dest='mode', choices=['diff','se'], default='diff', help='analysis type, single ended or differential')
argparser.add_argument('-device', dest='device', choices=['ind','cap'], default='ind', help='device type, inductor or capacitor')
argparser.add_argument('-maxfreq', dest='maxFreq', nargs='+', default = ['50G'], help='Maximum frequency with units attached, default=65G. [You can also give "start stop" or "start step stop"; with units attached i.e. 10G 1G 50G]')
argparser.add_argument('-tempDir', dest='tempDir', default='/tmp', help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import sparameter as sp, ckt, numtools

## run for each file specified 
for iiCktFile in args.cktFiles:
  ## Get real path of the file and decide for how many ports
  if os.path.exists(iiCktFile) and re.search(r'\.(scs|sp|hsp|spf)$',os.path.splitext(iiCktFile)[1],flags=re.I):
    cktFile = os.path.realpath(iiCktFile); cktFileName = os.path.splitext(os.path.basename(cktFile)); cktType = os.path.splitext(cktFile)[1]
    cktParam = ckt.read(cktFile)
  else: print('Subcircuit file '+iiCktFile+' either does not exists or is not a spectre/hspice file'); continue
  ## Set freqs
  if len(args.maxFreq) == 1: mFreq = args.maxFreq[0]; fFreq = 0.01*numtools.getScaleNum(mFreq); sFreq = fFreq
  elif len(args.maxFreq) == 2: fFreq, mFreq = args.maxFreq; sFreq = 0.01*numtools.getScaleNum(mFreq)
  elif len(args.maxFreq) == 3: fFreq, sFreq, mFreq = args.maxFreq
  else: raise IOError('Wrong number of frequencies fool')
  ## Get the differential or single ended values
  Qscs=dict(diff=[],se=[]); Pscs=dict(diff=[],se=[]); Rscs=dict(diff=[],se=[])  # sparameter spectre sim
  QscsAc=dict(diff=[],se=[]); PscsAc=dict(diff=[],se=[]); RscsAc=dict(diff=[],se=[])  # AC spectre sim
  freqScs,Qscs['diff'],Pscs['diff'],Qscs['se'],Pscs['se'],Rscs['diff'],Rscs['se'] = cktParam.getQPR(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device=args.device,tmpTarget=args.tempDir)
  freqScsAc,QscsAc['diff'],PscsAc['diff'],RscsAc['diff'] = cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device=args.device,sim='scs',rEnd={'diff':1e9,'se':1e-6}.get(args.mode),tmpTarget=args.tempDir)
  if cktType in ['.hsp','.spf']: 
    QhspAc=dict(diff=[],se=[]); PhspAc=dict(diff=[],se=[]); RhspAc=dict(diff=[],se=[])  # AC spice sim
    freqHsp,QhspAc['diff'],PhspAc['diff'],RhspAc['diff'] = cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device=args.device,sim='hsp',rEnd={'diff':1e9,'se':1e-6}.get(args.mode),tmpTarget=args.tempDir)          
  else: freqHsp = freqScs  
  ## show the plot if requested
  if len(freqScs)*len(freqScsAc)/len(freqHsp) == len(freqScs): freq = freqScs
  else: raise IOError('Frequencies do not match')
  devL = {'ind':'L','cap':'C'}.get(args.device)
  plotArgs = [{'Qscs':Qscs,'Qscs_AC':QscsAc},{devL+'scs':Pscs,devL+'scs_AC':PscsAc}] if cktType not in ['.hsp','spf'] else [{'Qscs':Qscs,'Qscs_AC':QscsAc,'Qhsp_AC':QhspAc},{devL+'scs':Pscs,devL+'scs_AC':PscsAc,devL+'hsp_AC':PhspAc}]
  plotData(freq,plotArgs,args.mode)
exit(0)
