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
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, re, math, subprocess, pandas as pd, numpy, collections, sclIndModel, os
from numtools import numToStr as toStr
argparser = argparse.ArgumentParser(description='Scalable Inductor')
argparser.add_argument(dest='csvFile', help='Test file with Dims/QLR')
argparser.add_argument('-ai', dest='ai', default = ['neighbor'], nargs='+', choices = ['ann','annR','tree','lin','neighbor','svm'], help='machine learning algorithm')
argparser.add_argument('-param', dest='param', default = ['q','l'], nargs='+', choices = ['q','l','r'], help='Parameter(s) to test')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## Read the File and get all the XTest
csvF = pd.read_csv(args.csvFile)
## get the model based on the ai and correct parameters
indModels = sclIndModel.getModel(['oct','-ai']+args.ai) #dummy argument oct
params = list(map(lambda ff: sclIndModel.getEffParam(ff), args.param))
## prepare the X data and drop unnecessary X
xTest = csvF[indModels[0].dimensions]; xEffLabels = indModels[0].dimensions+params; csvF = csvF[xEffLabels]
## predict the data
for ai,model in zip(args.ai,indModels):
  yPreds = collections.OrderedDict();
  for param in params:
    print('Working Hard: '+param+': ai='+ai)
    yPreds[param] = model.predict(param,xTest)
  yPreds['srcData'] = numpy.repeat(['predicted'],len(xTest)); 
  fDf = pd.concat([csvF,pd.DataFrame({'srcData':numpy.repeat(['original'],len(csvF))})],axis=1)
  pDf = pd.concat([xTest,pd.DataFrame(yPreds)],axis=1)
  fDf = fDf.append(pDf)
  ## save csv as jmp friendly
  fName = os.path.basename(os.path.splitext(args.csvFile)[0])+'_'+ai+'.csv'
  fDf.to_csv(fName,index=False,float_format='%.3g'); print("Wrote: "+fName)
  
