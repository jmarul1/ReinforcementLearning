#!/usr/bin/env python3.7.4

def sclModel(splitParams):
  import re
  params = 'indType,N,W(um),S(um),X(um),Y(um),TL(um),TS(um),Xi(um),Yi(um),Xm(um),Ym(um),other,skew';   reg = "^(n?\d+(?:p\d+)?)"
  dims = list(map(lambda ff: re.search(reg,ff).group(1),splitParams[1:8])); ind = splitParams[0]; skew = splitParams[-1]; other = '_'.join(splitParams[8:-1])
  dims = list(map(lambda ff: ff.replace('p','.').replace('n','-'),dims))
  n,w,s,x,y = list(map(float, dims[0:5])); tempPer = n*w + (n-1)*s
  xI = x - 2*tempPer; yI = y - 2*tempPer; xM = x - tempPer; yM = y - tempPer
  dims.extend(list(map(str, [xI,yI,xM,yM])))
  dims = [ind]+(dims)+[skew]+[other]
  return params,dims 

def mmSclModel(splitParams):
  import re
  params = 'indType,N,W(um),S(um),X(um),Y(um),TL(um),TS(um),skew';   reg = "^(n?\d+(?:p\d+)?)"
  dims = list(map(lambda ff: re.search(reg,ff).group(1),splitParams[1:8])); ind = splitParams[0]; skew = '_'.join(splitParams[8:-1])
  dims = list(map(lambda ff: ff.replace('p','.').replace('n','-'),dims))
  n,w,s,x,y,tl,ts = list(map(float, dims[0:7])); 
  dims = [ind]+(dims)+[skew]
  return params,dims 

def xfmrModel(splitParams):
  import re
  params = 'indType,N,m8W(um),m7W(um),m8Do(um),m7Do(um),TL(um),TS(um),dlt(um),skew';   reg = "^(n?\d+(?:p\d+)?)"
  dims = list(map(lambda ff: (re.search(reg,ff).group(1) if re.search(reg,ff) else ''),splitParams[1:9])); ind = splitParams[0]; other = '_'.join(splitParams[9:-1])
  dims = list(map(lambda ff: ff.replace('p','.').replace('n','-'),dims))
  skew = re.search(r'(tttt|pcff|pcss|prcs|prcf|ffff|ssss|typQ|highQ|lowQ)', '_'.join(splitParams), flags=re.I)
  skew = skew.group(1) if skew else ''
  dims = [ind]+(dims)+[skew]
  return params,dims
  
def testChip(splitParams):
  import re, numtools
  params = 'die,shuttle,dut,deemb,N,S(um),W(um),Dx(um),Dy(um)';  
  die,shuttle = splitParams[0:2] if len(splitParams) != 1 else (' '.join(splitParams),''.join(splitParams));
  test = re.search(r'X(-?\d+|m)Y(-?\d+|m)',die,flags=re.I)
  if test: dut = '_'.join(splitParams[2:-1]); 
  else: ## there is no die
    die = ''; shuttle = splitParams[0]
    test = re.search(r'^([xsi].*?)_((?:tttt|pcff|ffff|ssss|pcss|prcs|prcf|typQ|highQ|lowQ|DE).*)','_'.join(splitParams[1:]),flags=re.I); 
    if not test: return generalCsv(splitParams)
    dut = test.group(1); die = (die+'_'+test.group(2)).strip('_');
  geom = xtractGeom(dut) ## try to get N,S,W,X,Y  
  test = re.search(r'_(de)(\w+)?','_'.join(splitParams),flags=re.I); deemb = 'model'
  if test and test.group(2): deemb = test.group(2)
  elif test and test.group(1): deemb = 'OpSh'
  if re.search(r'_nl',dut,flags=re.I): deemb = 'modelNoleads'; dut = dut.replace('_nl','')
  dims = list(map(str,[die,shuttle,dut,deemb]+geom)    )
  return params,dims

def generalCsv(splitParams):
  import re
  test = re.search(r'(.*)(tttt|pcff|pcss|prcs|prcf|ffff|ssss|typQ|highQ|lowQ)(.*)', '_'.join(splitParams), flags=re.I)
  if test: dims = [(test.group(1)+'_'+test.group(3)).strip('_'),test.group(2)]; params = 'fileBaseName,skew'
  else: dims = ['_'.join(splitParams)]; params = 'fileBaseName'
  return params,dims
  
def xtractGeom(dut):
  import re, numtools; 
  dims = []; dimsMain = []
  for ii in ['n','s','w','x','y','do','di']:
    test = re.search(r'_(n?\d+(?:p\d+)?)'+ii+'_',dut+'_',flags=re.I)
    dims.append(float(test.group(1).replace('p','.')) if test else None)
  for ii in dims[0:5]: dimsMain.append(numtools.numToStr(ii) if ii!=None else '')
  if dims[5] != None: dimsMain[3]=dimsMain[4]=numtools.numToStr(dims[5])
  elif dims[6] != None and all(dimsMain[0:3]): dimsMain[3]=dimsMain[4]=numtools.numToStr(2*(dims[0]*dims[2]+(dims[0]-1)*dims[1])+dims[6])
  return dimsMain
  
