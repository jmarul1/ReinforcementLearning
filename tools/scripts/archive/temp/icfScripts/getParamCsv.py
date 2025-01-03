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

def getParam(inFile,freq,params):
  import csvUtils
  dF = csvUtils.dFrame(inFile)
  fK = 'Freq(GHz)'
  if freq in dF[fK]: ii=dF[fK].index(freq); out=','.join(dF[pp][ii] for pp in params)
  else: out=','.join('Invalid Freq' for pp in params)
  return out

def mainExe(argLst=None):
  ## ARGS ##
  import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python'); 
  import os, re, plotUtils, numtools, argparse, plotRF, itertools, tempfile
  inChoices = ['Qd','Ld','Qse','Lse','Cd','Cse','Rd','Rse']
  argparser = argparse.ArgumentParser(description='Creates Param list based on CSV')
  argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
  argparser.add_argument('-param', dest='param', nargs='+', choices=inChoices, default = ['Cd'], help='What to extract')
  argparser.add_argument('-freq', dest='freq', default = '0.5', help='Freq in GHz (must exist)')
  args = argparser.parse_args(argLst);

  ## MAIN ##
  lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();  
  params = map(lambda ff: plotUtils.getPltKeys(ff)[0], args.param)

  results=['FileBaseName,'+','.join(map(lambda ff: ff+'@'+args.freq+'G',params))]
  for iiFile in lstFiles:
    effName = os.path.basename(os.path.splitext(iiFile)[0]).rstrip('_QC')
    results.append(effName+','+getParam(iiFile,args.freq,params))
  if __name__ == '__main__':  print '\n'.join(results)
  else: return results

if __name__ == '__main__':
  mainExe()
