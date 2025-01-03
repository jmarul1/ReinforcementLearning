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
#   Type >> plotRF.py -h 
##############################################################################

## Functions
def targetFiles(path):
  import os, argparse, re
  lstFiles = []
  if os.path.isdir(path):
    lstFiles = os.listdir(path); lstFiles = filter(lambda ff: re.search(r'\.csv$',ff,flags=re.I), lstFiles); 
    if any(lstFiles): lstFiles = [path+'/'+ii for ii in lstFiles]; lstFiles = map(os.path.normpath,lstFiles); 
  elif os.path.isfile(path): 
    if os.path.splitext(path)[1]=='.csv': lstFiles = [path]
  else: raise argparse.ArgumentTypeError('File or Dir doesn\'t exist: '+path)
  return lstFiles

def fixGraph(AxF,**kArgs):
  import argparse
  AxF.legend(loc='best',handletextpad=0.5,prop=kArgs.get('legendSize',{'size':9}),frameon=False,ncol=2); offset = 1.1#1.25
  if kArgs.get('grid',True): AxF.grid(True,which='both')
  AxF.set_ylabel(kArgs.get('ylabel','Quality Factor'));
  AxF.set_xlabel(kArgs.get('xlabel','Frequency(GHz)'));
  if not(kArgs.get('ylabel','Quality Factor') in ['(db)','(Radians)']):
    ylims = kArgs.get('ylims',[0,AxF.get_ylim()[1]*offset]); xlims = kArgs.get('xlims',[0,AxF.get_xlim()[1]])
#    ylims = kArgs.get('ylims',[AxF.get_ylim()[0],AxF.get_ylim()[1]*offset]); xlims = kArgs.get('xlims',[0.01,1])
    if kArgs.get('limitAx',True): AxF.set_ylim(ylims[0],ylims[1]); AxF.set_xlim(xlims[0],xlims[1]); 
  AxF.set_yscale(kArgs.get('yscale','linear')); AxF.set_xscale(kArgs.get('xscale','linear')) 
  AxF.set_title(kArgs.get('title',AxF.get_title()))

def plotModel(AxF,name,csvModelLst,pltArgs):
  import csvUtils,argparse,os
  dF = csvUtils.dFrame(csvModelLst.name,text=True); found = False; colors = {'s':'r','f':'g','t':'k'}; rfKey='RF'
  for ii,mKey in enumerate(dF.keys()):
    if mKey == rfKey: continue
    else:
      modelCsv = dF[mKey][dF[rfKey].index(name)] if name in dF[rfKey] else '' ## get the model to compare based on the csvModelLst
      if modelCsv != '':
        modelCsv = os.path.dirname(csvModelLst.name)+'/'+modelCsv if os.path.dirname(csvModelLst.name) else modelCsv #use the same path the model files is for its components
        modelDF = csvUtils.dFrame(modelCsv,text=False); 
        AxF.plot(modelDF[pltArgs[0]],modelDF[pltArgs[1]],'D'+colors.get(mKey[-1],'k'),lw=4,label=mKey,fillstyle='none',ms=4,mew=1.5); found = True
  return found
 
