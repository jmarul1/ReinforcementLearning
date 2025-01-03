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
#   Finds the first and last frequencies of an sparameter file and the units
#
##############################################################################

from .sparamUtils import getIndSRF, indKPI
from .sparamFileUtils import citiToTs

class read():
  '''reads the contents of the sparameter file'''
## Read the contents of the file
  def __init__(self,spFile):
    self.filename = citiToTs(spFile) # convert if necessary
    with open(self.filename, 'r') as fidIn:
      from os import path; from .sparamUtils import toMultiArray, getZ
      from numtools import getFreqM; import re, sys
 ## find the number of ports
      test = re.search(r'\.s(\d+)p',path.splitext(self.filename)[1],flags=re.I)
      if test: self.portNum = int(test.group(1)); paramCount = 1+2*(self.portNum**2); # freq + port^2 of im,re or mag,ph
      else: raise ValueError('Invalid sparameter file')
      numExp = '([+-]?\d*(?:\.\d+)?(?:[eE][+-]?\d+)?)'; 
      optionLine=False; entryCount=0; self.freq=[]; self.data=[]; self.version='2.0' #initialize
      for line in fidIn:
        if re.search(r'^\s*!.*$|^\s*$',line): #if comments("!") in sparam file or blanklines, but check if version is mentioned
            testVer = re.search(r'version\s+v?(\d+(?:\.\d*)?)',line,flags=re.I)
            if testVer: self.version = testVer.group(1); print('Sparameter file given is '+self.version,file=sys.stderr)
        else: #process the line
 ## get the description of the file 
          if re.search(r'^\s*#',line) and not optionLine:
            test = re.search(r'\b(HZ|KHZ|MHZ|GHZ)\b',line,flags=re.I); self.freqUnits = test.group(1) if test else 'GHZ'
            test = re.search(r'\b(S|Y|Z|G|H)\b',line,flags=re.I); self.dataType = test.group(1) if test else 'S'
            test = re.search(r'\b(MA|DB|RI)\b',line,flags=re.I); self.dataFormat = test.group(1) if test else 'MA'
            test = re.search(r'\bR\s+'+numExp,line,flags=re.I); self.impedance = float(test.group(1)) if test else float('50')
            self.freqM = getFreqM(self.freqUnits)
            optionLine = True
 ## read the values
          else:
            test = list(filter(lambda ff: ff.strip()!='', re.findall(r''+numExp,line))) # read all the numbers in the line, ignore empty values (regex captures them to allow .number not onlyy 0.number)
            if entryCount == 0: 
              self.freq.append(float(test[0])*self.freqM/1e9) #store in GHz
              tempValList = [float(test[ii]) for ii in range(1,len(test))]
              entryCount += len(test)
            else: 
              for ii in test: tempValList.append(float(ii) )
              entryCount += len(test);
            if entryCount == paramCount: # at the end of the data entry for the frequency
              self.data.append(tempValList)
              entryCount = 0;
      if len(self.data) == 0: raise ValueError('No data in the sparameter file')
      self.data = toMultiArray(self.data,self.dataFormat,self.version)
      self.getZ = getZ 

## Calculate Q , L and R for diff and se modes
  def getQLR(self):
    import math; from .sparamUtils import getZ
    Qdiff = []; Ldiff = []; Qse = []; Lse = []; Rdiff = []; Rse = []; k12 = []
    Zdiff,Zse,Zk = getZ(self);    
    for iiFreq,freqVal in enumerate(self.freq):
      Qdiff.append(Zdiff[iiFreq].imag/Zdiff[iiFreq].real) 
      try: Ldiff.append(Zdiff[iiFreq].imag/(2*math.pi*freqVal))
      except ZeroDivisionError: Ldiff.append(float('inf'));
      Qse.append(Zse[iiFreq].imag/Zse[iiFreq].real)    
      try: Lse.append(Zse[iiFreq].imag/(2*math.pi*freqVal))    
      except ZeroDivisionError: Lse.append(float('inf'))
