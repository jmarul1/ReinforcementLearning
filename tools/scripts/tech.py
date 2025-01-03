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
# Description:
#   Type >> tech.py -h 
##############################################################################

def clean(inVal):
  import numtools
  if numtools.isNumber(inVal): return str(int(inVal))
  else: return str(inVal)

def checkInputs(lpp):
  import numtools, argparse,re
  test = list(map(numtools.isNumber, lpp)) 
  if all(test): ## we got numbers
    if len(test) > 2: raise argparse.ArgumentTypeError('Numerical inputs are limited to TWO')
    elif len(test) == 1: rval = lpp+['0']
    else: rval = lpp
  elif not any(test): ## we got alpha
    if len(test) > 3: raise argparse.ArgumentTypeError('Alpha inputs are limited to THREE')
    elif any([re.search('boundary',ff,flags=re.I) for ff in lpp]): rval=['']+lpp
    elif len(test) == 1: rval = lpp+['drawing'] 
    else: rval=lpp
  else: raise argparse.ArgumentTypeError('Inputs must be either only numerical or alpha values')
  return rval
  
def readTechLayer(techFile):
  ''' read the layer map from the env '''
  import os, re, numtools
  keys = ['layer','purpose','stmlay','stmdat'] #if typeMap=='layermap' else ['object','purpose','layer','stmlay','stmdat']
  print(techFile)
  with open(techFile) as fIn:
    dataF = {};
    for ii in keys: dataF[ii]=[]
    for line in fIn:
      if not re.search(r'^\s*#|^\s*/\s*\*|^\s*//|^\s*$',line): #ignore empty lines or beginning with #
        line = (re.split(r'#',line)[0]).strip() #ignore anything after #
        entries = re.split(r'\s+',line); jj=0
        checkLst = keys[:]
        for ii,value in enumerate(entries):
          if ii >= len(keys): break
          if not numtools.isNumber(value): dataF[keys[ii]].append(value); checkLst.pop(checkLst.index(keys[ii]))
          else: dataF[keys[-2+jj]].append(value); checkLst.pop(checkLst.index(keys[-2+jj])); jj+=jj+1
        for jj in checkLst: dataF[jj].append('')  ## keys that were not stored
  return keys, dataF
  
def findPair(lppObj,lppDict,keys):
  import numtools
  lpp = lppObj[:]
  if len(keys) == 4: #layermap
    if len(lpp) > 2: lpp.pop(-1)
    if numtools.isNumber(lpp[0]): szip = ((lppDict[ii]) for ii in keys[-2:]); kLst = keys[:2]
    else: szip = ((lppDict[ii]) for ii in keys[:2]); kLst = keys[-2:]
  else: # objectmap
    if numtools.isNumber(lpp[0]): szip = ((lppDict[ii]) for ii in keys[-2:]); kLst = [keys[2],keys[0],keys[1]]
    else: szip = ((lppDict[ii]) for ii in (keys[2],keys[0],keys[1])); kLst = keys[-2:]
  result = ['NotFound']
  for ii,ssLst in enumerate(list(zip(*szip))):
    if 'x'.join(map(str.lower,ssLst)) == 'x'.join(map(str.lower,lpp)):
      result = [lppDict[kk][ii] for kk in kLst]; break
  return result
    
def mainExe(arguments=None):  
  import sys, os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
  import numtools, argparse, layout
  defTechFile = layout.getTechFile()[0]
  print("TECH FILES:\n"+defTechFile)
  argparser = argparse.ArgumentParser(description='Gets the lpp or name depending on the inputs')
  argparser.add_argument(dest='input', nargs='+', type=clean, help='LayerPurposePair+[objectType] or StmLay StmDat')
  argparser.add_argument('-layer', dest='layer', type=os.path.realpath, default = defTechFile, help='techfile')
  args = argparser.parse_args()
  ## search in the layermap and objectmap
  lppIn = checkInputs(args.input)
  for ii in [args.layer]:
    keys,techDict = readTechLayer(ii)
    result = findPair(lppIn,techDict,keys) 
    if result[0] != 'NotFound': break
  result = '('+','.join(result)+')'
  ## return or print  
  if __name__ == '__main__': print(result)
  else: return result
  
if __name__ == '__main__':
  mainExe()
  