def mainExe(argLst=None):
  import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
  import argparse, os, re, numpy, itertools, plotUtils
  import csvUtils, smooth, pylab as plt
  ## Argument Parsing
  inChoices = ['Qd','Ld','Qse','Lse','Cd','Cse','Rd','Rse','C11','C22','insertion','inReturn','outReturn','insertionPh']
  argparser = argparse.ArgumentParser(description='Plots all CSV files in give DIR and combine dies in single plots')
  argparser.add_argument(dest='input', nargs='+', type=targetFiles, help='Dir(s) or file(s) to compute')
  argparser.add_argument('-model', dest='model', type=file, help='CSV file with RF,Model table for comparison')
  argparser.add_argument('-plt', dest='plt', choices=inChoices, default='Qd', help='What to Plot')
  argparser.add_argument('-smooth', dest='smooth',nargs='?',choices=['both'],const=True, help='Smooth data with local regressions, specify both to plot both')
  argparser.add_argument('-prefix', dest='prefix', default='X-?\d+Y-?\d+', help='Prefix to be used for comparison and grouping of the input dir(s)/file(s)')
  argparser.add_argument('-suffix', dest='suffix', default='', help='Suffix to be used for comparison and grouping of the input dir(s)/file(s)')
  argparser.add_argument('-save',dest='save',nargs='?',const='PLOTME', help='Saves all the figures as PLOTME|[given prefix]_number')
  argparser.add_argument('-noplot',dest='plotme',action='store_false',help=argparse.SUPPRESS)
  argparser.add_argument('-title',dest='title',help='Group number 1 of the regular expression to label each plot')
  argparser.add_argument('-fs',dest='fSize',default=11.0,type=float,help=argparse.SUPPRESS)
  argparser.add_argument('-logy',dest='logy',default='linear',const='log',action='store_const',help=argparse.SUPPRESS)
  argparser.add_argument('-logx',dest='logx',default='linear',const='log',action='store_const',help=argparse.SUPPRESS)  
  argparser.add_argument('-override',dest='override',help=argparse.SUPPRESS)  
  argparser.add_argument('-plotforreal',dest='plotforreal',help=argparse.SUPPRESS)
  argparser.add_argument('-nolim',dest='limit',action='store_false',help=argparse.SUPPRESS)  
     
  args = argparser.parse_args(argLst)
  ## Define plotting keywords
  pltOutArgs = ['Freq(GHz)']; pltOutArgs.extend(plotUtils.getPltKeys(args.plotforreal if args.plotforreal else args.plt)); pltOutArgs.insert(2,'Frequency(GHz)')
  args.plt = pltOutArgs # store [x_key,y_key,x_label,y_label]
  if args.plotforreal: print args.plt; args.plt[1] = args.plotforreal; print args.plt
  
  ## Get the files to plot as 2 dim array
  lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();
  if not any(lstFiles): raise argparse.ArgumentTypeError('File(s) or Dir(s) given aren\'t or don\'t contain ANY csv files')
  results=plotUtils.group(lstFiles,prefix=args.prefix,suffix=args.suffix); rowMax = len(results)
  for iiRow in results: print(iiRow);
  #exit()
  ## decide the layout of the graph
  [Figs,Layouts] = plotUtils.layoutPlt(rowMax, grW = float(args.fSize)/3) if rowMax != 1 else plotUtils.layoutPlt(rowMax, grW = float(args.fSize))

  ## plot the data
  fSize = args.fSize*8
  for cc,row in enumerate(results): # results are 2 dim array
    Layouts[cc].hold(True); foundOnce=False; mm=0
    for csvFile in row:
      dF = csvUtils.dFrame(csvFile,text=False); test1 = re.search(r'('+args.prefix+'.*?'+args.suffix+')',os.path.basename(csvFile),flags=re.I); 
      if test1:
        gLen = len(test1.groups())
        labelMe = test1.group(gLen) if gLen<=2 else test1.group(gLen-1)+'_'+test1.group(gLen)
      else: labelMe = ''
      suffix = '(lowess)' if args.smooth else '';
      if args.title: test1 = re.search(r''+args.title,os.path.basename(csvFile),flags=re.I); titleMe = ' '.join(test1.groups()) if test1 else args.title;
      else: titleMe = csvFile
      x = dF[args.plt[0]]; y = smooth.RLoess(x,dF[args.plt[1]],span=0.3,iteration=4) if args.smooth else dF[args.plt[1]]
      if args.smooth == 'both':
  	(Layouts[cc]).plot(x,dF[args.plt[1]],'o',fillstyle='none',ms=4,label=labelMe); Layouts[cc].set_title(titleMe)
  	(Layouts[cc]).plot(x,y,ls='-',lw=1.5,c=Layouts[cc].get_lines()[-1].get_markeredgecolor(),label=labelMe+suffix)
      else:
        if args.override: import plot; plot.plot(csvFile,Layouts,cc,x,y,labelMe,suffix) 
	else:  (Layouts[cc]).plot(x,y,'-',fillstyle='none',ms=3,label=labelMe+suffix,lw=1); 
	Layouts[cc].set_title(titleMe);
	mm += 1
      if args.model and not foundOnce: foundOnce = plotModel(Layouts[cc],os.path.basename(csvFile),args.model,args.plt);
    Layouts[cc].hold(False)

  ## add axis and labels
  [fixGraph(iiGraph,xlabel=args.plt[2],ylabel=args.plt[3],yscale=args.logy,xscale=args.logx,limitAx=args.limit,legendSize={'size':12}) for iiGraph in Layouts]
  for iiFig in Figs: iiFig.tight_layout(); iiFig.suptitle(args.plt[1],y=0.5,fontsize=fSize,color='gray',alpha=0.3,rotation=45,va='center',ha='center')

  ## show the graph and save
  if __name__ == '__main__':
    if args.plotme: plt.show()
  if args.save:
    [iiFig.savefig(args.save+'_'+str(cc)+'.png') for cc,iiFig in enumerate(Figs)]
  return Figs,Layouts
        
if __name__ == '__main__':
  mainExe()
