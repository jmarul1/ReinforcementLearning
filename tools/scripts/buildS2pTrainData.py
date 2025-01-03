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
##############################################################################
import sys,os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import warnings
warnings.simplefilter("ignore")    
##############################################################################

#!/usr/bin/env python3.7.4

def mmSclModel(splitParams):
  import re
  params = 'indType,N,W(um),S(um),X(um),Y(um),TL(um),TS(um),skew';   reg = "^(n?\d+(?:p\d+)?)"
  dims = list(map(lambda ff: re.search(reg,ff).group(1),splitParams[1:8])); ind = splitParams[0]; skew = '_'.join(splitParams[8:-1])
  dims = list(map(lambda ff: ff.replace('p','.').replace('n','-'),dims))
  n,w,s,x,y,tl,ts = list(map(float, dims[0:7]))
  dims = [ind]+(dims)+[skew]
  return params,dims 
  
def getParamDims(fBaseName):
  import os, re
  try: 
    temp = (fBaseName.split('__')[1]).split('_'); 
    if re.search(r'mmind',fBaseName): return mmSclModel(temp)
    else: return sclModel(temp)
  except IndexError: 
    temp = fBaseName.split('_'); return testChip(temp)

def createPdDF(spObj):
  import pandas as pd, numpy
  lambda ff: ff
  matrix = [];   columns=numpy.array([('s'+str(row)+str(col)+'r','s'+str(row)+str(col)+'i') for row in sp.data[0].keys() for col in sp.data[0].keys()]).flat;
  for iiF in range(len(spObj.data)): 
    temp = [(spObj.data[iiF][row][col].real,spObj.data[iiF][row][col].imag) for row in spObj.data[iiF].keys() for col in spObj.data[iiF].keys()]
    matrix.append(numpy.array(temp).flat)
  dFSp = pd.DataFrame(matrix,columns=columns);  QLR = spObj.getQLR();
  dFQL = pd.DataFrame(numpy.stack([spObj.freq,QLR[0],QLR[1],QLR[4]],axis=1),columns=['Fd_full(GHz)','Qd_full','Ld_full(nH)','Rd_full(Ohms)'])
  dF = pd.concat([dFQL,dFSp],axis=1)
  return dF
       
## ARGS ##
import sys, os, re, argparse, itertools, sparameter, pandas as pd
argparser = argparse.ArgumentParser(description='Creates Training List with Dimes, Q,L,sparams')
argparser.add_argument(dest='input', nargs ='+',help='S2P Input files')
argparser.add_argument('-csv', dest='csvFile', const='fullSpData.csv', nargs='?', help='output file fullSpData.csv/[givenName]')
args = argparser.parse_args();
## MAIN ##
fullCsvDf = pd.DataFrame()
for iiFile in args.input:
  effName = re.sub(r'(_QC|_QL)$','',os.path.basename(os.path.splitext(iiFile)[0]));
  dims,dimVals = getParamDims(effName)
  sp = sparameter.read(iiFile)
  valDf = createPdDF(sp)   ## convert SPData to Pandas Matrix
  dimDf = pd.DataFrame([dimVals],columns=dims.split(',')); dimDf = pd.concat([dimDf]*len(sp.freq),ignore_index=True)  # Attach Dims
  csvDf = pd.concat([dimDf,valDf],axis=1)
  ## append to full one
  fullCsvDf = fullCsvDf.append(csvDf)
if args.csvFile: fullCsvDf.to_csv(args.csvFile,index=False); print("Wrote: "+args.csvFile)
else: print(fullCsvDf)

