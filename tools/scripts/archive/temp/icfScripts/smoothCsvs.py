#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret							     #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.  	     #
#									     #
# This is the property of Intel Corporation and may only be utilized	     #
# pursuant to a written Restricted Use Nondisclosure Agreement  	     #
# with Intel Corporation.  It may not be used, reproduced, or		     #
# disclosed to others except in accordance with the terms and		     #
# conditions of such agreement. 					     #
#									     #
# All products, processes, computer systems, dates, and figures 	     #
# specified are preliminary based on current expectations, and are	     #
# subject to change without notice.					     #
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################


def getSmoothDf(inFile):
  import csvUtils,smooth
  dF = csvUtils.dFrame(inFile)
  outDf = {args.x:dF[args.x]}; yKeys = filter(lambda ff: ff!=args.x, dF.keys())
  for key in yKeys: outDf[key] = smooth.RLoess(dF[args.x],dF[key],span=args.span,iteration=args.iter)
  return csvUtils.toStr(outDf,givenKeys=[args.x]+yKeys)
  
## ARGS ##
import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python'); 
import os, re, plotUtils, numtools, argparse, plotRF, itertools, tempfile
argparser = argparse.ArgumentParser(description='Smoth all the values in the CSV except for the Freq(GHz) column')
argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
argparser.add_argument('-span',dest='span',default=0.3,help='span')
argparser.add_argument('-iteration',dest='iter',default=4,help='iteration')
argparser.add_argument('-xkey',dest='x',default='Freq(GHz)',help='X key from the CSV for smoothing'); 
args = argparser.parse_args();

## MAIN ##
lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();  

for iiFile in lstFiles:
  effName = os.path.basename(os.path.splitext(iiFile)[0])+'_smooth.csv'
  newCsvStr = getSmoothDf(iiFile)
  with open(effName,'wb') as fout: fout.write(newCsvStr)

