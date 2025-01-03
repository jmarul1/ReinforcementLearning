#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def getParamDims(fBaseName):
  import os, re
  splitParams = (fBaseName.split('__')[1]).split('_'); 
  params = 'indType,N,m8W(um),m7W(um),m8Do(um),m7Do(um),TL(um),TS(um),dlt(um)';   reg = "^(n?\d+(?:p\d+)?)"
  dims = map(lambda ff: (re.search(reg,ff).group(1) if re.search(reg,ff) else ''),splitParams[1:9]); ind = splitParams[0]; other = '_'.join(splitParams[9:-1])
  dims = map(lambda ff: ff.replace('p','.').replace('n','-'),dims)
  skew = re.search(r'(tttt|pcff|pcss|prcs|prcf|ffff|ssss|typQ|highQ|lowQ)', '_'.join(splitParams), flags=re.I)
  skew = skew.group(1) if skew else ''
  dims = [ind]+(dims)
  return params,dims

def getSRF(csv):
  freq,k1,k2 = csv.keys()[0],csv.keys()[1],csv.keys()[5]
  srf = '>'+csv[freq][-1]
  for ii in range(1,len(csv[k1])):
    if float(csv[k1][ii-1]) > 0 and float(csv[k1][ii]) < 0: srf = csv[freq][ii]; break
  return srf  

   
## ARGS ##
import sys, os, re; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); 
import plotRF, argparse, itertools, csvUtils
argparser = argparse.ArgumentParser(description='Summarize lumped XFMR elements')
argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
args = argparser.parse_args();
## MAIN ##
lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();   
results = []
for iiFile in lstFiles:
  effName = re.sub(r'(_QC|_QL)$','',os.path.basename(os.path.splitext(iiFile)[0]));
  csv = csvUtils.dFrame(iiFile); keys = ','.join(csv.keys()); srf = getSRF(csv)
  dims,dimVals = getParamDims(effName)
  for ii,freq in enumerate(csv[csv.keys()[0]]):
    values = [csv[kk][ii] for kk in csv.keys()]  
    results.append(','.join(dimVals+values+[srf,effName]))
results.insert(0,dims+','+keys+',srf(GHz),fileName');
## PRINT ##
print '\n'.join(results)
