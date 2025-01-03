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
#   Reads the inductor or capacitor file netlist
#
##############################################################################

class read():
## Read the contents of the file
  def __init__(self,cktFile,full=False):
    import os, re, cktUtils
    self.cktFile = os.path.realpath(cktFile); self.rlck = {}
    with open(self.cktFile, 'r') as fidIn:
      ## read the file
      optionLine=False; entryCount=0; self.freq=[]; self.data=[]; self.params={} #initialize
      for line in fidIn:
        line = re.split(r'//|\$',line.strip())[0]
        if re.search(r'^\*|^$',line): continue # skip comments in sparameter file or blank lines
 	## get the description of the file subckt
 	test = re.search(r'^\s*(\.?subckt)\s+(\w+)\s+(.+)$',line,flags=re.I)
	if test:
	  self.modelName = test.group(2);
	  self.ports = re.findall(r'(\w+)',test.group(3))  ## find the number of ports
	  self.portNum = len(self.ports)
	  self.cktFile=[self.cktFile];
	  if test.group(1).lower() == '.subckt': self.cktFile.append('spice')
	  else: self.cktFile.append('spectre')
	  if not full: break
	else:
	  test = re.search(r'^\s*.param\S*\s+(\S+?)\s*=\s*(\S+)',line)
	  if test: self.params[test.group(1)] = test.group(2); continue
	  test = re.findall(r'\S+',line)
	  if len(test) == 4:
	    key,val = cktUtils.getPassiveScaledValue(test[0],test[-1],self.params)
	    self.rlck[key] = val 

## Calculate Q and L or C for diff and se modes
  def getQPR(self,firstFreq='0.5G',stepFreq='0.5G',lastFreq='50G',tmpTarget='/tmp',device='ind'):
    import re, math, tempfile, subprocess, cktUtils, numtools
  ## convert the frequencies
    firstFreq,stepFreq,lastFreq = map(numtools.getScaleNum,[firstFreq,stepFreq,lastFreq])        
  ## Create working dir and run spectre
    tempDir = tempfile.mkdtemp(dir=tmpTarget);    
    scsTuple = cktUtils.createScsFile(tempDir,self.modelName,self.ports,self.cktFile,firstFreq,stepFreq,lastFreq) 
    runScs = subprocess.Popen('cd '+tempDir+';spectre '+scsTuple[0],shell=True,stdout=subprocess.PIPE)
#    subprocess.call('cd '+tempDir+';cat '+scsTuple[0],shell=True)          
    output = runScs.communicate()[0]
  ## Read the Data if no errors
    test = re.findall(r'\b(ERROR|FATAL).*\n',output)
    if not test:
      import sparameter as sp
      sparam = sp.read(tempDir+'/'+scsTuple[1])
      freq = sparam.freq
      if device == 'cap': [Qdiff,Pdiff,Qse,Pse,Rdiff,Rse] = sparam.getQCR() 
      elif device == 'mim': params = sparam.getMimFns()    
      else: [Qdiff,Pdiff,Qse,Pse,Rdiff,Rse,k12] = sparam.getQLR() 
      if self.ports == 3 and device == 'tcoil':
        [L1ToCt,R1ToCt,L2ToCt,R2ToCt,kL1L2,C11,C22,C33] = sparam.getTCoilFns()
      elif device == 'tcoil': raise ValueError('Only 3 port inductors can be used for tcoil transfer functions')
    else: raise IOError('Problems running spectre, check log in dir: '+tempDir)
    if tmpTarget=='/tmp': subprocess.call('sleep 5 && rm -r '+tempDir+' &',shell=True)
    if self.ports == 3 and device == 'tcoil':
      return freq,Pdiff,L1ToCt,R1ToCt,L2ToCt,R2ToCt,kL1L2,C11,C22,C33
    elif device == 'mim':
      return freq,params
    else:
      return freq, Qdiff, Pdiff, Qse, Pse, Rdiff, Rse
    
## Calculate Q and L or C for diff and se modes
  def getQPR_AC(self,firstFreq='0.5G',stepFreq='0.5G',lastFreq='50G',tmpTarget='/tmp',device='ind',sim='scs',rEnd=1e9):
    import re, math, tempfile, subprocess, cktUtils, numtools
  ## convert the frequencies
    firstFreq,stepFreq,lastFreq = map(numtools.getScaleNum,[firstFreq,stepFreq,lastFreq])        
  ## Create working dir and run hspice or spectre
    tempDir = tempfile.mkdtemp(dir=tmpTarget)
    if sim == 'scs':    
      simTuple = cktUtils.createACScsFile(tempDir,self.modelName,self.ports,self.cktFile,firstFreq,stepFreq,lastFreq,rEnd) 
      runSim = subprocess.Popen('cd '+tempDir+';spectre '+simTuple[0],shell=True,stdout=subprocess.PIPE)
      output = runSim.communicate()[0]
    else:
      simTuple = cktUtils.createHspFile(tempDir,self.modelName,self.ports,self.cktFile,firstFreq,stepFreq,lastFreq,rEnd) 
      runSim = subprocess.Popen('cd '+tempDir+';hspice '+simTuple[0],shell=True,stdout=subprocess.PIPE)
      output = runSim.communicate()[0]
      with open(tempDir+'/'+simTuple[1],'w') as fidOut: fidOut.write(output)
