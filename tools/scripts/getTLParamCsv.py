#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
  
def getParamDims(fBaseName):
  import os, re, collections
  dims = collections.OrderedDict()
  for pp in ['w','l','s']:
    test = re.search(r'(\d+(p\d+)?)'+pp,fBaseName)
    if test: dims[pp+'(um)'] = float(test.group(1).replace('p','.'))
    else: dims[pp+'(um)'] = ''
  return dims
  
def getParamValues(inFile,dims):
  import csvUtils, plotUtils, mathUtils, numtools
  dF = csvUtils.dFrame(inFile); params = dims.keys()+dF.keys(); results = []
  for ii in xrange(len(dF['Freq(GHz)'])):
    lineVals = [numtools.numToStr(val) for dim,val in dims.items()]; 
    for kk in dF.keys():lineVals+=[numtools.numToStr(dF[kk][ii])]
    results.append(lineVals)
  return params,results

def cleanEmptyCols(results):
  import csvUtils
  keys = results[0].split(','); newDt = {}; atleastOneEmpty=False
  temp = csvUtils.strToDict('\n'.join(results))  
  for kk,lst in temp.items():
    if any(lst): newDt[kk] = lst
    else: atleastOneEmpty = True
  if not atleastOneEmpty: return results
  keys = filter(lambda ff: ff in newDt.keys(),keys)
  return csvUtils.toStr(newDt,keys,True)
  
## ARGS ##
import sys, os, re; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'));
import csvUtils, itertools, plotRF, argparse
argparser = argparse.ArgumentParser(description='Creates Param list based on CSV')
argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
args = argparser.parse_args();
## MAIN ##
lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();   
results = []
for iiFile in lstFiles:
  effName = re.sub(r'(_TL)$','',os.path.basename(os.path.splitext(iiFile)[0]))  
  dims = getParamDims(effName)
  params,paramValsLst = getParamValues(iiFile,dims)
  for paramVals in paramValsLst:  
    results.append(','.join(paramVals+[effName]))
results.insert(0,','.join(params)+',fileName'); #results = cleanEmptyCols(results)
## PRINT ##
print '\n'.join(results)
