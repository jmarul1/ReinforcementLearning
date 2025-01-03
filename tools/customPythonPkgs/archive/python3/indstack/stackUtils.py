
def getViaOffset(via,metals):
  import re,os
  prefix = 'tm' if re.search(r'^t|g',via) else 'm'
  metal = via.replace('v','m')
  if re.search(r'tv1|siv',via): metal = metals.keys()[1] #assume metals start from the top
  if re.search(r'tva',via): metal = metals.keys()[3] # for p1231 assign m2
  return float(metals[metal][0])+float(metals[metal][1])
  
def getMVTable(dt,offGuide=False,PR=None):
  import re, layout; from numtools import numToStr as n2s
  outLst = [];
  for layer in dt.keys()[::-1]:  
    if re.search(r'tf',layer,flags=re.I): continue
    bot = getViaOffset(layer,offGuide) if offGuide else float(dt[layer][0]);
    tc = float(dt[layer][1])
    top = bot+tc;
    outLst.append(','.join([layer,n2s(bot,PR),n2s(top,PR),n2s(tc,PR),'1',n2s(dt[layer][2],PR,True)] ))
  outLst.reverse()
  return outLst

def getOxides(dt,mComp,skip='0',PR=None):
  import re, layout; from numtools import numToStr as n2s
  bLayer = 'first'; outLst=[]; skip= len(filter(lambda ff: re.search(r'oxide|c4|si',ff,flags=re.I),dt.keys())) - int(skip); oo=1
  for layer in layout.sortOxides(dt.keys()):
    bot = 0 if bLayer == 'first' else float(dt[bLayer][0])
    top = float(dt[layer][0]); tc = top-bot
    bLayer = layer;
    if re.search(r'oxide|c4|si',layer,flags=re.I): uncomp = dt[layer][1] if oo>skip else str(float(dt[layer][1])/float(mComp)); oo+=1;
    else: uncomp = dt[layer][1]
    outLst.append(','.join([layer,n2s(bot,PR),n2s(top,PR),n2s(tc,PR),'1',n2s(dt[layer][2],PR,True),n2s(uncomp,PR),n2s(dt[layer][1],PR),n2s(dt[layer][3],PR)]))
  outLst.reverse()
  return outLst

def findOxide(oxLst,height):
  h = float(height); 
  for ii,temp in enumerate(oxLst):
    ox,hh = temp[0],temp[1];
    if abs(h-float(hh)) < 0.0001: return ii,ox,True #0.0001 um grid does not exist
    if h<float(hh): break
  return ii,ox,False

def readTechFile(process,inFile):
  import csvUtils, os, re
  test = re.search(r'(\w+?)_(\d+)',os.path.basename(process))
  if not test: raise IOError('Bad upf inside '+inFile)
  srcPrefix = os.path.dirname(__file__)+'/tech/'+test.group(1)+'_'+test.group(2)
  techfile = srcPrefix+'.layermap';
  csv = csvUtils.dFrame(techfile); dt = {}
  for layer,gds in zip(csv['layer'],csv['gds']): dt[layer] = gds
  return dt,[srcPrefix+'.tech.db',srcPrefix+'.library.tech']

def correctOxides(dt,exclude,factor,compensate='True',lti=0,ltb=0,PR=None): # if compesate is true return epsr with factor, if compensate is a number return epsr with that factor else return uncmp
  import layout, re, collections; from numtools import isNumber, numToStr as n2s
  newDt = collections.OrderedDict();
  oxOnly = filter(lambda ff: re.search(r'oxide|c4|sib',ff,flags=re.I),dt.keys())
  bot = len(dt.keys()) - len(oxOnly)
  top = len(dt.keys()) - exclude
  for ii,layer in enumerate(dt.keys()): # OLD layout.sortOxides(dt.keys())):
    if ii >= bot and ii < top:
      uncmp = float(dt[layer][1])/factor
      if compensate == 'True': effEpsr = uncmp*factor; 
      elif isNumber(compensate):  effEpsr = uncmp*compensate
      else: effEpsr = uncmp
      newDt[layer] = [dt[layer][0],n2s(effEpsr,PR),dt[layer][2],n2s(ltb,PR)] #append the losstanBot where EPSR
    else: newDt[layer] = dt[layer][0:3]+[n2s(lti,PR) if layer in oxOnly else '0'] #append the losstanIn to rest of oxides and zero to nonOxides
  return newDt

def getMVBelow(layer):
  import re
  test = re.search(r'(m|v)(\d+)',layer,flags=re.I); out=False
  if test: 
    num = int(test.group(2)); out=[]
    for ii in range(num,-1,-1): 
      if test.group(1) in ['v','V'] and ii==num : out.append('v'+str(ii))
      out.append('m'+str(ii))
      if ii!= 0: out.append('v'+str(ii-1))
  return out

def getExcludeValue(oxDt,mtlDt):
  newOxides = []
  for layer in oxDt.keys():
    newOxides.append([layer,oxDt[layer][0]])
  topMetal = mtlDt.keys()[1]
  iiTopMetalOx = findOxide(newOxides,mtlDt[topMetal][0])[0]
  exclude = len(oxDt.keys()) - (iiTopMetalOx + 1)
  return str(exclude)