#    subprocess.call('cd '+tempDir+';cat '+simTuple[0],shell=True)      
  ## Read the Data if no errors
    test = re.findall(r'\b(ERROR|fatal).*\n',output) if sim == 'scs' else re.findall(r'\b(error|ERROR|fatal).*\n',output)
    if not test:
      numExp = '([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)';       
  ## open the file and get the results
      with open(tempDir+'/'+simTuple[1]) as fidIn:
        freq=[]; P = []; Q = []; R = []
        for line in fidIn:
          test = re.search(r'^\s*'+numExp+'\s+'+numExp+'\s+'+numExp, line, flags=re.I)
          if test:
            freq.append(float(test.group(1))*1e-9);	    
	    R.append(float(test.group(3)))
	    if device == 'ind':
              P.append(float(test.group(2))/(2*math.pi*freq[-1]))	    
              try: Q.append(float(test.group(2))/R[-1]) 
	      except ZeroDivisionError: Q.append(float(test.group(2))*float('inf'))
	    else:
	      Yval = 1/(float(test.group(2))*1j + R[-1]); 
              P.append(Yval.imag*1e6/(2*math.pi*freq[-1]))	    
              try: Q.append(-1*float(test.group(2))/R[-1]) #Q.append(1/(Yval.imag*R[-1])) 	    
	      except ZeroDivisionError: Q.append(-1*float(test.group(2))*float('inf'))
    else: raise IOError('Problems running simulation, check log in dir: '+tempDir)
    if tmpTarget=='/tmp': subprocess.call('sleep 5 && rm -r '+tempDir+' &',shell=True)
    return freq, Q, P, R

## Calculate L1ToCt,R1ToCt,L2ToCt,R2ToCt
  def getTCoilFns(self,firstFreq='0.5G',stepFreq='0.5G',lastFreq='50G',tmpTarget='/tmp'):
    import re, math, tempfile, subprocess, cktUtils, numtools
    if self.portNum == 3:
      freq=[]; L1ToCt=[];R1ToCt=[];L2ToCt=[];R2ToCt=[];kL1L2=[]
    ## convert the frequencies
      firstFreq,stepFreq,lastFreq = map(numtools.getScaleNum,[firstFreq,stepFreq,lastFreq])        
    ## Create working dir
      tempDir = tempfile.mkdtemp(dir=tmpTarget)    
      scsTuple = cktUtils.createScsFile(tempDir,self.modelName,self.ports,self.cktFile,firstFreq,stepFreq,lastFreq)
      runScs = subprocess.Popen('cd '+tempDir+';spectre '+scsTuple[0],shell=True,stdout=subprocess.PIPE)
      output = runScs.communicate()[0]
    ## Read the Data if no errors
      test = re.findall(r'\b(ERROR|FATAL).*\n',output)
      if not test:
    ## Get the differential, center tap components and losses from the sparameter file
        import sparameter as sp
	sparam = sp.read(tempDir+'/'+scsTuple[1])
        Qdiff,Ldiff,Qse,Lse,Rdiff,Rse = sparam.getQLR()
        L1ToCt,R1ToCt,L2ToCt,R2ToCt,kL1L2,C11,C22,C33 = sparam.getTCoilFns()
      else:
        raise IOError('Problems running spectre\n'+'\n'.join(test))
      subprocess.call('sleep 5 && rm -r '+tempDir+' &',shell=True)
    else: raise ValueError('Only 3 port inductors can be used')
    return sparam.freq,Ldiff,L1ToCt,R1ToCt,L2ToCt,R2ToCt,kL1L2,C11,C22,C33

## Calculate Sparameter for subckt
  def spAnalysis(self,firstFreq='0.5G',stepFreq='0.5G',lastFreq='50G',tmpTarget='/tmp'):
    import re, math, tempfile, subprocess, cktUtils, numtools
  ## convert the frequencies
    firstFreq,stepFreq,lastFreq = map(numtools.getScaleNum,[firstFreq,stepFreq,lastFreq])        
  ## Create working dir and run spectre
    tempDir = tempfile.mkdtemp(dir=tmpTarget)    
    scsTuple = cktUtils.createScsFile(tempDir,self.modelName,self.ports,self.cktFile,firstFreq,stepFreq,lastFreq) 
    runScs = subprocess.Popen('cd '+tempDir+';spectre '+scsTuple[0],shell=True,stdout=subprocess.PIPE)
    output = runScs.communicate()[0]
  ## Read the Data if no errors
    test = re.findall(r'\b(ERROR|FATAL).*\n',output)
    if not test: return tempDir,tempDir+'/'+scsTuple[1]
    else: raise IOError('Problems running spectre, check log in dir: '+tempDir)