#      Ldiff.append(Zdiff[iiFreq].imag/(2*math.pi*freqVal))
#      Lse.append(Zse[iiFreq].imag/(2*math.pi*freqVal))
      Rdiff.append(Zdiff[iiFreq].real)    
      Rse.append(Zse[iiFreq].real)      
      if any(Zk) and Ldiff[-1]*Lse[-1]>0: k12.append(-1*Zk[iiFreq].imag/(2*math.pi*freqVal)/(Ldiff[-1]*Lse[-1])**0.5)
      else: k12.append(0)
    return Qdiff, Ldiff, Qse, Lse, Rdiff, Rse, k12

## Calculate insertion loss, input return loss and output return loss  
  def getTransferFns(self):
    import math, cmath
    losses = dict(insertion=[],inReturn=[],outReturn=[],insertionPh=[])
    for iiFreq in range(len(self.freq)):
      isZero = lambda ff: {0:float('inf')}.get(ff,ff)
      losses['insertion'].append(-20*math.log10(isZero(abs(self.data[iiFreq][2][1]))) ) #DB
      losses['inReturn'].append(abs(20*math.log10(isZero(abs(self.data[iiFreq][1][1]))) )) #DB
      losses['outReturn'].append(abs(20*math.log10(isZero(abs(self.data[iiFreq][2][2]))) )) #DB
      losses['insertionPh'].append(cmath.phase(self.data[iiFreq][2][1])) #rad
    return losses

## Calculate Q,C, and R for diff or se depending on mode
  def getQCR(self,freq=None):
    import math; from .sparamUtils import getZ
    Cdiff = []; Qdiff = []; Cse = []; Qse = []; Rdiff = []; Rse = []; k12 = []
    Zdiff,Zse,Zk = getZ(self)
    for iiFreq, freqVal in enumerate(self.freq):
      if not freq == None: freqVal = freq
      Ydiff = 1/Zdiff[iiFreq]; Yse = 1/Zse[iiFreq]
      Cdiff.append(1e6*Ydiff.imag/(2*math.pi*freqVal))#Make it fF from nF
      Cse.append(1e6*Yse.imag/(2*math.pi*freqVal))#Make it fF from nF
      #Qdiff.append(Ydiff.imag/Ydiff.real)      Qse.append(Yse.real/Ydiff.imag)
      #Cdiff.append(-1e6/(Zdiff[iiFreq].imag*2*math.pi*freqVal)); Cse.append(-1e6/(Zse[iiFreq].imag*2*math.pi*freqVal)) #Make it fF from nF      
      try: Qdiff.append(-Zdiff[iiFreq].imag/Zdiff[iiFreq].real)
      except ZeroDivisionError: Qdiff.append(float('inf'))
      try: Qse.append(-Zse[iiFreq].imag/Zse[iiFreq].real)          
      except ZeroDivisionError: Qse.append(float('inf'))
      Rdiff.append((Zdiff[iiFreq].real**2+Zdiff[iiFreq].imag**2)/Zdiff[iiFreq].real)    
      Rse.append((Zse[iiFreq].real**2+Zse[iiFreq].imag**2)/Zse[iiFreq].real)      
    return Qdiff, Cdiff, Qse, Cse, Rdiff, Rse

  def getTLChar(selfData,ports):
    from sparamFileUtils import snpToS2p; import numpy; from sparamUtils import getZ, getTLRsn
    if selfData.portNum>2 or (selfData.portNum==2 and len(ports)==1):
      import sparameter 
      newData = sparameter.read(snpToS2p(selfData,ports)); #keep ports as main 1,2 and the rest gnd
      selfData.freq = newData.freq; selfData.data = newData.data; selfData.portNum = newData.portNum 
    if len(ports) == 2:  
      gammaL = []; Zeff = []
      for iiFreq in range(len(selfData.freq)):
        S11 = selfData.data[iiFreq][1][1]; S12 = selfData.data[iiFreq][1][2];
        S21 = selfData.data[iiFreq][2][1]; S22 = selfData.data[iiFreq][2][2]; Z0 = selfData.impedance
        ## get the z-parameters
        A = ((1+S11)*(1-S22)+S12*S21)/(2*S21);     B = Z0*((1+S11)*(1+S22)-S12*S21)/(2*S21)
        C = ((1-S11)*(1-S22)-S12*S21)/(Z0*2*S21);  D = ((1-S11)*(1+S22)+S21*S12)/(2*S21)
        ## get the tline characteristics
        gammaL.append(numpy.arccos(A/2+D/2)*180/3.1416); #convert to degrees
        Zeff.append((B/C)**0.5)
      Qdiff, Ldiff, Qse, Lse, Rdiff, Rse, k12 = selfData.getQLR()
      return Qdiff,Ldiff,Rdiff,gammaL,Zeff
    else:
      Zdiff, Zse, Zk = getZ(selfData); Zse = numpy.array(Zse); rsnFreq = getTLRsn(selfData.freq,Zse)
      return Zse.real,Zse.imag,rsnFreq          
  
