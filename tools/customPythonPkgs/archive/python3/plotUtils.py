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
#   Useful functions for graphing 
#
##############################################################################

def layoutPlt(nFigs,grH = 11/3., grW = 9/3.):
  """creates figures for plotting, returns the figure list and the subplot list, both as lists"""
  import pylab as plt, numpy
  Figs=[]; Layouts=[]; 
  for ii in range(int(nFigs/9)): # create 3x3 figures
    [rVal,cVal] = [3,3]
    fig, layout = plt.subplots(nrows=rVal,ncols=cVal,figsize=[cVal*grW,rVal*grH]);
    Figs.append(fig); [Layouts.append(ii) for ii in layout.reshape(numpy.size(layout))]
  if (nFigs % 9) != 0: # create remainder figure < 3x3
    rem = nFigs%9
    [rVal,cVal] = [1,3] if rem == 3 else [int(round(rem**0.5)),int(numpy.ceil(rem**0.5))]
    fig, layout = plt.subplots(nrows=rVal,ncols=cVal,figsize=[cVal*grW,rVal*grH]); 
    if type(layout) != numpy.ndarray: layout = numpy.array(layout) # case of one plot
    Figs.append(fig); [Layouts.append(ii) for ii in layout.reshape(numpy.size(layout))]
    if rem==5 or rem>=7: 
      for ii in range(len(Layouts),rem+int(nFigs/9)*9,-1): #delete unused plots from figure and list
        Figs[-1].delaxes(Layouts[ii-1]); Layouts.pop(ii-1) # start from the last one, python index is -1    
  return Figs,Layouts
  
def getPltKeys(pltArg):
  import re
  yOutDictLabel = {'Q':'Quality Factor','Qd':'Quality Factor','Qse':'Quality Factor','L':'Inductance(nH)','Lse':'Inductance(nH)','Ld':'Inductance(nH)',
  'C':'Capacitance(fF)','Cd':'Capacitance(fF)','Cse':'Capacitance(fF)','Rd':'Resistance(Ohms)','Rse':'Resistance(Ohms)','R':'Resistance(Ohms)',
  'insertion':'Insertion Loss(db)','inReturn':'In Return Loss(db)','insertionPh':'Insertion Phase(Radians)',
  'outReturn':'Out Return Loss(db)','C11':'C11(fF)','C22':'C22(fF)','C12':'C12(fF)','C21':'C21(fF)',
  'L11':'Inductance(nH)','L22':'Inductance(nH)','Q11':'Quality Factor','Q22':'Quality Factor','R11':'R11(Ohms)','R22':'R22(Ohms)',
  'R12':'R12(Ohms)','R21':'R21(Ohms)','k':'k'}
  pltDict = {'Qd':'Qdiff','Ld':'Ldiff(nH)','Qse':'Qse','Lse':'Lse(nH)','Cd':'Cdiff(fF)','Cse':'Cse(fF)','Rd':'Rdiff(Ohms)','Rse':'Rse(Ohms)',
  'C11':'C11(fF)','C22':'C22(fF)','C12':'C12(fF)','C21':'C21(fF)',
  'Q11':'Q11','Q22':'Q22','L11':'L11(nH)','L22':'L22(nH)','k':'k',
  'R11':'R11(Ohms)','R22':'R22(Ohms)','R12':'R12(Ohms)','R21':'R21(Ohms)',
  'insertion':'Insertion Loss(db)','inReturn':'In Return Loss(db)','insertionPh':'Insertion Phase(rad)','outReturn':'Out Return Loss(db)',}
  if pltArg in yOutDictLabel: 
    yOutLabel = yOutDictLabel.get(pltArg); #print yOutLabel
  else:  
#    print(pltArg)
    if re.search(r'^Q',pltArg): yOutLabel = 'Quality Factor'
    elif re.search(r'^L',pltArg): yOutLabel = 'Inductance(nH)'
    elif re.search(r'^C',pltArg): yOutLabel = 'Capacitance(fF)'
    elif re.search(r'^R',pltArg): yOutLabel = 'Resistance(Ohms)'
    else: yOutLabel = pltArg
  pltKey = pltDict.get(pltArg,pltArg)
  return pltKey, yOutLabel

## Get the files to plot as 2 dim array
def group(inLst,prefix='',suffix=''):
  import itertools, os, re
  results=[]; entryLst = inLst[:]
  while entryLst: ## get the raw data
    fileP=entryLst.pop(0); fileT = os.path.basename(fileP) # pop the first one
    test = re.search(r'^'+prefix+'(?P<rowName>.*?)'+suffix+'$',fileT) 
    if test:
      rowName = test.group('rowName'); rowList = [fileP];
      for iiTest in entryLst[:]: # compare with the whole table slicing it with a copy
        if re.search(r'^'+prefix+rowName+suffix+'$',os.path.basename(iiTest)):
          rowList.append(iiTest);
          entryLst.pop(entryLst.index(iiTest))
      results.append(rowList); 
  if not any(results): #if could not group anything
    Warning('No grouping accomplished')
    print('#No grouping accomplished')
    for ii in inLst: results.append([ii])
  return results

## Return X,Y from X with Sigmas and STD
def computeStd(means,stds,size=3):
  yplus=[]; yminus=[]
  for mean,std in zip(means,stds):
    yplus.append(mean + size*std)
    yminus.append(mean - size*std)
  return yminus,means,yplus    

## Return Color for the legend
def getColor(value,default='k'):
  import re
  colors = {'ssss':'r','pcss':'r','ffff':'g','pcff':'g','tttt':'k','prcs':'r','prcf':'g'}; 
  priorityK = ['ssss','ffff','tttt','prcs','prcf','pcss','pcff'] 	    
  for cc in priorityK:
    test = re.search(r''+cc,value,flags=re.I)
    if test: return colors.get(cc);
  return default
