#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
  
def getParamDims(fBaseName):
  import os, re, numtools
  test = re.search('(\d+)nx.*?(\d+)ny.*?(tttt|pcff|pcss|prcs|prcf|ffff|ssss)',fBaseName)      
  if test:
    params = 'nx,ny,skew,area';   
    nx = float(test.group(1)); ny = float(test.group(2)); skew = test.group(3)
    area = (ny*4.5)*(nx*0.8+(nx-1)*2+0.4+0.4)
    dims = map(numtools.numToStr,[nx,ny,skew,area])
  else:
    params = ['baseName']; dims=[fBaseName]; area=False
  return params,dims
  
def getParamValues(inFile,freqD):
  import csvUtils, plotUtils, mathUtils, numtools, re
  dF = csvUtils.dFrame(inFile);  fK = 'Freq(GHz)'; results = [];
  if freqD != 'full': 
    if freqD == None: freqD = [float(dF[fK][0]),0.1]  # choose the dc point (assume first point)
    rng = [numtools.closestNum(map(float,dF[fK]),freqD[0],freqD[1])]; label = '@'+numtools.numToStr(freqD[0])+'G' 
  else: rng = xrange(len(dF[fK]));
  ## run for specified frequency(s)
  for ii in rng: results.append([numtools.numToStr(dF[kk][ii],3,exp=True if re.search(r'^Y',kk) else False) for kk in dF.keys()])
  return ','.join(dF.keys()),results #diff first then se if both

def checkFreq(freq):
  if freq[0].lower() == 'full': return 'full'
  elif len(freq) == 2: return map(float,freq)
  else: raise IOError('Bad frequency selection')

def mainExe(argLst=None):
  ## ARGS ##
  import sys, os, re; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); 
  import plotRF, argparse, itertools, csvUtils
  argparser = argparse.ArgumentParser(description='Creates Param list (DcC,DcQ,DcR) based on CSV')
  argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
  argparser.add_argument('-freq', dest='freq', nargs='+', help='Freq in GHz and tolerance or "full" for all frequencies')
  args = argparser.parse_args(argLst);
  ## MAIN ##
  if args.freq: args.freq = checkFreq(args.freq)
  lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();   
  results = []
  for iiFile in lstFiles:
    effName = re.sub(r'(_QC)$','',os.path.basename(os.path.splitext(iiFile)[0]))
    dims,dimVals = getParamDims(effName)
    params,paramValsLst = getParamValues(iiFile,args.freq)
    for paramVals in paramValsLst:     
      results.append(','.join(dimVals+paramVals+[effName]))
  results.insert(0,dims+','+params+',fileName');
  ## PRINT ##
  if __name__ == '__main__':  print '\n'.join(results)
  else: return results

if __name__ == '__main__':
  mainExe()
