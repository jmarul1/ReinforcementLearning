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
#  lowess(x, y, span=2/3., iter=3)
#  lowess smoother is a locally weighted regression. It fits a nonparametric regression curve 
#  to a scatterplot like the ones in the RF LAB
#  x and y should be the same length. span is the size of the data
#  The return value is the smooth y
#
##############################################################################

def loess(x,y,span=0.6,iteration=3): 
  import numpy
  elements = len(x) 
  radius = int(numpy.ceil(span*elements)) 
  height = [numpy.sort(abs(x-x[ii]))[radius] for ii in range(elements)] 
  width = numpy.clip(abs(([x] - numpy.transpose([x])) / height), 0, 1) 
  width = (1 - width**3)**3
  smooth = numpy.zeros(elements) 
  delta = numpy.ones(elements) 
  for ronda in range(iteration): 
    for ii in range(elements): 
      weights = delta*width[:, ii] 
      weightsMultX = weights*x 
      b1 = numpy.dot(weights, y) 
      b2 = numpy.dot(weightsMultX, y) 
      A11 = sum(weights) 
      A12 = sum(weightsMultX) 
      A21 = A12 
      A22 = numpy.dot(weightsMultX, x) 
      determinant = A11*A22 - A12*A21 
      beta1 = (A22*b1 - A12*b2) / determinant 
      beta2 = (A11*b2 - A21*b1) / determinant 
      smooth[ii] = beta1 + beta2*x[ii] 
    residuals = y - smooth
    sobra = numpy.median(abs(residuals)) 
    delta[:] = numpy.clip(residuals / (6*sobra), -1, 1) 
    delta[:] = 1 - delta * delta 
    delta[:] = delta * delta 
  return smooth

def RLoess(x,y,span=0.4,iteration=3):
  import tempfile,subprocess
  tmpInCsvF = tempfile.mkstemp(suffix='.csv')[1]
  with open(tmpInCsvF,'w') as fId:
    for xR,xY in zip(x,y): fId.write(','.join([str(xR),str(xY)])+'\n')
  tmpRF = tempfile.mkstemp(suffix='.R')[1]
  tmpOutCsvF = tempfile.mkstemp(suffix='.csv')[1]
  with open(tmpRF,'w') as fId:
    fId.write('\
dataF <- read.csv("'+tmpInCsvF+'",header=FALSE); xLst <- dataF[,1]; yLst <- dataF[,2]\n\
result<- lowess(xLst,yLst,f='+str(span)+',iter='+str(iteration)+')\n\
write(result$y,file="'+tmpOutCsvF+'",ncolumns=1)')
  test=subprocess.Popen('R -f '+tmpRF,stderr=subprocess.PIPE, stdout=subprocess.PIPE,shell=True)
  test.communicate()
  if test.returncode: raise RuntimeError('Problem with the R file: '+tmpRF)
  with open(tmpOutCsvF) as fId: result = map(str.strip, fId.readlines())    
  subprocess.call('rm '+tmpInCsvF+' '+tmpRF+' '+tmpOutCsvF,shell=True)
  return map(float,result)

#import smooth, numpy
#x = numpy.array([4,  4,  7,  7,  8,  9, 10, 10, 10, 11, 11, 12, 12, 12, 
#12, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 16, 16, 
#17, 17, 17, 18, 18, 18, 18, 19, 19, 19, 20, 20, 20, 20, 
#20, 22, 23, 24, 24, 24, 24, 25], numpy.float)
 
#y = numpy.array([2, 10,  4, 22, 16, 10, 18, 26, 34, 17, 28, 14, 20, 24, 
#28, 26, 34, 34, 46, 26, 36, 60, 80, 20, 26, 54, 32, 40, 
#32, 40, 50, 42, 56, 76, 84, 36, 46, 68, 32, 48, 52, 56, 
#64, 66, 54, 70, 92, 93, 120, 85], numpy.float) 
#result = smooth.loess(x, y) 
#len(result) 
#import pylab as plt
#plt.plot(x,y,color='k')
#plt.hold(True)
#plt.plot(x,result,color='red')
#plt.show()