## Remove ports and keep the ports indicated
  def extractPorts(self,ports):
    import mathUtils; from sparamUtils import toMultiArray
    portLst = mathUtils.combElemInLst(ports)
    newData = []
    for ii,freq in enumerate(self.freq):
      temp = []
      for n,m in portLst: temp += self.data[ii][n][m].real,self.data[ii][n][m].imag
      newData.append(temp)
    self.data = toMultiArray(newData,self.dataFormat,self.version); self.portNum = len(ports)

## Create an sparameter file
  def writeSpFileStr(self):
    import mathUtils
    lines = ['! S-Parameters Output Version 2.0']
    lines.append(' '.join(map(str,['#','GHZ',self.dataType,'RI','R',self.impedance])))
    portLst = mathUtils.combElemInLst(xrange(1,self.portNum+1)); lineElems = self.portNum if self.portNum == 3 else 4
    line = ['! FREQ\t']; jj=0
    for n,m in portLst: #print the port order comments
      line.append('S'+str(n)+str(m)); jj +=1; stop=False
      if jj == lineElems: lines.append(' '.join(map(str,line))); jj=0; line = ['!\t']; stop=True
    if not stop: lines.append(' '.join(map(str,line)))
    lines.append('')      
    for ii,freq in enumerate(self.freq):
      line = [freq]; jj = 0
      for n,m in portLst:
        line += [self.data[ii][n][m].real,self.data[ii][n][m].imag]; jj+=1; stop=False
        if jj == lineElems: lines.append(' '.join(map(str,line))); jj=0; line = ['\t']; stop=True
      if not stop: lines.append(' '.join(map(str,line)))
    return '\n'.join(lines)
    
## What is step freq
  def stepFreq(self):
    for ii,freq in enumerate(self.freq):
      if ii == 0: continue
      print(freq - self.freq[ii-1])

