#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2016, Intel Corporation.  All rights reserved.               #
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
#   Type >> getUpfModels.py -h 
##############################################################################
 
def mainExe(args):
  import os, re
  ## Read the UPFs
  modelsStr = {}; model=False; output = {};
  for modelFile,tipo in args.inModel:
    effName = os.path.basename(os.path.realpath(modelFile))
    skewP,modelP = ('(?:\+\+\+|.lib)','(?:.?model.*?|\.subckt\s+)') if tipo == '.upf' else ('section','(?:subckt|model)\s+')
    model = skew = False
    with open(modelFile) as fin:
      outStr = ['## '+effName]
      for line in fin:
        if re.search(r'^\s*$|^\s*\*',line): continue #skip comments or empty lines
        line = line.strip();
	## find the skew
	test = re.search(r'^'+skewP+'\s*(\w+)',line)
	if test: skew = test.group(1); modelsStr[skew] = {}; continue
	## if there is a skew start looking for models
	if skew:
	  ## extract the model
	  test = re.search(r'^'+modelP+'(\w+)(.*)',line,flags=re.I)
	  if test:
#	    if tipo == '.upf' and not re.search(r'numPorts',line): continue
	    model = test.group(1); props = test.group(2).strip()
	    modelsStr[skew][model] = {'content':[],'props':props}; continue
	  ## append the lines of the model
	  if re.search(r'^ends?',line,flags=re.I): model = False
	  if model: modelsStr[skew][model]['content'].append(line)    ## All information is in the modelsStr[skew][model] = [lines]	  
    ## print only the models requested	  
    for skew,modelDt in modelsStr.items():
      if args.skew==False or re.search(r''+args.skew,skew):
        for model,info in modelDt.items():
          ## decide if model is to be printed
	  if args.model==False or re.search(r''+args.model,model):
            outStr.append('skew='+skew+' model='+model+' props='+info['props'])
	    if args.content: outStr.append(('\n'.join(info['content']))+'\n')
    output[effName] = outStr
  return output  

def getDetails(path):
  import os
  if not os.path.isfile(path): raise IOError('Path does not exist: '+path)
  ext = os.path.splitext(path)[1]
  if ext in ['.upf','.scs']: return os.path.relpath(path),ext
  else: raise IOError('Only SCS or UPF supported: '+path)
  
if __name__ == '__main__':
  import sys, os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
  import re, argparse
  ## Argument Parsing
  argparser = argparse.ArgumentParser(description='Gets all models inside upf/scs')
  argparser.add_argument(dest='inModel', nargs='+', help='UPF/SCS file(s)', type=getDetails)
  argparser.add_argument('-model', dest='model', default = False, help='RegExp to match model')
  argparser.add_argument('-skew', dest='skew', default = False, help='Specific skew')
  argparser.add_argument('-content',dest='content',action='store_true')       
  args = argparser.parse_args()
  output = mainExe(args)
  for upf,content in output.items():
    print '\n'.join(content)
