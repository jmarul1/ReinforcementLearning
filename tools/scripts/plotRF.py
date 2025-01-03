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
#   Type >> plotRF.py -h 
##############################################################################

legendCols = 1

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
  import argparse, textutils
  AxF.legend(loc='best',handletextpad=0.5,prop=kArgs.get('legendSize',{'size':7}),frameon=False,ncol=legendCols); offset = 1.1#1.25
  handles,labels=AxF.get_legend_handles_labels(); AxF.legend(handles,(textutils.shorten(ff,45) for ff in labels))
  if kArgs.get('grid',True): AxF.grid(True,which='both')
  AxF.set_ylabel(kArgs.get('ylabel','Quality Factor'));
  AxF.set_xlabel(kArgs.get('xlabel','Frequency(GHz)'));
  if not(kArgs.get('ylabel','Quality Factor') in ['(db)','(Radians)']):
    ylims = kArgs.get('ylims',[0,AxF.get_ylim()[1]*offset]); xlims = kArgs.get('xlims',[0,AxF.get_xlim()[1]])
#    ylims = kArgs.get('ylims',[AxF.get_ylim()[0],AxF.get_ylim()[1]*offset]); xlims = kArgs.get('xlims',[0.01,1])
#    if ylims[-1] > 30: ylims = [0,30];# xlims = [0,30]
    if kArgs.get('limitAx',True): AxF.set_ylim(ylims[0],ylims[1]); AxF.set_xlim(xlims[0],xlims[1]);
  AxF.set_yscale(kArgs.get('yscale','linear')); AxF.set_xscale(kArgs.get('xscale','linear')) 
  AxF.set_title(kArgs.get('title',AxF.get_title()))

def getLabels(csv,prefix,suffix,title,smth):
  import os, re
  test1 = re.search(r'('+prefix+'.*?'+suffix+')',os.path.basename(csv),flags=re.I); 
  if test1: gLen = len(test1.groups()); labelMe = test1.group(gLen) if gLen<=2 else test1.group(gLen-1)+'_'+test1.group(gLen)
  else: labelMe = ''
  if title: test1 = re.search(r''+title,os.path.basename(csv),flags=re.I); titleMe = ' '.join(test1.groups()) if test1 else title;
  else: titleMe = '' #csvFile
  suffixS = '(lowess)' if smth else '';
  return labelMe, titleMe, suffixS

def plotData(Layouts,counter,labelMe,titleMe,suffix,dF,xK,yK,smt):
  import smooth, re, plotUtils
  x = dF[xK]; y = smooth.RLoess(x,dF[yK],span=0.3,iteration=4) if smt else dF[yK]
  if smt == 'both':
    (Layouts[counter]).plot(x,dF[yK],'o',fillstyle='none',ms=4,label=labelMe); Layouts[counter].set_title(titleMe)
    (Layouts[counter]).plot(x,y,ls='-',lw=1.5,c=Layouts[counter].get_lines()[-1].get_markeredgecolor(),label=labelMe+suffix)
  else:
    test = re.search(r'(tttt|ffff|ssss|pcff|pcss|prcs|prcf)', labelMe, flags=re.I)
    test = False
    if test: (Layouts[counter]).plot(x,y,('o' if re.search(r'sparam',labelMe,flags=re.I) else '-'),fillstyle='none',ms=3,label=labelMe+suffix,color=plotUtils.getColor(test.group(1)),lw=1.5);
    else: (Layouts[counter]).plot(x,y,'-',fillstyle='none',ms=3,label=labelMe+suffix,lw=1.5);
  Layouts[counter].set_title(titleMe); 
  return Layouts
    
def plotModel(AxF,name,csvModelLst,pltArgs):
  import csvUtils,argparse,os,re,plotUtils
  dF = csvUtils.dFrame(csvModelLst.name,text=True); found = 0; rfKey='RF'
  for ii,mKey in enumerate(dF.keys()):
    if mKey == rfKey: continue
    else:
      modelCsv = dF[mKey][dF[rfKey].index(name)] if name in dF[rfKey] else '' ## get the model to compare based on the csvModelLst
      if modelCsv != '':
        modelCsv = os.path.dirname(csvModelLst.name)+'/'+modelCsv if os.path.dirname(csvModelLst.name) else modelCsv #use the same path the model files is for its components
        if not os.path.isfile(modelCsv): continue
        modelDF = csvUtils.dFrame(modelCsv,text=False);
        AxF.plot(modelDF[pltArgs[0]],modelDF[pltArgs[1]],'o'+plotUtils.getColor(mKey),lw=4,label=mKey,fillstyle='none',ms=3,mew=1.5); found = 1
  return found
 
