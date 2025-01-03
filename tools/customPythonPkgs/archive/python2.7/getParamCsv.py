#!/usr/bin/env python3.7.4
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

def getParam(inFile,freq,params,tolerance):
  import csvUtils, numtools
  dF = csvUtils.dFrame(inFile)
  fK = 'Freq(GHz)'
  ii = numtools.closestNum(map(float,dF[fK]),float(freq),tolerance); 
  if ii >= 0 : out=','.join(dF[pp][ii] for pp in params)
  else: out=','.join('Invalid Freq' for pp in params)
  return out

def mainExe(argLst=None):
  ## ARGS ##
  import sys, os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); 
  import re, plotUtils, numtools, argparse, plotRF, itertools, tempfile
  argparser = argparse.ArgumentParser(description='Creates Param list based on CSV')
  argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
  argparser.add_argument('-param', dest='param', nargs='+', required=True, help='What to extract')
  argparser.add_argument('-freq', dest='freq', nargs=2, type = float, default = [0.5, 0.5], help='Freq in GHz and tolerance')
  argparser.add_argument('-tol', dest='tol', default = 1e-9, help='How close to the Freq in GHz')
  args = argparser.parse_args(argLst);

  ## MAIN ##
  lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();  
  params = args.param  #  params = map(lambda ff: plotUtils.getPltKeys(ff)[0], args.param)
  results=['FileBaseName,'+','.join(map(lambda ff: ff+'@'+str(args.freq[0])+'G',params))]
  for iiFile in lstFiles:
    effName = os.path.basename(os.path.splitext(iiFile)[0]).rstrip('_QC').rstrip('_QL')
    results.append(effName+','+getParam(iiFile,args.freq[0],params,args.freq[1]))
  if __name__ == '__main__':  print '\n'.join(results)
  else: return results

if __name__ == '__main__':
  mainExe()
