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
#
# Author:
#   Mauricio Marulanda
#
# Description:
#   LTD stack handling
#
##############################################################################

from .stackUtils import printLtd, getMaskVals, getExcludeNum, getMult

class read():
  '''reads and process the contents of the ltd file'''
## Read the contents of the file
  def __init__(self,inFile):
    import os, re, collections; from . import stackUtils
    self.fileName = inFile; numExp = '([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    with open(self.fileName,'r') as fin:
      self.header=collections.OrderedDict(); self.units=collections.OrderedDict(); self.masks=collections.OrderedDict(); self.materials=collections.OrderedDict(); self.ops=collections.OrderedDict(); self.stacks = []; self.metalBias = []
      fetchUnits = fetchMaterial = fetchStack = fetchMask = fetchMetalBias = fetchOps = False
      ## find the process, skew
      self.header['# PROCESS'],self.header['# SKEW'] = '',''
      ## read the file
      for line in fin:
        line = line.strip()
        ## upf version skew
        test = re.search(r'^#.*(p\d+_\d+x\d+r\d+\w*).+?(\w+)', line, flags = re.I)
        if test: self.header['# PROCESS'],self.header['# SKEW'] = test.group(1),test.group(2); 
        ## tech file version
        if re.search(r'TECHFORMAT\s*=\s*(\S+)',line,flags=re.I): self.techformat = line
        ## fetching status
        fetchUnits,fetchMaterial,fetchMetalBias,fetchMask,fetchStack,fetchOps,skip = stackUtils.fetch(line,fetchUnits,fetchMaterial,fetchMetalBias,fetchMask,fetchStack,fetchOps)
        if skip: continue
        ## units
        if fetchUnits:
          test = re.split(r'\s*=\s*',line); 
          if len(test) == 2: self.units[test[0]] = test[1]
        ## materials
        if fetchMaterial:
          test = re.search(r'^MATERIAL\s*(\S+)\s*(.*)',line,flags=re.I)
          if test: key = test.group(1); self.materials[key] = stackUtils.getValuePairs(test.group(2))
        ## mask
        if fetchMask:
          test = re.search(r'^MASK\s*(\S+)\s*(.*)',line,flags=re.I) 
          if test: key = test.group(1); self.masks[key] = stackUtils.getValuePairs(test.group(2))
        ## stacks
        if fetchStack:
          test = re.search(r'^(LAYER|INTERFACE)\s*(.*)',line,flags=re.I) 
          if test: self.stacks.append([test.group(1),stackUtils.getValuePairs(test.group(2))])
          else: self.stacks.append(['',{line:''}])
        ## metalbias
        if fetchMetalBias and line and not re.search(r'^BEGIN',line): self.metalBias.append(line)
        ## operations
        if fetchOps:
          test = re.search(r'^OPERATION\s*(\S+)\s+(.+)',line,flags=re.I)
          if test: self.ops[test.group(1)] = stackUtils.getValuePairs(test.group(2))
      ## DEFAULT
      self.header['# LOSSTANGENT'] = '0.0'; self.header['# DUMMYFACTOR'] = '1'; self.header['# TOPEXCLUDE'] = '0'

## apply dummy/lt
  def applyDumLt(self,dummy,lt=None,exclude=None):
    import re; from . import stackUtils
    self.header['# DUMMYFACTOR'] = str(dummy);
    if lt != None: self.header['# LOSSTANGENT'] = str(lt);
    if exclude == None: exclude,tM = stackUtils.getExcludeNum(self);
    self.header['# TOPEXCLUDE'] = exclude
    ss = 0; repeat = []
    for key,val in self.stacks:
      if key == 'LAYER':
        ss+=1;
        if ss > int(self.header['# TOPEXCLUDE']) and not re.search(r'epi|substrate', val['MATERIAL'],flags=re.I) and val['MATERIAL'] not in repeat: 
          material = val['MATERIAL']; repeat.append(material)
          ## change the material
          self.materials[material]['PERMITTIVITY'] = str(float(self.header['# DUMMYFACTOR'])*float(self.materials[material]['PERMITTIVITY']))
          self.materials[material]['LOSSTANGENT'] = str(self.header['# LOSSTANGENT'])

## remove confidential layers
  def rmLayers(self,remove):
    import re; from . import stackUtils
    ss = 0; index=[]
    for ll,(key,val) in enumerate(self.stacks):
      if key == 'INTERFACE':
        if ss >= remove and not re.search(r'epi|substrate', val['NAME']): 
          index.append(ll)
          stackUtils.getRidOfLayer(val['MASK'],self) #remove material          
        ss+=1 
      elif key == 'LAYER' and ss >= remove: # remove any via reference MASK = 
        if 'MASK' in val.keys():           
          stackUtils.getRidOfLayer(val['MASK'],self) #remove material          
          self.stacks[ll][1].pop('MASK'); 
    for ii in index[::-1]: self.stacks.pop(ii)
         
## print ltd
  def printLtd(self,foutName=None):
    from . import stackUtils
    return stackUtils.printLtd(self,foutName)

## print csv
  def printCsv(self,foutName=None):
    from . import stackUtils
    return stackUtils.printCsv(self,foutName)

