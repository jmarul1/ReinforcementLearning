#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
 
def getParamValues(inFile,mode,freqD):
  import csvUtils, plotUtils, mathUtils, numtools
  dF = csvUtils.dFrame(inFile); fK = 'Freq(GHz)'; keys = []; results = []; params = []
  if mode in ['diff','both']: keys.append('d')
  if mode in ['se','both']: keys.append('se')
  if mode in ['xfmr']: keys = ['11','22']
  for ii in range(len(dF[fK]) if freqD == 'full' else 1):
    lineVals = []
    for jj,kk in enumerate(keys):
      Q = list(map(float,dF[plotUtils.getPltKeys('Q'+kk)[0]])); srfI = mathUtils.getNegZeroInt(Q)
      R = list(map(float,dF[plotUtils.getPltKeys('R'+kk)[0]]))
      ## get the correct SRF
      if srfI == False: srfI = len(Q); srf = '>'+numtools.numToStr(dF[fK][srfI-1],1);  #use the max value
      else: srf = dF[fK][srfI]; #use the SRF 
      ## peak, full, or a point for freq points
      if freqD == 'full': label = 'full';  # keep the outer ii index
      elif freqD == 'peak': Qpeak = max(Q[0:srfI]); ii = Q.index(Qpeak); label = 'peak'
      else: ii = numtools.closestNum(list(map(float,dF[fK]),freqD[0],freqD[1])); label = '@'+numtools.numToStr(freqD[0])+'G'
      ## get the values if they exist for either inductors or transformers
      if ii < 0: Ldc = Rdc = Fpeak = Qpeak = 'NA'
      elif mode == 'xfmr': Ldc = dF[plotUtils.getPltKeys('L'+kk)[0]][ii]; Fii = dF[fK][ii]; Qii = Q[ii]; k12 = dF['k12'][ii]; Rii=R[ii]
      else: Ldc = dF[plotUtils.getPltKeys('L'+kk)[0]][ii]; Fii = dF[fK][ii]; Qii = Q[ii]; Rdc = dF[plotUtils.getPltKeys('R'+kk)[0]][ii]; 
      ## store them 
      if mode == 'xfmr':
        if jj == 0: lineVals+=[numtools.numToStr(Fii)]; 
        lineVals+=list(map(lambda ff: numtools.numToStr(ff,3),[str(Qii),Ldc,str(Rii),srf]))
        if jj == 1: lineVals+=[numtools.numToStr(k12,3)]
        if freqD != 'full' or ii == 0: 
          if jj==0: params += ['Freq_'+label+'(GHz)'];
          params += ['Q'+kk+'_'+label,'L'+kk+'_'+label+'(nH)','R'+kk+'_'+label,'SRF'+kk+'(GHz)']
          if jj==1: params += ['k12']
      else:
        lineVals+=list(map(lambda ff: numtools.numToStr(ff,3),[Fii,str(Qii),Ldc,Rdc,srf]))
        if freqD != 'full' or ii == 0: params += ['F'+kk+'_'+label+'(GHz)','Q'+kk+'_'+label,'L'+kk+'_'+label+'(nH)','R'+kk+'_'+label+'(Ohms)','SRF'+kk+'(GHz)']
    results.append(lineVals)
  return params,results #diff first then se if both

def checkFreq(freq):
  if freq[0].lower() == 'full': return 'full'
  elif freq[0].lower() == 'peak': return 'peak'
  elif len(freq) == 2: return list(map(float,freq))
  else: raise IOError('Bad frequency selection')

def extractReg(sample,reg):
  import re
  test = re.search(r''+reg,sample,flags=re.I)
  if test and len(test.groups())>0:
    labels = []; vals = []; dt = test.groupdict()
    for ii,gg in enumerate(test.groups()):
      label = [kk for kk,val in dt.items() if val == gg] 
      labels.append(label[0] if label else ('ext'+str(ii))); vals.append(gg)
    return labels,vals
  else: return [],[]

def trimVals(df,freq):
  from sparameter.sparamUtils import getIndSRF
  srf = getIndSRF(df['Fd_full(GHz)'],df['Qd_full'])
  if srf[0] == False: return df
  srfIndex = min(len(df),srf[1]+1)  
  return df.iloc[0:srfIndex,:]
  
def mainExe(argLst=None):
  ## ARGS ##
  import sys, os, re, plotRF, argparse, itertools, csvUtils, namedecipher, pandas as pd; from sparameter.sparamUtils import getIndSRF
  argparser = argparse.ArgumentParser(description='Creates Param list (DcL,Qpeak,DcR) based on CSV')
  argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
  argparser.add_argument('-mode', dest='mode', choices=['diff','se','both','xfmr'], default = 'diff', help='Differential, Single Ended, Both (only applies to Inductors)')
  argparser.add_argument('-freq', dest='freq', nargs='+', default = ['full'], help='Freq in GHz and tolerance or "full" for all frequencies or "peak"')
  argparser.add_argument('-extract', dest='reg', help='Regular expresion to extract from the filename')
  args = argparser.parse_args(argLst);
  ## MAIN ##
  if args.freq: args.freq = checkFreq(args.freq)
  lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();   
  results = pd.DataFrame()
  for iiFile in lstFiles:
    effName = os.path.basename(os.path.splitext(iiFile)[0]);
    extLabels,extVals = extractReg(effName,args.reg) if args.reg else ([],[])
    if re.search(r'xfmr',effName): args.mode = 'xfmr' ## is it a transformer
    params,paramValsLst = getParamValues(iiFile,args.mode,args.freq)   
    dims,dimVals = namedecipher.getParamDims(effName)
    current = pd.DataFrame(paramValsLst,columns=params); current = trimVals(current,args.freq)
    for dim,dimVal in zip(dims,dimVals): current[dim] = dimVal
    for extLabel,extVal in zip(extLabels,extVals): current[extLabel] = extVal
    results = pd.concat([results,current])
  ## OUTPUT ##
  if __name__ == '__main__':  print(results.to_csv(index=False)); # print
  else: return results

if __name__ == '__main__':
  mainExe()
