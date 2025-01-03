#!/usr/bin/env python3.7.4
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
##############################################################################

def chkIn(num):
  import numtools, re
  if re.search(r'train',num): return 'trainingMode'
  if num in ['rec','oct']: return num
  num = numtools.getScaleNum(num)
  if numtools.isNumber(num): return num
  else: raise IOError('Provide numbers or indType(oct,rec)')

def getEffParam(param):
  paramExpand = {'l':'Ld_full(nH)','q':'Qd_full','r':'Rd_full(Ohms)'}
  paramCompress = {'Ld_full(nH)':'l','Qd_full':'q','Rd_full(Ohms)':'r'}    
  if param in paramExpand.keys(): return paramExpand.get(param)
  if param in paramCompress.keys(): return paramCompress.get(param)
  return param
  
def getFreqRng(freqs):
  import numpy
  freqs = list(map(lambda ff: ff/1e9,freqs))
  if len(freqs) == 1: mFreq = freqs[0]; fFreq = 0.01*mFreq; sFreq = fFreq
  elif len(freqs) == 2: fFreq, mFreq = freqs; sFreq = 0.01*mFreq
  elif len(freqs) == 3: fFreq, sFreq, mFreq = freqs
  else: raise IOError('Wrong number of frequencies fool')
  return numpy.arange(fFreq,mFreq,sFreq)

def getScaleUp(lst):
  import math
  print(min(abs(lst[lst!=0])))
  decimal = int(math.log(min(abs(lst[lst!=0])),10));
  decimal = abs(decimal)+3
  print(decimal)
  print(max(lst*(10**decimal))); exit()
  
def writeQa(model,*params):
  import pandas as pd, numpy, collections
  print('Starting QA')
  xTest = model.df[model.dimensions] # FOR ALL DATA
  sawType = pd.DataFrame(model.model[params[0]][2][0].iloc[:,0].values,columns=['TestType']); sawType.iloc[:] = 'unseen'  # FOR UNSEEN DATA
  sawType = pd.concat([sawType,xTest.iloc[:,0]],axis=1).iloc[:,0].fillna('seen');
  yPreds = collections.OrderedDict(); yOrig = pd.DataFrame()
  for param in params:
    print('Working Hard:'+param)
    yOrig = pd.concat([yOrig,model.df[param]],axis=1)
    yPreds[param] = model.predict(param,xTest)
  yPreds['srcData'] = numpy.repeat(['predicted'],len(xTest)); 
  ## remember which one is orig and which one is tested
  fDf = pd.concat([xTest,yOrig,pd.DataFrame({'srcData':numpy.repeat(['orig'],len(xTest))}),sawType],axis=1)
  pDf = pd.concat([xTest,pd.DataFrame(yPreds),sawType],axis=1)
  fDf = fDf.append(pDf)
  ## create a column for easy plot in JMP
  indeces = fDf['indType']; 
  for ii,jj in zip(['N','W(um)','S(um)','X(um)','Y(um)'],['n','w','s','x','y']): indeces = indeces+'_'+fDf[ii].astype(str)+jj
  indeces = indeces.apply(lambda ff: ff.replace('.','p').replace('p0',''))
  fDf = fDf.set_index(indeces.values)
  ## write to file
  fName = (''.join(map(lambda ff: getEffParam(ff), params)))+'_'+model.ai+'.csv'
  fDf.to_csv(fName,index_label='index',float_format='%.3g'); print("QA Wrote: "+fName)
  
class aiModel:
  def __init__(self,ai):
    self.ai = ai; self.model = {}; self.trainFile = False; 
    self.dimensions = ['indType','N','W(um)','S(um)','X(um)','Y(um)','Fd_full(GHz)']
    self.dump = '/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/AI'
  ## FITTING OPTIONS
    if self.ai in ['ann','annR']: self.options = dict(hidden_layer_sizes=(100,100,100,100),verbose=1,max_iter=100,early_stopping=True,alpha=0.001); 
    else: self.options = {}
    self.shape = lambda ss: {'rec':1,'oct':2,1:'rec',2:'oct'}.get(ss,3); 
  def train(self,csv,qa,param):
    import numpy, ai, pandas as pd, numpy, os
    if self.trainFile != os.path.normpath(csv): self.df = pd.read_csv(csv,comment='#'); self.trainF=os.path.normpath(csv)
    self.xTrain, self.yTrain  = self.df[self.dimensions].copy(), self.df[param].copy(); #getScaleUp(self.yTrain)
    self.xTrain.loc[:,'indType'] = self.xTrain['indType'].apply(self.shape);  self.yTrain=(self.yTrain*1e3).astype(numpy.int64)     ## convert F/Q/L to integers and shape to numbers oct=1; rec=2
    print('Fitting Model for: '+param); #if its complex fit it in two parts
    if qa: qa = ['indType','N','W(um)','S(um)','X(um)','Y(um)']
    self.model[param] = ai.fit(self.xTrain,self.yTrain,self.ai,qa,**self.options)
  ## predict
  def predict(self,param,xTest):
    import numpy
    xEff = xTest.copy(); xEff[self.dimensions[0]] = xEff[self.dimensions[0]].apply(self.shape)
    xEff = self.model[param][1].transform(xEff)
    return self.model[param][0].predict(xEff).astype(numpy.float64)*1e-3 # values are in nH,GHz
  def readModel(self,param,path):
    import pickle
    with open(path, 'rb') as fin:
      print('Reading existing model: '+path)
      self.model[param] = pickle.load(fin);
  def write(self,*params):
    import pickle
    for param in params:
      if param in self.model.keys():
        effParam = getEffParam(param)
        fName = self.dump+'/indSclModel_'+effParam+'.'+self.ai
        with open(fName, 'wb') as fout: pickle.dump(self.model[param],fout); print('wrote '+fName)