def mainExe(argLst=None):
  import sys,os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
  import argparse, re, numpy, itertools, plotUtils, csvUtils, pylab as plt
  ## Argument Parsing
  inChoices = ['Qd','Ld','Qse','Lse','Cd','Cse','Rd','Rse','C11','C22','C12','C21','R11','R22','R12','R21','L11','Q11','L22','Q22','k12','Z0','Bl','Qtl','insertion','inReturn','outReturn','insertionPh'];   testChip = 'X-?\d+Y-?\d+'
  argparser = argparse.ArgumentParser(description='Plots all CSV files in give DIR and combine dies in single plots',formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  argparser.add_argument(dest='input', nargs='+', type=targetFiles, help='Dir(s) or file(s) to compute')
  argparser.add_argument('-model', dest='model', type=open, help='CSV file with RF,Model table for comparison')
  argparser.add_argument('-plt', dest='plt', nargs='+', choices=inChoices, default=['Qd','Ld'], help='What to Plot')
  argparser.add_argument('-smooth', dest='smooth',nargs='?',choices=['both'],const=True, help='Smooth data with local regressions, specify both to plot both')
  argparser.add_argument('-prefix', dest='prefix', default='.*', help='Prefix to be used for comparison and grouping of the input dir(s)/file(s)')
  argparser.add_argument('-suffix', dest='suffix', default='', help='Suffix to be used for comparison and grouping of the input dir(s)/file(s)')
  argparser.add_argument('-save',dest='save',nargs='?',const='', help='Saves all the figures as PLOTME|[given prefix]_number')
  argparser.add_argument('-noplot',dest='plotme',action='store_false',help=argparse.SUPPRESS)
  argparser.add_argument('-title',dest='title',help='Group number 1 of the regular expression to label each plot')
  argparser.add_argument('-fs',dest='fSize',default=15.0,type=float,help=argparse.SUPPRESS)
  argparser.add_argument('-logy',dest='logy',default='linear',const='log',action='store_const',help=argparse.SUPPRESS)
  argparser.add_argument('-logx',dest='logx',default='linear',const='log',action='store_const',help=argparse.SUPPRESS)  
  argparser.add_argument('-override',dest='override',help=argparse.SUPPRESS)  
  argparser.add_argument('-nolim',dest='limit',action='store_false',help=argparse.SUPPRESS)       
  argparser.add_argument('-varactor',dest='var',action='store_true',help=argparse.SUPPRESS)       
  args = argparser.parse_args(argLst)

  ## Define plotting keywords
  if args.var:  pltArgs,axArgs = ['Voltage(V)'],['Voltage(V)']; args.limit=False
  else: pltArgs,axArgs = ['Freq(GHz)'],['Frequency(GHz)'] 
  for iiPlt in args.plt: temp=plotUtils.getPltKeys(iiPlt); pltArgs.append(temp[0]); axArgs.append(temp[1])

  ## Get the files to plot as 2 dim array
  lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();
  if not any(lstFiles): raise argparse.ArgumentTypeError('File(s) or Dir(s) given aren\'t or don\'t contain ANY csv files')
  results=plotUtils.group(lstFiles,prefix=args.prefix,suffix=args.suffix); rowMax = len(results)*len(args.plt)
  for iiRow in results: print(iiRow);

  ## decide the layout of the graph
  grW = float(args.fSize)/3 if rowMax != 1 else float(args.fSize)
  grH = {1:9,2:4.5}.get(len(results),3)
  [Figs,Layouts] = plotUtils.layoutPlt(rowMax, grW = grW, grH = grH)

  ## plot the data
  fSize = args.fSize*2; cc=0
  for row in results: # results are 2 dim array
    foundOnce=0; 
    for csvFile in row:
      dF = csvUtils.dFrame(csvFile,text=False); 
      labelMe,titleMe,suffix = getLabels(csvFile,args.prefix,args.suffix,args.title,args.smooth)
      for mm,iiPlt in enumerate(pltArgs[1:]):
#        Layouts[cc+mm].hold(True)
        if args.override: import plot; plot.plot(csvFile,Layouts,cc+mm,x,y,labelMe,suffix) 
        Layouts = plotData(Layouts,cc+mm,labelMe,titleMe,suffix,dF,pltArgs[0],iiPlt,args.smooth)
        if args.model and foundOnce < len(args.plt): foundOnce += plotModel(Layouts[cc+mm],os.path.basename(csvFile),args.model,[pltArgs[0],iiPlt]);
 #       Layouts[cc+mm].hold(False)      
    cc+=len(args.plt)    

  ## add axis and labels
  [fixGraph(iiGraph,xlabel=axArgs[0],ylabel=axArgs[1+ii%len(args.plt)],yscale=args.logy,xscale=args.logx,limitAx=args.limit,legendSize={'size':12}) for ii,iiGraph in enumerate(Layouts)]
  for iiFig in Figs: 
    iiFig.tight_layout(); 
    iiFig.suptitle('_'.join(pltArgs[1:]),y=0.5,fontsize=fSize,color='gray',alpha=0.3,rotation=45,va='center',ha='center')

  ## show the graph and save
  if __name__ == '__main__':
    if args.plotme: plt.show()
  if args.save != None:
    [iiFig.savefig(args.save+('_'.join(args.plt))+'_'+str(cc)+'.png') for cc,iiFig in enumerate(Figs)]
  return Figs,Layouts
        
if __name__ == '__main__':
  mainExe()
