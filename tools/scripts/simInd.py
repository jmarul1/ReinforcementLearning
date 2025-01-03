#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> simVar.py -h 
##############################################################################

def plotData(xArray,plotArgs,skew,Layouts=False,Figs=False,count=0):
  import plotUtils, numtools, pylab as pl, argparse
  if not Layouts: [Figs,Layouts] = plotUtils.layoutPlt(len(plotArgs)); 
  markerList = dict(tttt='-k',pcff='-g',pcss='-m',prcf='-b',prcs='-r',ffff='-b',ssss='-r')  
  for ii,iiKey in enumerate(plotArgs):
    iiAx = Layouts[ii]; iiAx.hold(True)
    if iiKey in ['Q','L','R']: 
      iiAx.plot(xArray,plotArgs[iiKey],markerList[skew],label=iiKey+'d_'+skew)
      iiAx.legend(loc='best'); #iiAx.set_ylim(0,iiAx.get_ylim()[1]); 
    else: 
      iiAx.plot(xArray,plotArgs[iiKey])      
    iiAx.set_ylabel(plotUtils.getPltKeys(iiKey)[1]);
    iiAx.set_xlabel('Frequency(GHz)'); iiAx.set_ylim(0,iiAx.get_ylim()[1]); iiAx.legend(loc='best')
    iiAx.hold(False)
#  for iiFig in Figs: iiFig.tight_layout(); iiFig.suptitle('Diff',y=0.5,fontsize=80,color='gray',alpha=0.3,rotation=45,va='center',ha='center')
  return count

def getSimType(ffile):
  import os
  if os.path.splitext(ffile)[1] == '.scs': return 'scs'
  else: return 'hsp'
  
def mainExe():
  ##############################################################################
  # Argument Parsing
  ##############################################################################
  import argparse, os, sys, re, math 
  import ckts, numtools, plotUtils, pylab as pl
  argparser = argparse.ArgumentParser(description='Calculates Q/L')
  argparser.add_argument(dest='name', nargs='+', help='inductor name')
  argparser.add_argument('-upf', dest='include', type=os.path.realpath, help='UPF or SCS file')
  argparser.add_argument('-skew', dest='skew', nargs = '+', choices = ['tttt_template', 'tttt_int', 'tttt','prcs','prcf','pcff','pcss','rfff','rsss','ssss','ffff','ssvff','ffvss'], default=['tttt'], help='Skew')
  argparser.add_argument('-temp', dest='temp', choices = ['-40','25','125'], default='25', help='Temperature')
  argparser.add_argument('-mode', dest='mode', choices = ['diff','se'], default='diff', help='Differential or SingleEnded')  
  argparser.add_argument('-maxfreq', dest='maxFreq', nargs='+', default = ['50G'], help='Maximum frequency with units attached, default=65G. [You can also give "start stop" or "start step stop"; with units attached i.e. 10G 1G 50G]')
  argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "name"_QL.csv')
  argparser.add_argument('-plot', dest='plotme', nargs='*', type=str, choices=['Q','L','R','all'], help='Plot')
  args = argparser.parse_args()
  ##############################################################################
  # Main Begins
  ##############################################################################
  
  ## decide the simulator
  simExt = getSimType(args.include)

  ## Set freqs
  if len(args.maxFreq) == 1: mFreq = args.maxFreq[0]; fFreq = 0.01*numtools.getScaleNum(mFreq); sFreq = fFreq
  elif len(args.maxFreq) == 2: fFreq, mFreq = args.maxFreq; sFreq = 0.01*numtools.getScaleNum(mFreq)
  elif len(args.maxFreq) == 3: fFreq, sFreq, mFreq = args.maxFreq
  else: raise IOError('Wrong number of frequencies fool')

  count=0
  ## run for each file specified 
  for inductor in args.name:
    Layouts = False
    for skew in args.skew:
      include = ckts.getIncludes(simExt,skew,args.include)
      ports = ckts.checkSub(inductor,include)
      if not ports: sys.stderr.write('Model does not exist: '+inductor+'\n'); continue
      ind = ckts.inductor(inductor,ports,simExt,args.temp,args.mode);
      F,Q,L,R = ind.simulate(include,skew,fFreq,sFreq,mFreq)
      results = 'Freq(GHz),Qdiff,Ldiff(nH),Rdiff(Ohms)\n' if args.mode == 'diff' else 'Freq(GHz),Qse,Lse(nH),Rse(Ohms)\n'
      for f,q,l,r in zip(F,Q,L,R):
        f = numtools.numToStr(f,2)
        results += ','.join(map(str,[f,q,l,r])) + '\n'
      ## if csv enable print values in csv file ## else print to the prompt
      if args.csvFile:
        with open(inductor+'_'+skew+'_QL.csv','w') as fout: fout.write(results)
      else: print results
      ## show the plot if requested
      if type(args.plotme) == list:
        getPlotArg = lambda ff: {'Q':Q,'L':L,'R':R}.get(ff)
        if any(args.plotme):
          if args.plotme[0].lower() == 'all': plotArgs = {'Q':Q,'L':L,'R':R} #if all is asked for
          else:
            plotArgs = {}
            for ii in set(args.plotme): plotArgs.update({ii:getPlotArg(ii)}) 
        else: plotArgs = {'Q':Q,'L':L}
        if not Layouts: [Figs,Layouts] = plotUtils.layoutPlt(len(plotArgs),grH=6,grW=6);     
        count = plotData(F,plotArgs,skew,Layouts,Figs,count)  
    pl.show()

if __name__ == '__main__':
  mainExe()

