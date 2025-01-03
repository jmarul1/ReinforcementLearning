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

def getEffParam(param):
  paramExpand = {'l':'Ld_full(nH)','q':'Qd_full','r':'Rd_full(Ohms)'}
  paramCompress = {'Ld_full(nH)':'l','Qd_full':'q','Rd_full(Ohms)':'r'}    
  if param in paramExpand.keys(): return paramExpand.get(param)
  if param in paramCompress.keys(): return paramCompress.get(param)
  return param

def shapeToNum(shape): dt = {'rec':1,'oct':2,1:'rec',2:'oct'}; return dt.get(shape,None);   

def trainModel(xTrainMultiDim,yTrain,api,**kargs):
  import sklearn.linear_model, sklearn.neighbors, sklearn.tree, sklearn.ensemble, sklearn.svm, sklearn.neural_network, sklearn.gaussian_process, sklearn.naive_bayes
  import sklearn.preprocessing as preprocess
  xTrainMultiDim = xTrainMultiDim.copy()
  xTrainMultiDim.loc[:,'indType'] = xTrainMultiDim['indType'].apply(shapeToNum); 
  scalar = preprocess.StandardScaler(); scalar.fit(xTrainMultiDim); # scale
  xTrainMultiDim = scalar.transform(xTrainMultiDim); 
  yTrain = (yTrain*1e3).astype(int); 
  if   api == 'lin':      mlp = sklearn.linear_model.LinearRegression(**kargs)
  elif api == 'tree':     mlp = sklearn.tree.DecisionTreeClassifier()
  elif api == 'rf':       mlp = sklearn.ensemble.RandomForestClassifier()
  elif api == 'ada':      mlp = sklearn.ensemble.AdaBoostClassifier()    # performed really bad
  elif api == 'knn':      mlp = sklearn.neighbors.KNeighborsClassifier(1)
  elif api == 'neighbor': mlp = sklearn.neighbors.KNeighborsClassifier(**kargs)
  elif api == 'gau':      mlp = sklearn.gaussian_process.GaussianProcessClassifier()
  elif api == 'gauNB':    mlp = sklearn.naive_bayes.GaussianNB()
  elif api == 'svm':      mlp = sklearn.svm.SVC(**kargs)
  mlp.fit(xTrainMultiDim,yTrain)
  return mlp,scalar

def predict(model,scalar,xTest):
  xTest = xTest.copy()
  xTest.loc[:,'indType'] = xTest['indType'].apply(shapeToNum);
  xTest = scalar.transform(xTest)
  yHat = model.predict(xTest)*1e-3
  return yHat
  
def writeModels(modelsDt):
  import pickle
  for param,modelDt in modelsDt.items():
    for algo,model in modelDt.items():
      fName = f'indSclModel_{param}.{algo}'
      with open(fName, 'wb') as fout: pickle.dump(model,fout); print('wrote '+fName)

##############################################################################
# Argument Parsing
##############################################################################
import argparse, re, math, subprocess, pandas as pd, numpy, collections
from numtools import numToStr as toStr
argparser = argparse.ArgumentParser(description='Train Scalable Inductor')
argparser.add_argument('-train', dest='train', required = True, help='train table set')
# give the model or models
argparser.add_argument('-test', dest='test', required = True, help='test table set')
argparser.add_argument('-param', dest='trainParam', default = ['q','l'], nargs='+', choices = ['q','l'], help='Parameter(s) to train')
argparser.add_argument('-ai', dest='ai', default = ['lin'], nargs='+', choices = ['lin','tree','neighbor','knn','gauNB','rf','gau','ada','svm'], help='machine learning algorithm')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## inputs/outputs
params = [getEffParam(pp) for pp in args.trainParam]; model={}
dimensions = ['indType','n','w(um)','s(um)','x(um)','y(um)','Fd_full(GHz)']
## read the data
train = pd.read_csv(args.train); xTrain = train[dimensions]; 
test = pd.read_csv(args.test); xTest = test[dimensions];
## train the model
for param in params:
  model[param] = {};
  for algo in args.ai:
    print(f'Training {param} using {algo} ...')
    try: testM = trainModel(xTrain,train[param],algo); model[param][algo] = testM; 
    except: print(f'{param} in {algo} did not work') 
writeModels(model)
# validate agains itself and the test
trainQa = xTrain.copy(); testQa = xTest.copy()
for param,algoDt in model.items(): 
 for algo,iiModel in algoDt.items(): 
   yHatTrain = predict(iiModel[0],iiModel[1],xTrain);
   trainQa = pd.concat([trainQa,pd.DataFrame({param:train[param],f'{algo}_{param}':yHatTrain})],axis=1)
   MSE = ((train[param]-yHatTrain)**2).mean(); trainQa[f'MSE_{algo}_{param}'] = MSE; print(f'Train_MSE for {algo}_{param}:{MSE:.3f}');        
   yHatTest = predict(iiModel[0],iiModel[1],xTest);
   testQa = pd.concat([testQa,pd.DataFrame({param:test[param],f'{algo}_{param}':yHatTest})],axis=1)   
   MSE = ((test[param] -yHatTest )**2).mean(); testQa[f'MSE_{algo}_{param}'] = MSE; print(f'Test_MSE for {algo}_{param}:{MSE:.3f}')
# print the result table
trainQa.to_csv('trainQa.csv',index=False); testQa.to_csv('testQa.csv',index=False)

