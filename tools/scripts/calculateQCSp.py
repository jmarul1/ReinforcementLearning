#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> calculateQCSp.py -h 
##############################################################################

def plotData(xArray,plotArgs,mode,figName):
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
  for iiFig in Figs: iiFig.tight_layout();iiFig.canvas.set_window_title(figName)
  pl.show()

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='This program calculates the capacitances and quality factors of a capacitor sparameter file.')
argparser.add_argument(dest='spFiles', nargs='+', help='sparameter file(s)')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "spfile"_QL.csv')
argparser.add_argument('-plot', dest='plotme', nargs='*', choices=['Q','C','R','all'], help='displays a plot picture for the sparameter.')
argparser.add_argument('-mode', dest='mode', choices=['diff','se','mim'], help='specify to limit calculation to only single ended or differential')
argparser.add_argument('-freq',dest='freq',help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import sys, re, math
import sparameter as sp, numtools

## if a freq specified
if args.freq != None: args.freq = numtools.getScaleNum(args.freq)/1e9 #make it GHz

## run for each sparameter specified 
for iiSpFile in args.spFiles:
## Get real path of the file and decide for how many ports
  if os.path.exists(iiSpFile) and re.search(r'\.(s\d+p|c.?ti)$',os.path.splitext(iiSpFile)[1],flags=re.I):
    spFile = os.path.realpath(iiSpFile); spFileName = os.path.splitext(os.path.basename(spFile))[0]
    sparam = sp.read(spFile)
  else: print('Sparameter file '+iiSpFile+' either does not exists or is not an sparameter file'); continue

## Get the differential and single ended and losses
  if args.mode and args.mode == 'mim': params = sparam.getMimFns()
  Q=dict(diff=[],se=[]); C=dict(diff=[],se=[]); R=dict(diff=[],se=[])
  Q['diff'],C['diff'],Q['se'],C['se'],R['diff'],R['se'] = sparam.getQCR(freq=args.freq)

## Varactor case, change the freq
  if args.freq: sparam.freq = [ff*1e9 for ff in sparam.freq]

# decide what to print based on the inputs, diff or se or both
  if args.mode: #if single or diff or mim specified
    mode = args.mode
    if mode in ['diff','se']:
      results = 'Freq (GHz),Qdiff,Cdiff(fF),Rdiff(Ohms)\n' if args.mode == 'diff' else 'Freq(GHz),Qse,Cse(fF),Rse(Ohms)\n'
      for ii in range(len(sparam.freq)): results += ','.join([str(sparam.freq[ii]),str(Q[mode][ii]),str(C[mode][ii]),str(R[mode][ii])]) + '\n'
    else:
      results = 'Freq(GHz),Qdiff,Cdiff(fF),Rdiff(Ohms),C11(fF),C22(fF),C12(fF),C21(fF),R11(Ohms),R22(Ohms),R12(Ohms),R21(Ohms),Q11,Q22,Q12,Q21,Y11r,Y11i,Y22r,Y22i,Y12r,Y12i,Y21r,Y21i\n'
      for ii in range(len(sparam.freq)):
        results += str(sparam.freq[ii])+','+str(Q['diff'][ii])+','+str(C['diff'][ii])+','+str(R['diff'][ii])+','
        results += (','.join(str(params[kk][ii]) for kk in list(params.keys())))+'\n'
  else:
    results = 'Freq(GHz),Qdiff,Cdiff(fF),Qse,Cse(fF),Rdiff(Ohms),Rse(Ohms)\n'
    for ii in range(len(sparam.freq)):
      results += ','.join([str(sparam.freq[ii]),str(Q['diff'][ii]),str(C['diff'][ii]),str(Q['se'][ii]),str(C['se'][ii]),str(R['diff'][ii]),str(R['se'][ii])]) + '\n'

## if csv enable print values in csv file ## else print to the prompt
  if args.csvFile:
    with open(spFileName+'_QC.csv','w') as fout:
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
    plotData(sparam.freq,plotArgs,args.mode,spFileName)
exit(0)