def getParamDims(fBaseName):
  import os, re
  try: 
    temp = (fBaseName.split('__')[1]).split('_'); 
    if re.search(r'xfmr',fBaseName): return xfmrModel(temp)
    elif re.search(r'mmind',fBaseName): return mmSclModel(temp)
    else: return sclModel(temp)
  except IndexError: 
    temp = fBaseName.split('_'); return testChip(temp)
  
def getParamValues(inFile,mode,freqD):
  import csvUtils, plotUtils, mathUtils, numtools
  dF = csvUtils.dFrame(inFile); fK = 'Freq(GHz)'; keys = []; results = []; params = []
  if mode in ['diff','both']: keys.append('d')
  if mode in ['se','both']: keys.append('se')
  if mode in ['xfmr']: keys = ['11','22']
  for ii in xrange(len(dF[fK]) if freqD == 'full' else 1):
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
          params += ['Q'+kk+'_'+label+',L'+kk+'_'+label+'(nH)','R'+kk+'_'+label,'SRF'+kk+'(GHz)']
          if jj==1: params += ['k12']
      else:
        lineVals+=list(map(lambda ff: numtools.numToStr(ff,3),[str(Qii),Fii,Ldc,Rdc,srf]))
        if freqD != 'full' or ii == 0: params += ['Q'+kk+'_'+label+',F'+kk+'_'+label+'(GHz),L'+kk+'_'+label+'(nH)','R'+kk+'_'+label+'(Ohms)','SRF'+kk+'(GHz)']
    results.append(lineVals)
  return ','.join(params),results #diff first then se if both

def checkFreq(freq):
  if freq[0].lower() == 'full': return 'full'
  elif freq[0].lower() == 'peak': return 'peak'
  elif len(freq) == 2: return list(map(float,freq))
  else: raise IOError('Bad frequency selection')

def cleanEmptyCols(results):
  import csvUtils
  keys = results[0].split(','); newDt = {}; atleastOneEmpty=False
  temp = csvUtils.strToDict('\n'.join(results))  
  for kk,lst in temp.items():
    if any(lst): newDt[kk] = lst
    else: atleastOneEmpty = True
  if not atleastOneEmpty: return results
  keys = list(filter(lambda ff: ff in newDt.keys(),keys))
  return csvUtils.toStr(newDt,keys,True)

def extractReg(sample,reg):
  import re
  test = re.search(r''+reg,sample,flags=re.I)
  if test and len(test.groups())>0:
    labels = vals = ''
    for ii,gg in enumerate(test.groups()):
      labels += ',ext'+str(ii); vals += ','+test.group(ii+1)  
    return [labels,vals]
  else: return ['','']
  
def mainExe(argLst=None):
  ## ARGS ##
  import sys, os, re; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); 
  import plotRF, argparse, itertools, csvUtils
  argparser = argparse.ArgumentParser(description='Creates Param list (DcL,Qpeak,DcR) based on CSV')
  argparser.add_argument(dest='input',type=plotRF.targetFiles, nargs ='+',help='Input files')
  argparser.add_argument('-mode', dest='mode', choices=['diff','se','both','xfmr'], default = 'diff', help='Differential, Single Ended, Both (only applies to Inductors)')
  argparser.add_argument('-freq', dest='freq', nargs='+', default = ['full'], help='Freq in GHz and tolerance or "full" for all frequencies or "peak"')
  argparser.add_argument('-extract', dest='reg', help='Regular expresion to extract from the filename')
  args = argparser.parse_args(argLst);
  ## MAIN ##
  if args.freq: args.freq = checkFreq(args.freq)
  lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();   
  results = []
  for iiFile in lstFiles:
    effName = re.sub(r'(_QC|_QL)$','',os.path.basename(os.path.splitext(iiFile)[0]));
    extLabels,extVals = extractReg(effName,args.reg) if args.reg else ['','']
    if re.search(r'xfmr',effName): args.mode = 'xfmr' ## is it a transformer
    params,paramValsLst = getParamValues(iiFile,args.mode,args.freq)   
    dims,dimVals = getParamDims(effName)
    for paramVals in paramValsLst:  
      results.append(','.join(dimVals+paramVals+[effName])+extVals)
  results.insert(0,dims+','+params+',fileName'+extLabels);
  results = cleanEmptyCols(results)
  ## print ##
  if __name__ == '__main__':  print( '\n'.join(results)); # print
  else: return results

if __name__ == '__main__':
  mainExe()

#print 123