def isThereModel(ai,param):
  import os
  path = '/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/AI/indSclModel_'+  getEffParam(param)+'.'+ai 
  if os.path.isfile(path): return path
  else: return False

def getModel(argLst=None):
  ##############################################################################
  # Argument Parsing
  ##############################################################################
  import argparse, re, math, subprocess, pandas as pd, numpy, collections
  from numtools import numToStr as toStr
  argparser = argparse.ArgumentParser(description='Scalable Inductor')
  argparser.add_argument('-train', dest='train', default = '/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/AI/trainTables/inductorGuideSimple.csv', help=argparse.SUPPRESS)
  argparser.add_argument('-param', dest='trainParam', default = ['q','l'], nargs='+', choices = ['q','l','r','sp'], help='Parameter(s) to train')
  argparser.add_argument('-ai', dest='ai', default = ['neighbor'], nargs='+', choices = ['ann','annR','tree','lin','neighbor','svm'], help='machine learning algorithm')
  argparser.add_argument('-qa', dest='qa', action='store_true', help='Print Csv of Validation')
  argparser.add_argument('-freq', dest='freq', nargs='+', default = [100e9], type=chkIn, help='Maximum frequency with units attached, default=65G. [You can also give "start stop" or "start step stop"; with units attached i.e. 10G 1G 50G]')
  argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "dims"_QL.csv')
  argparser.add_argument(dest='inputs', nargs='+', type=chkIn, help='Inputs Shape,N,W,S,X,Y')
  args = argparser.parse_args(argLst)
  ##############################################################################
  # Main Begins
  ##############################################################################
  paramLst = [getEffParam(ff) for ff in args.trainParam]; indModels = []
  if 'sp' in paramLst: paramLst.remove('sp'); paramLst+=['s11r','s11i','s12r','s12i','s21r','s21i','s22r','s22i']
  if 'trainingMode' in args.inputs: ## Train if asked
    for ai in args.ai:
      indModel = aiModel(ai);
      for param in paramLst: indModel.train(args.train,args.qa,param); indModel.write(param)
      if args.qa: writeQa(indModel,*paramLst)
    exit(0)
  ## for all ai given
  for ai in args.ai:
    ## Read or train it
    indModel = aiModel(ai); 
    for param in paramLst:
      test = isThereModel(ai,param)
      if test: indModel.readModel(param,test) # Read
      else: indModel.train(args.train,args.qa,param); indModel.write(param) #Train
    ## if a function store the models and break out of the loop
    if __name__ != '__main__':  indModels.append(indModel); continue
    #### now we have a trained model so predict
    if args.qa: writeQa(indModel,*paramLst) ## print the qa if requested
    outData = collections.OrderedDict()
    shape,N,W,S,X,Y = args.inputs[0],args.inputs[1],args.inputs[2]*1e6,args.inputs[3]*1e6,args.inputs[4]*1e6,args.inputs[5]*1e6 #shape,N,W,S,X,Y
    inputs = numpy.array([shape,N,W,S,X,Y]); freqs = getFreqRng(args.freq); inputs = numpy.broadcast_to(inputs,[len(freqs),len(inputs)]);
    xTest = pd.DataFrame(numpy.concatenate([inputs,freqs.reshape(len(freqs),1)],axis=1),columns=indModel.dimensions); outData=pd.DataFrame({'Freq(GHz)':freqs})
    for param in paramLst: outData = pd.concat([outData,pd.DataFrame({param:indModel.predict(param,xTest)})],axis=1)
    if args.csvFile:
      N,W,S,X,Y = list(map(lambda ff: (toStr(toStr(ff,1))).replace('.','p'), [N,W,S,X,Y]))
      fname = ai+'_ind__'+shape+'_'+N+'n_'+W+'w_'+S+'s_'+X+'x_'+Y+'y_QL.csv'
      headers = {'Ld_full(nH)':'Ldiff(nH)','Qd_full':'Qdiff','Rd_full':'Rdiff(Ohms)'}
      outData.to_csv(fname,index=False,header=['Freq(GHz)']+list(map(lambda ff: headers.get(ff), paramLst)))
      print('Wrote '+fname)
    else: print(outData)
  return indModels ## called a functions return all models
if __name__ == '__main__':
  getModel()