## Calculate MIM Parameters
  def getMimFns(self):
    import math, collections
    if self.portNum == 2:
      params = collections.OrderedDict()    
      params['C11']=[];params['C22']=[];params['C12']=[];params['C21']=[];
      params['R11']=[];params['R22']=[];params['R12']=[];params['R21']=[];
      params['Q11']=[];params['Q22']=[];params['Q12']=[];params['Q21']=[];
      params['Y11r']=[];params['Y11i']=[];params['Y22r']=[];params['Y22i']=[];params['Y12r']=[];params['Y12i']=[];params['Y21r']=[];params['Y21i']=[];            
      for iiFreq in range(len(self.freq)):  
        S11 = self.data[iiFreq][1][1]; S12 = self.data[iiFreq][1][2];
        S21 = self.data[iiFreq][2][1]; S22 = self.data[iiFreq][2][2];            
   ## get the y-parameters
        dS = (1+S11)*(1+S22)-S12*S21; Y0 = 1/self.impedance
        Y11 = ((1-S11)*(1+S22)+S12*S21)*Y0/dS;         Y12 = -2*S12*Y0/dS;
        Y21 = -2*S21*Y0/dS;                         Y22 = ((1+S11)*(1-S22)+S12*S21)*Y0/dS;
   ## get the z-parameters
        dS = (1-S11)*(1-S22) - S12*S21; Z0 = self.impedance
        Z11 = Z0*((1+S11)*(1-S22)+S12*S21)/dS;         Z12 = Z0*2*S12/dS
        Z21 = Z0*2*S21/dS;                        Z22 = Z0*((1-S11)*(1+S22) + S12*S21)/dS
   ## get the capacitance
        if self.freq[iiFreq] < 1e-15: params['C11'].append('inf'); params['C22'].append('inf') ; params['C12'].append('inf') ; params['C21'].append('inf') 
        else:
          params['C11'].append( 1e6/(Y11.imag/(Y11.real**2+Y11.imag**2))/(2*math.pi*self.freq[iiFreq]))
          params['C22'].append( 1e6/(Y22.imag/(Y22.real**2+Y22.imag**2))/(2*math.pi*self.freq[iiFreq]))
          params['C12'].append(-1e6/(Y12.imag/(Y12.real**2+Y12.imag**2))/(2*math.pi*self.freq[iiFreq]))
          params['C21'].append(-1e6/(Y21.imag/(Y21.real**2+Y21.imag**2))/(2*math.pi*self.freq[iiFreq]))
   ## get the resistance
          params['R11'].append(Y11.real/(Y11.real**2+Y11.imag**2))
          params['R22'].append(Y22.real/(Y22.real**2+Y22.imag**2))
          params['R12'].append(-Y12.real/(Y12.real**2+Y12.imag**2))
          params['R21'].append(-Y21.real/(Y21.real**2+Y21.imag**2))
   ## get the Qs
          params['Q11'].append(Z11.imag/Z11.real)
          params['Q22'].append(Z22.imag/Z22.real)
          params['Q12'].append(Z12.imag/Z12.real)
          params['Q21'].append(Z21.imag/Z21.real)
   ## include the Y parameters
          params['Y11r'].append(Y11.real); params['Y11i'].append(Y11.imag); params['Y22r'].append(Y22.real); params['Y22i'].append(Y22.imag)
          params['Y12r'].append(Y12.real); params['Y12i'].append(Y12.imag); params['Y21r'].append(Y21.real); params['Y21i'].append(Y21.imag);
    else: raise ValueError('Only 3 port inductors can be used')
    return params

  def getIndSRF(self):
    from . import sparamUtils
    srf = sparamUtils.getIndSRF(self.freq,self.getQLR()[0])
    if len(srf) == 2: return srf
    else: return False

  def getYParams(self,ports=[1,2]):
    import math, collections
    if len(ports) != 2: raise ValueError('Number of ports must be 2')
    p1,p2 = ports
    if self.portNum > 1:
      params = {}
      params['Y11']=[];params['Y22']=[];params['Y21']=[];params['Y12']=[];            
      for iiFreq in range(len(self.freq)):  
        S11 = self.data[iiFreq][p1][p1]; S12 = self.data[iiFreq][p1][p2];
        S21 = self.data[iiFreq][p2][p1]; S22 = self.data[iiFreq][p2][p2];            
   ## get the y-parameters
        dS = (1+S11)*(1+S22)-S12*S21; Y0 = 1/self.impedance
        Y11 = ((1-S11)*(1+S22)+S12*S21)*Y0/dS;         Y12 = -2*S12*Y0/dS;
        Y21 = -2*S21*Y0/dS;                         Y22 = ((1+S11)*(1-S22)+S12*S21)*Y0/dS;
   ## include the Y parameters
        params['Y11'].append(Y11); params['Y22'].append(Y22);
        params['Y12'].append(Y12); params['Y21'].append(Y21);
    else: raise ValueError('Only for 2 or more s-parameters ports')
    return params

