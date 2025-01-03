
def divide(num1,num2):
  import numtools
  num1,num2 = float(num1),float(num2)
  if numtools.cmpFloat(num2,0): return 'inf'
  else: return str(num1/num2)

def fetch(line,fetchUnits,fetchMaterial,fetchMetalBias,fetchMask,fetchStack,fetchOps):          
  import re
  skip = True
  if   re.search(r'^UNITS',line,flags=re.I): fetchUnits = True
  elif re.search(r'^END_UNITS',line,flags=re.I): fetchUnits = False
  elif re.search(r'^BEGIN_MATERIAL',line,flags=re.I): fetchMaterial = True
  elif re.search(r'^END_MATERIAL',line,flags=re.I): fetchMaterial = False
  elif re.search(r'^BEGIN_METALBIAS',line,flags=re.I): fetchMetalBias = True
  elif re.search(r'^END_METALBIAS',line,flags=re.I): fetchMetalBias = False
  elif re.search(r'^BEGIN_MASK',line,flags=re.I): fetchMask = True
  elif re.search(r'^END_MASK',line,flags=re.I): fetchMask = False
  elif re.search(r'^BEGIN_STACK',line,flags=re.I): fetchStack = True
  elif re.search(r'^END_STACK',line,flags=re.I): fetchStack = False
  elif re.search(r'^BEGIN_OPERATION',line,flags=re.I): fetchOps = True
  elif re.search(r'^END_OPERATION',line,flags=re.I): fetchOps = False
  else: skip = False
  return fetchUnits,fetchMaterial,fetchMetalBias,fetchMask,fetchStack,fetchOps,skip

def getValuePairs(line):
  import re, collections
  line = re.sub(r'{\s*(\S+)\s*}',r' \1 ',line.strip()); out = collections.OrderedDict(); ii = 0
  test = re.split(r'(\s*=\s*|\s+)',line)
  while ii<len(test):
    if ii+3<=len(test) and test[ii+1].strip()=='=': out[test[ii].upper()] = test[ii+2]; ii+=3
    elif test[ii].strip(): out[test[ii].upper()] = ''; ii+=1
    else: ii+=1
  return out

def getStrFromDt(dt,separator=' '):
  outStr = []
  for kk,vv in dt.items():
    if vv.strip(): 
      if kk.upper() == 'MASK': outStr.append(kk+'={'+vv+'}')
      else: outStr.append(kk+'='+vv)
    else: outStr.append(kk)
  return separator.join(outStr)
  
def printLtd(ltdObj,foutName=None):
  outLst = [] #  outLst = ['## '+ltdObj.header['# PROCESS']+'_'+ltdObj.header['# SKEW']]
  for key,val in ltdObj.header.items():
    if(key not in ['1# LOSSTANGENT','1# DUMMYFACTOR']): outLst.append(key+'='+val); 
  outLst.append(ltdObj.techformat)
  ## units ltdObj is a dictionary
  outLst.append('\nUNITS'); outLst.append('  '+getStrFromDt(ltdObj.units,separator='\n  ')); outLst.append('END_UNITS')
  ## materials ltdObj is a dictionary of a dictionary
  outLst.append('\nBEGIN_MATERIAL'); [outLst.append('  MATERIAL '+key+' '+getStrFromDt(val)) for key,val in ltdObj.materials.items()]; outLst.append('END_MATERIAL')
  ## metal bias ltdObj is a list
  outLst.append('\nBEGIN_METALBIAS'); outLst+=['  '+val for val in ltdObj.metalBias]; outLst.append('END_METALBIAS')
  ## operations ltdObj is a dictionary
  outLst.append('\nBEGIN_OPERATION'); outLst+=[('  OPERATION '+key+' '+getStrFromDt(val)) for key,val in ltdObj.ops.items()]; outLst.append('END_OPERATION')
  ## masks ltdObj is a dictionary of a dictionary
  outLst.append('\nBEGIN_MASK'); [outLst.append('  MASK '+key+' '+getStrFromDt(val)) for key,val in ltdObj.masks.items()]; outLst.append('END_MASK')
  ## stacks ltdObj is a list of a dictionary
  outLst.append('\nBEGIN_STACK'); [outLst.append('  '+(key+' ' if key.strip() else '')+getStrFromDt(val)) for key,val in ltdObj.stacks]; outLst.append('END_STACK')  
  ## print the values
  if foutName:
    with open(foutName,'w') as fout: fout.write('\n'.join(outLst))
    return foutName
  else: return '\n'.join(outLst)
  
