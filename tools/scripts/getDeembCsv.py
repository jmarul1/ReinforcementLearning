#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def getParamDims(fBaseName):
  import os, re, numtools
  params = 'die,shuttle,dut'; splitParams = fBaseName.split('_')    
  die,shuttle = splitParams[0:2]
  dut = '_'.join(splitParams[2:]); 
  dims = map(str,[die,shuttle,dut])    
  return params,dims
  
def getParamValues(inFile,mode='diff'):
  import csvUtils, plotUtils, mathUtils, numtools
  dF = csvUtils.dFrame(inFile); fK = 'Freq(GHz)'; label='full'; keys = []; results = []; params = [fK]
  if mode in ['diff','both']: keys.append('d')
  if mode in ['se','both']: keys.append('se')
  for ii in xrange(len(dF[fK])):
    Fii = dF[fK][ii];       
    lineVals = [Fii];
    for jj,kk in enumerate(keys):
      Q = dF[plotUtils.getPltKeys('Q'+kk)[0]][ii]
      L = dF[plotUtils.getPltKeys('L'+kk)[0]][ii] if plotUtils.getPltKeys('L'+kk)[0] in dF.keys() else ''
      C = dF[plotUtils.getPltKeys('C'+kk)[0]][ii] if plotUtils.getPltKeys('C'+kk)[0] in dF.keys() else ''
      R = dF[plotUtils.getPltKeys('R'+kk)[0]][ii]; 
      ## store them 
      lineVals+=map(lambda ff: numtools.numToStr(ff,3),[Q,L,C,R])
      if ii == 0: params += ['Q'+kk+'_'+label+',L'+kk+'_'+label+'(nH),C'+kk+'_'+label+'(fF),R'+kk+'_'+label+'(Ohms)']      
    results.append(lineVals)
  return ','.join(params),results #diff first then se if both

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
  
def mainExe(argLst=None):
  ## ARGS ##
  import sys, os, re; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); 
  import plotRF, argparse, itertools, csvUtils
  argparser = argparse.ArgumentParser(description='Creates Param list (DcL,Qpeak,DcR) based on CSV')
  argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
  args = argparser.parse_args(argLst);
  ## MAIN ##
  lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();   
  results = []
  for iiFile in lstFiles:
    effName = re.sub(r'(_QC|_QL)$','',os.path.basename(os.path.splitext(iiFile)[0]))
    params,paramValsLst = getParamValues(iiFile)   
    dims,dimVals = getParamDims(effName)
    for paramVals in paramValsLst:  
      results.append(','.join(dimVals+paramVals+[effName]))      
  results.insert(0,dims+','+params+',fileName');
  results = cleanEmptyCols(results)
  ## PRINT ##
  if __name__ == '__main__':  print '\n'.join(results)
  else: return results

if __name__ == '__main__':
  mainExe()
