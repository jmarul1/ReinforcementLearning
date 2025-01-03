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
  import re, numtools; from . import generalCsv
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
