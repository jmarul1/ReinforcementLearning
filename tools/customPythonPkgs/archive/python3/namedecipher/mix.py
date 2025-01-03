#!/usr/bin/env python3.7.4

def getParamsFromName(fName):
  import re
  geom = ['n','w(um)','s(um)','x(um)','y(um)','do(um)','l(um)','wM8(um)','wM7(um)','doM8(um)','doM7(um)','tl(um)','ts(um)','dlt(um)']; dt = {}; rem=fName
  regexes = {'die':'(X(?:-?\d+|m)Y(?:-?\d+|m))','indType':'(oct|rec)'} # die, shape, shuttle
  for label in geom: regexes[label] = '(n?\d+(?:p\d+)?)'+re.sub('\(um\)','',label) # geometry
  regexes['skew'] = '(tttt|pcff|pcss|prcs|prcf|ffff|ssss|typQ|highQ|lowQ)';  # skews
  regexes['deemb'] = '(?:de)([a-z]+)'
  for label,reg in regexes.items(): # match the necessary
    regex = (r'(?:^|_)'+reg+'(?:_|$)') if label!='x(um)' else (r'(?:^|_)'+reg+'(?:_(?!dut)|$)')
    test = re.search(regex,fName,flags=re.I);
    if test: 
      dt[label] = test.group(1); 
      if label in geom: dt[label] = dt[label].replace('p','.')
      rem = re.sub(r'(?P<k1>^|_)'+reg+'(?P<k2>_|$)','\g<k1>\g<k2>',rem,flags=re.I); rem = re.sub('_+','_',rem)
  if dt: return dt,rem
  else: return {'fileBaseName':fName},'' 

def shuttleDut(fName):
  import re
  shuttle=deemb=False; rem = fName; fun = lambda reg,string: re.sub('_+','_',re.sub(reg,'_',string,flags=re.I));
  test = re.search(r'(^|_)([xsi]\d\d[a-z][a-z])_',fName,flags=re.I)
  if test: shuttle = test.group(2); rem=fun(test.group(),rem)
  test = re.search(r'_de(_|$)',fName,flags=re.I);
  if test: deemb = 'OpSh'; rem = fun(test.group(),rem) #DE from the machine
  test = re.search(r'_nl(_|$)',fName,flags=re.I)
  if test: deemb='modelNoLeads'; rem = fun(test.group(),rem)
  elif shuttle: deemb='model'
  return shuttle,deemb,rem.strip('_')

def cleanUpFile(fName):
  import re, os
  fName = os.path.splitext(os.path.basename(fName))[0]
  fName = re.sub('_(QL|TL|QC)$','_',fName,flags=re.I) # remove csv stuff
  fName = re.sub('_\d+p\d+_\d+p\d+lt(_|$)','_',fName,flags=re.I) ## remove ads
  fName = re.sub('_\d+x\d+r[0-9a-z]+(_|$)','_',fName,flags=re.I)  ## remove upf
  return fName
  
