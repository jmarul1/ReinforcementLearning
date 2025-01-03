from functools import reduce
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
#   Initialize the module for sparamteres
#
##############################################################################

class read():
  '''reads the contents of the sparameter file in citi: self.VAR[name,type,length,values] 
and self.DATA[name,param,type,values]'''
## Read the contents of the file
  def __init__(self,citiFile):
    self.filename = citiFile
    with open(citiFile, 'r') as fidIn:
      import os, re      
      if not re.search(r'\.citi',os.path.splitext(citiFile)[1],flags=re.I): raise ValueError('Invalid sparameter citi file')  ## check is a citi file
      ## read the file line by line
      for line in fidIn: 
        if re.search(r'^\s*#.*$|^\s*$|^\s*COMMENT.*$',line): continue #if comments("#") in sparam file or blanklines
      ## CITIFILE header and version
        test = re.search(r'^\s*CITIFILE\s+(.*)',line)
        if test: self.version = test.group(1).rstrip(); self.VAR=[]; self.DATA=[]; iiVar=0; iiData=0; continue #initialize all the variables
      ## get the header NAME and VAR
        test = re.search(r'^\s*NAME\s+(\w+)',line)
        if test: self.dataKey = test.group(1);  continue
        test = re.search(r'^\s*VAR\s+(\w+)\s+(\w+)\s+(\d+)',line)
        if test: self.VAR.append(tuple([test.group(1),test.group(2),int(test.group(3)),[]])); continue
      ## get the DATA based on NAMES
        test = re.search(r''+self.dataKey+'\s+(\S+)\s+(\w+)',line,flags=re.I)
        if test: self.DATA.append(tuple([self.dataKey,test.group(1),test.group(2),[]])); continue ## at this point all the VAR values have been stored
      ## get the VAR values
        if re.search('^\s*VAR_LIST_BEGIN',line): varFetch = True;  continue ## begin reading var values
        if re.search('^\s*VAR_LIST_END',line): iiVar+=1; continue ## next var value
        if varFetch and iiVar<len(self.VAR): self.VAR[iiVar][3].append(line.rstrip()); continue
      ## get the DATA values
        if re.search('^\s*BEGIN',line): dataFetch=True; continue  ## begin reading the data values
        if re.search('^\s*END',line): iiData+=1; continue ## next data value
        if dataFetch and iiData<len(self.DATA): self.DATA[iiData][3].append(line.rstrip()); continue        
      ## figure out the number of ports
      self.param = 'sparameter'; self.portNum = int(len([ff for ff in [ii[1] for ii in self.DATA] if re.search(r'^S\[|^[Ss]\d',ff)])**0.5);
      self.dataSample = reduce(lambda x,y: x*y, [ii[2] for ii in self.VAR]) 
