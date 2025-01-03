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
#   Type >> cmpSp.py -h 
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='This program compares the sparameter file versus the model ckt fit.')
argparser.add_argument(dest='spFile', help='sparameter reference file <spfilename_skew.snp> to be compared with <spfilename_skew>.scs')
argparser.add_argument('-cktfile', dest='cktFile', help='if given, this file is used for ckt comparison, otherwise it is searched in the current directory')
argparser.add_argument('-mode', dest='mode', choices=['diff','se'], default='diff', help='specify single ended or differential comparison; default = differential')
argparser.add_argument('-plot', dest='plot', choices=['Q','L','R'], default=['Q','L','R'], help='Choose the parameter to compare')
argparser.add_argument('-all', dest='cmpAll', action='store_true', help='if given, all three skews are compared using spfile_skew.snp vs spfilename_skew.scs')
argparser.add_argument('-fullfreq', dest='fullFreq', action='store_true', help='if given all points in the sparam freq range are shown in the plot')
argparser.add_argument('-cktext', dest='cktext',default='.scs',choices=['.scs','.hsp'], help=argparse.SUPPRESS)
argparser.add_argument('-sim', dest='sim',default='scs',choices=['scs','hsp'], help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import os, re, sys
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import pylab, ckt, sparameter as sp, plotUtils

## get the file information
spFile = os.path.relpath(args.spFile)
#fileName,fileExt = os.path.splitext(os.path.basename(spFile))
fileName,fileExt = os.path.splitext(spFile)
fileBase = re.sub('(_pcss|_tttt|_pcff)$','',fileName,flags=re.I)

## if requested graph everything otherwise choose the skew
if args.cmpAll: skewList = ['pcss','tttt','pcff']
else: 
  test = re.search('(pcss|tttt|pcff)$',fileName,flags=re.I)
  if test: skewList = [test.group(1)]
  else: raise IOError('Wrong format for the name of the file: '+args.spFile)

## graph colors
pColor = dict(pcss='r',tttt='k',pcff='b')
[Figs,Layouts] = plotUtils.layoutPlt(len(args.plot))

## plot the skew comparison  
maxFreq=-1
for iiSkew in skewList:  
  iiCktFile = args.cktFile if args.cktFile else (os.path.basename(fileBase)+'_'+iiSkew+args.cktext)
  if not(os.path.isfile(fileBase+'_'+iiSkew+fileExt) and os.path.isfile(iiCktFile)): print 'Skipped: '+iiCktFile+' or '+fileBase+'_'+iiSkew+fileExt; continue
  sparam = sp.read(fileBase+'_'+iiSkew+fileExt);  
  cktParam = ckt.read(iiCktFile)
  ## Set freqs and get values
  mFreq = sparam.freq[-1]; fFreq = sparam.freq[0]; sFreq = (mFreq-fFreq)/(len(sparam.freq)-1)
  fFreq,sFreq,mFreq = map(lambda ff: str(ff)+'G',[fFreq,sFreq,mFreq])
  if args.sim == 'hsp':
    tempVals = cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='ind',sim='hsp',rEnd=1e9)+cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='ind',sim='hsp',rEnd=1e-6)
    cktFull = (tempVals[0],tempVals[1],tempVals[2],tempVals[5],tempVals[6],tempVals[3],tempVals[7])
  else: cktFull = cktParam.getQPR(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='ind') 
  spFull = sparam.getQLR()    ; 
  # select the mode to plot
  if args.mode == 'se': spPlotData = [spFull[2],spFull[3],spFull[5]]; cktPlotData = [cktFull[0],cktFull[3],cktFull[4],cktFull[6]]
  else: spPlotData = [spFull[0],spFull[1],spFull[4]]; cktPlotData = [cktFull[0],cktFull[1],cktFull[2],cktFull[5]]
  # plot the values
  for iiP,var in enumerate(args.plot):
    Layouts[iiP].hold(True);
    Layouts[iiP].plot(sparam.freq,spPlotData[iiP],'o'+pColor[iiSkew],fillstyle='none',label=iiSkew+'EMsim')
    Layouts[iiP].plot(cktPlotData[0],cktPlotData[iiP+1],pColor[iiSkew],lw=2,label=iiSkew+'model')
    Layouts[iiP].set_ylabel(plotUtils.getPltKeys(var)[1]);
    Layouts[iiP].set_xlabel('Frequency(GHz)');   Layouts[iiP].legend(loc='best')
  ## find the maxFreq
  srf = sparam.getSRF()[args.mode]
  maxFreq = max(maxFreq,srf if srf else sparam.freq[-1]) 

##graph limits
for cc,iiAx in enumerate(Layouts):
  iiAx.set_ylim(0,iiAx.get_ylim()[1])
  if not args.fullFreq: iiAx.set_xlim(0,maxFreq*1.05)
##figure labels
for iiFig in Figs: 
  iiFig.tight_layout(); iiFig.suptitle(args.mode,y=0.5,fontsize=80,color='gray',alpha=0.3,rotation=45,va='center',ha='center')
  iiFig.canvas.set_window_title(fileBase)
pylab.show()
exit(0)
