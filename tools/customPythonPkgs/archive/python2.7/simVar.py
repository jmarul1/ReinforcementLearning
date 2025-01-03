#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> simVar.py -h 
##############################################################################

def plotData(xArray,plotArgs,skew,freq, Layouts=False,Figs=False,count=0):
  import plotUtils, numtools, pylab as pl, argparse
  if not Layouts: [Figs,Layouts] = plotUtils.layoutPlt(len(plotArgs)); 
  markerList = dict(tttt='-k',ffff='-b',ssss='-r',ffvss='-g',ssvff='-m',rfff='-b',rsss='-r')  
  for ii,iiKey in enumerate(plotArgs):
    iiAx = Layouts[ii]; iiAx.hold(True)
    if iiKey in ['C','Q','R']: 
      iiAx.plot(xArray,plotArgs[iiKey],markerList[skew],label=iiKey+'d_'+skew)
      iiAx.legend(loc='best'); #iiAx.set_ylim(0,iiAx.get_ylim()[1]); 
      if iiKey == 'C' and count==0: # compute cmin/cmax 
        cmin = min(plotArgs[iiKey]); cmax = max(plotArgs[iiKey]); ratio = cmax/cmin; midP = (cmin+cmax)/2
        cmin,cmax,ratio = [numtools.numToStr(ff,2) for ff in [cmin,cmax,ratio]]
        text = '$C_{min}='+cmin+'fF$\n$C_{max}='+cmax+'fF$\n$\\frac{C_{max}}{C_{min}}='+ratio+'$'
        iiAx.text(0.99*iiAx.get_xlim()[0],midP,text,ha='left',va='center',size='x-large',color=markerList[skew][1]);count+=1        
    else: 
      iiAx.plot(xArray,plotArgs[iiKey])      
    iiAx.set_ylabel(plotUtils.getPltKeys(iiKey)[1]);
    iiAx.set_xlabel('Voltage(V)');   
    iiAx.hold(False)
  for iiFig in Figs: iiFig.tight_layout(); iiFig.suptitle(freq,y=0.5,fontsize=80,color='gray',alpha=0.3,rotation=45,va='center',ha='center')
  return count
  
def mainExe():
  ##############################################################################
  # Argument Parsing
  ##############################################################################
  import argparse, os, sys, re, math 
  sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
  import ckts, numtools, plotUtils, pylab as pl
  argparser = argparse.ArgumentParser(description='Calculates Q/C')
  argparser.add_argument(dest='name', nargs='+', help='varactor name')
  argparser.add_argument('-upf', dest='include', type=os.path.realpath, help='UPF or SCS file')
  argparser.add_argument('-skew', dest='skew', nargs = '+', choices = ['tttt','ffff','ssss','rfff','rsss','ffvss','ssvff','pcff','pcss'], default=['tttt'], help='Skew')
  argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "var"_QL.csv')
  argparser.add_argument('-plot', dest='plotme', nargs='*', choices=['Q','C','R','all'], help='displays a plot picture for the sparameter.')
  argparser.add_argument('-freq', dest='freq', default = '10G', type=numtools.getScaleNum, help='Frequency to extract')
  argparser.add_argument('-volt', dest='volt', nargs = '+', default=[-1,0.1,1], type=numtools.getScaleNum, help='Voltage Range as [max] or [min max] or [min step max]')
  argparser.add_argument('-sim', dest='sim',default='hsp',choices=['scs','hsp'], help='Simulator Spectre or Lynx')
  args = argparser.parse_args()
  ##############################################################################
  # Main Begins
  ##############################################################################

  ## Set voltages
  if len(args.volt) == 1: mVolt = args.volt[0]; fVolt = 0.01*numtools.getScaleNum(mVolt); sVolt = fVolt
  elif len(args.volt) == 2: fVolt, mVolt = args.volt; sVolt = 0.01*numtools.getScaleNum(mVolt)
  elif len(args.volt) == 3: fVolt, sVolt, mVolt = args.volt
  else: raise IOError('Wrong number of frequencies fool')
  count=0
  ## run for each file specified 
  for varactor in args.name:
    Layouts = False
    for skew in args.skew:
      include = ckts.getIncludes(args.sim,skew,args.include)
      if not ckts.checkSub(varactor,include): sys.stderr.write('Model does not exist: '+varactor+'\n'); continue
      var = ckts.varactor(varactor,args.sim,'25');
      V,Q,C,R = var.simulate(include,args.freq,skew,fVolt,sVolt,mVolt)
      results = 'Voltage(V),Qdiff,Cdiff(fF),Rdiff(Ohms)\n'
      for v,q,c,r in zip(V,Q,C,R):
        v = numtools.numToStr(v,2)
        results += ','.join(map(str,[v,q,c,r])) + '\n'
      ## if csv enable print values in csv file ## else print to the prompt
      if args.csvFile:
        with open(varactor+'_'+skew+'_QC.csv','w') as fout: fout.write(results)
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
        if not Layouts: [Figs,Layouts] = plotUtils.layoutPlt(len(plotArgs),grH=6,grW=6);     
        count = plotData(V,plotArgs,skew,numtools.numToStr(args.freq/1e9,1)+'G',Layouts,Figs,count)  
    pl.show()

if __name__ == '__main__':
  mainExe()

