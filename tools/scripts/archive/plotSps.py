#!/usr/intel/bin/python2.7
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
#
# Author:
#   Mauricio Marulanda
#
# Description:
#   Type >> plotSps.py -h
#
##############################################################################
def plotData(Layouts,xArray,plotArgs,mode,name):  
  for ii,iiKey in enumerate(plotArgs):
    iiAx = Layouts[ii]; iiAx.hold(True)
    if iiKey in ['L','C','Q','R']: 
      iiAx.plot(xArray,plotArgs[iiKey][mode],label=name)
      iiAx.set_ylim(0,iiAx.get_ylim()[1]); 
      if args.legend: iiAx.legend(loc='best')
    else: 
      iiAx.plot(xArray,plotArgs[iiKey],label=name);
      if args.legend: iiAx.legend(loc='best')      
    iiAx.set_ylabel(plotUtils.getPltKeys(iiKey)[1]);
    iiAx.set_xlabel('Frequency(GHz)');   
    iiAx.hold(False)

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math
argparser = argparse.ArgumentParser(description='Calculates the device inductance or capacitance with quality factors of an sparameter file.')
argparser.add_argument(dest='spFiles', nargs='+', help='sparameter file(s)')
argparser.add_argument('-device', dest='device', choices=['ind','cap'], default='ind', help='specify whether to plot capacitance or inductance')
argparser.add_argument('-plot', dest='plotme', nargs='+', choices=['Q','L','R','C','all'], default=[], help='specify what to plot other than Q and the Passive')
argparser.add_argument('-mode', dest='mode', choices=['diff','se'], default='diff', help='specify to limit calculation to only single ended or differential')
argparser.add_argument('-nl',dest='legend',action='store_false',help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import sparameter as sp, pylab as pl, plotUtils
## run for each sparameter specified 
Figs = False; device = {'ind':'L','cap':'C'}.get(args.device);
for iiSpFile in args.spFiles:
## Get real path of the file and decide for how many ports
  if os.path.exists(iiSpFile) and re.search(r'\.s\d+p$',os.path.splitext(iiSpFile)[1],flags=re.I):
    spFile = os.path.realpath(iiSpFile); spFileName = os.path.splitext(os.path.basename(spFile))[0]
    sparam = sp.read(spFile)
  else: print('Sparameter file '+iiSpFile+' either does not exists or is not an sparameter file'); continue
## Get the differential and single ended and losses
  Q=dict(diff=[],se=[]); Passive=dict(diff=[],se=[]); R=dict(diff=[],se=[])
  if args.device == 'ind':
    Q['diff'],Passive['diff'],Q['se'],Passive['se'],R['diff'],R['se'] = sparam.getQLR()
    losses = sparam.getTransferFns() if sparam.portNum != 1 else None #exclude 1 port sparameter
  else:
    Q['diff'],Passive['diff'],Q['se'],Passive['se'],R['diff'],R['se'] = sparam.getQCR()
    losses = None
## prepare data to plot
  getPlotArg = lambda ff: {'Q':Q,device:Passive,'R':R,'losses':losses}.get(ff)
  if any(args.plotme):
    if args.plotme[0] == 'all': plotArgs = {'Q':Q,device:Passive,'R':R,'losses':losses} #if all is asked for
    else:
      plotArgs = {}
      for ii in set(args.plotme): plotArgs.update({ii:getPlotArg(ii)}) 
  else: plotArgs = {'Q':Q,device:Passive}
  if 'losses' in plotArgs.keys(): [plotArgs.update({ii[0]:ii[1]}) for ii in plotArgs['losses'].items()]; del plotArgs['losses']
  if not Figs: [Figs,Layouts] = plotUtils.layoutPlt(len(plotArgs),grH=5,grW=5); 
  plotData(Layouts,sparam.freq,plotArgs,args.mode,spFileName)
  for iiFig in Figs: iiFig.tight_layout(); iiFig.suptitle(args.mode,y=0.5,fontsize=80,color='gray',alpha=0.1,rotation=45,va='center',ha='center')
pl.show()
