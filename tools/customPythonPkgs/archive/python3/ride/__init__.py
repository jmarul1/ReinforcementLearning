##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2014, Intel Corporation.  All rights reserved.               #
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
#   Initialize the module for ride paramteres
#
##############################################################################

from .rideUtils import readSubCkt

class read():
## Read the contents of the file
  def __init__(self,cktFile):
    import os, re 
    self.model = []; self.range = []; self.options = []; self.equate = []
    self.subckt = []; self.newRange = False
    self.numExp = r'([+-]?\d*(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    self.cktFile = os.path.realpath(cktFile)
    with open(self.cktFile, 'r') as fidIn:
      ## read the file
      for line in fidIn:
        if re.search(r'^\s*\*|^\s*$|^\s*//',line): continue # skip comments in ckt file or blank lines
        line = line.strip()
        line = line.split('//')[0]
        ## read the options
        test = re.search(r'^\.(.*?:)(.*)',line)
        if test:
          if re.search(r'range',test.group(1),flags = re.I): self.range.append(test.group(2).strip().upper())
          elif re.search(r'equate',test.group(1),flags = re.I): self.equate.append(test.group(2).strip().upper())
          else: self.options.append(line)
        else: self.model.append(line)

## Update the circuit file
  def updateCkt(self,subcktFile,bndFile):
    import re, rideUtils
    self.model = rideUtils.readSubCkt(subcktFile);    
    if bndFile:
      bnds = rideUtils.readBndLimits(bndFile,self.numExp); tmpRange = []
      for rr in self.range:
        element = re.search(r'^(\w+)',rr).group(1)
        if element in bnds.keys():
          newRange = rideUtils.computNewRange(bnds[element])
          tmpRange.append(element+' = '+(' : '.join([newRange[0],newRange[0],newRange[1]]))); self.newRange=True
        else: tmpRange.append(rr)  
      self.range = tmpRange

## Update the circuit file with options
  def updateCktOptions(self,**kwargs):
    import re
    for newOption in kwargs.keys():    
      newValue = str(kwargs[newOption]).strip()
      if not newValue: continue
      newOptionArg = '.'+newOption+': '+newValue; success = False
      for oo,option in enumerate(self.options):      
        test = re.search(r'^\.'+newOption+'\s*:(.*)',option)
        if test: self.options[oo] = newOptionArg; success = True; break
      if not success: self.options.append(newOptionArg)

## Get the Option
  def getOption(self,option):
    import re
    for oo in self.options:
      test = re.search(r'\.'+option+'\s*:\s*(\S+)',oo)
      if test: return test.group(1)
    
## Print the new subckt
  def printCkt(self,tgtFile=False):
    outStr = ['*** Derived Model from RIDE run'+(' with updated RANGE' if self.newRange else '')+'\n']
    outStr += self.model
    outStr += ['\n* Ranges of element values']    
    outStr += map(lambda ff: '.range: '+ff,self.range)
    outStr += ['\n* Mutual relationships']    
    outStr += map(lambda ff: '.equate: '+ff,self.equate)
    outStr += ['\n* Optimization options']    
    outStr += self.options                 
    if tgtFile: 
      with open(tgtFile,'wb') as fout: fout.write('\n'.join(outStr))
    else: return '\n'.join(outStr)

