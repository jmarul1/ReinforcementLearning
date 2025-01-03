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
import sys,os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
##############################################################################
def download(symbol,fromDate):
  import yfinance, os, numpy
  os.environ['http_proxy']='http://proxy-chain.intel.com:911'
  os.environ['https_proxy']='http://proxy-chain.intel.com:912'
  os.environ['ftp_proxy']='http://proxy-chain.intel.com:911'
  os.environ['socks_proxy']='http://proxy-us.intel.com:1080'
  os.environ['no_proxy']='intel.com,.intel.com,localhost,127.0.0.1'
  fromDate = numpy.datetime64('today')-numpy.timedelta64(fromDate)
  data = yfinance.download(symbol,start=fromDate)  
  y = data['Close'].to_numpy(); x = data.index.values
  return x,y

class splineFit:
  def __init__(self,xTrain,yTrain):
    import numpy; from scipy.interpolate import CubicSpline
    xEff = numpy.arange(0,len(xTrain)); 
    self.model = CubicSpline(xEff,yTrain)
  def predict(self,xTest):
    return self.model(numpy.arange(0,len(xTest)))  

class aiFit:
  def __init__(self,xTrain,yTrain,algo):
    import numpy, ai
    self.algo = algo
    xTrain,yTrain = numpy.reshape(xTrain,(-1,1)),yTrain.astype(numpy.int64)  #resize to multi variate 
    if self.algo == 'ann': self.model,self.scale,qa = ai.fit(xTrain,yTrain,self.algo,False,hidden_layer_sizes=(100,100,100),verbose=1)  
    else: self.model,self.scale,qa = ai.fit(xTrain,yTrain,self.algo,False)  
  def predict(self,xTest):
    xTest = self.scale.transform(numpy.reshape(xTest,(-1,1)))
    if self.algo == 'isotonic': xTest = numpy.reshape(xTest,-1)
    return self.model.predict(xTest)
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, tempfile, numpy, subprocess, pandas, pdb
argparser = argparse.ArgumentParser(description='Read News')
argparser.add_argument(dest='code', help='stock symbol')
argparser.add_argument('-days', dest='days', type=int, default=60, help='days to predict')
argparser.add_argument('-back', dest='back', type=int, default=10, help='days back')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## Get models (model.prediction(Xdata))
dates,realPrice = download(args.code,args.back)
splineP = splineFit(dates,realPrice); 
aiP = aiFit(dates,realPrice,'tree')
## Add days to the Xdata
for dd in range(args.days):
  dates = numpy.append(dates,dates[-1]+numpy.timedelta64(1,'D'))
  realPrice = numpy.append(realPrice,-1)
## Predict
splineVals = splineP.predict(dates).astype(str)
aiVals = aiP.predict(dates).astype(str)
## Print to CSV
keys = ['RealPrice','Spline','AI']; csv = tempfile.mkstemp(suffix='.csv')[1]
csvD = pandas.DataFrame(numpy.stack((realPrice.astype(str),splineVals,aiVals),axis=1),index=dates,columns=keys)
csvD.to_csv(csv,index_label='Date')
print(csv)
subprocess.call('plPrice.py '+csv,shell=True)    