def printCsv(ltdObj,foutName=None):
  import re
  exclude = bot = 0; oxides = []; layers = []; outLst = []; vias = []; unitsD,unitsR = getMult(ltdObj.units['DISTANCE']),getMult(ltdObj.units['RESISTIVITY'])
  effExclude = len(list(filter(lambda ff: ff[0] == 'LAYER',ltdObj.stacks)))-int(ltdObj.header['# TOPEXCLUDE'])
  ## read the metals/oxides/vias
  for key,val in ltdObj.stacks[::-1]:
    if key == 'LAYER':
      oxideName,height,material = val['NAME'],unitsD*float(val['HEIGHT']),val['MATERIAL']; top = bot + height
      sigmaOx,epsrComp = '0',ltdObj.materials[material]['PERMITTIVITY']; epsr = epsrComp
      lt = ltdObj.materials[material]['LOSSTANGENT'] if 'LOSSTANGENT' in ltdObj.materials[material].keys() else 'NA'
      ## get the vias
      if 'MASK' in val.keys():
        name,material,thickness = getMaskVals(re.search(r'(\S+)',val['MASK']).group(1),ltdObj)
        sigma = ltdObj.materials[material]['CONDUCTIVITY']
        if name not in vias: vias.append(name); layers.append(','.join([name,'#VIA#','',sigma])); ## change material to name to support different layers with same material print material
      if effExclude>exclude and not re.search(r'epi|substrate',material,flags=re.I): 
        epsr = float(epsrComp)/float(ltdObj.header['# DUMMYFACTOR']); lt = ltdObj.header['# LOSSTANGENT']
      if re.search(r'epi|substrate',material,flags=re.I): sigmaOx = divide(1,unitsR*float(ltdObj.materials[material]['RESISTIVITY']))
      oxides.append(','.join([oxideName,str(bot),str(top),str(height),sigmaOx,str(epsr),str(epsrComp),lt])); bot = top; exclude += 1
    elif key == 'INTERFACE' and 'MASK' in val.keys():
      name,material,thickness = getMaskVals(re.search(r'(\S+)',val['MASK']).group(1) , ltdObj) ## find the mask thru the mask or the mask name
      sigma = ltdObj.materials[material]['CONDUCTIVITY'] if 'CONDUCTIVITY' in ltdObj.materials[material].keys() else divide(1,ltdObj.materials[material]['RESISTIVITY'])
      layers.append(','.join([name,str(bot),str(bot+float(thickness)),thickness,sigma]))
  ## add the info to the vias
  layers = addViaHeights(layers)
  ## print the headers
  for key,val in ltdObj.header.items(): 
    if re.search(r'^\s*#',key): outLst.append(key+'='+val); 
  ## print the metals/vias
  outLst.append(''); outLst += ['Layer,Zbot(um),Ztop(um),Tc(um),Sigma(S/m)']; layers.reverse(); outLst.append('\n'.join(layers))
  ## print the oxides
  outLst.append(''); outLst.append('Oxide/Substrate,Zbot(um),Ztop(um),Thickness(um),Sigma(S/m),EpsrUncomp,EpsrComp,lossTan'); oxides.reverse(); outLst.append('\n'.join(oxides))
  ## print the values
  if foutName:
    with open(foutName,'w') as fout: fout.write('\n'.join(outLst))
    return foutName
  else: return '\n'.join(outLst)

def getMaskVals(mask,ltdObj):
  name,material = 'unknown','unknown'; thickness = '0'
  if mask in ltdObj.masks.keys():
    name,material = ltdObj.masks[mask]['NAME'],ltdObj.masks[mask]['MATERIAL']
    if 'INTRUDE' in ltdObj.masks[mask].keys(): thickness = ltdObj.masks[mask]['INTRUDE']
  for mm,val in ltdObj.masks.items():
    if mask == val['NAME']: 
      name,material = val['NAME'],val['MATERIAL']
      if 'INTRUDE' in val.keys(): thickness = val['INTRUDE']; break
      elif 'OPERATION' in val.keys(): 
        operation = val['OPERATION']
        if operation in ltdObj.ops.keys() and 'INTRUDE' in ltdObj.ops[operation]: 
          thickness = str(getMult(ltdObj.units['DISTANCE'])*float(ltdObj.ops[operation]['INTRUDE']))
  return name,material,thickness    

def getMult(units):
  import re
  if re.search(r'metre',units,flags = re.I): return 1e6 #make it um
  elif re.search(r'um',units,flags=re.I): return 1 #make it um
  elif re.search(r'ohm.cm',units,flags=re.I): return 1e-2  #make it ohm.m
  else: return 1
  
def getExcludeNum(ltdObj):    
  ii = jj = 0; topMask = 'unknown'; topIndLays = ['gm1','tm1']
  for key,val in ltdObj.stacks:
    if key == 'LAYER': ii+=1
    elif key == 'INTERFACE' and 'MASK' in val.keys(): jj+=1 # and a mask
    mStk = val['MASK'] if 'MASK' in val.keys() else 'unknown'
    mStk = getMaskVals(mStk,ltdObj)[0]
    if jj >= 2 or mStk.lower() in topIndLays: topMask = mStk; break
  return str(ii),topMask
  
def addViaHeights(layers):
  newLayers = []
  for ii,line in enumerate(layers):
    layer = line.split(',')
    if layer[1] == '#VIA#':
      bot = layers[ii-1].split(',')[2]; top = layers[ii+1].split(',')[1]
      height = str(float(top) - float(bot))
      layer = [layer[0],bot,top,height,layer[-1]]
    newLayers.append(','.join(layer))  
  return newLayers

def getRidOfLayer(layer,ltdObj):
  mask,material,th = getMaskVals(layer,ltdObj); 
  if material in ltdObj.materials.keys():
    ltdObj.materials.pop(material) #remove material          
  if layer in ltdObj.masks.keys(): ltdObj.masks.pop(layer)

