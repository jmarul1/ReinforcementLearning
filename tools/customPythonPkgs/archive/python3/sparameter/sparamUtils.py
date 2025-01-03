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
#   Useful functions for sparameter executions
#
##############################################################################

def toMultiArray(data1D,format,version): # convert from 1D 11, 12, 21, 22, etc to matrix
  portNum = (len(data1D[0])/2)**0.5
  if not portNum-int(portNum) == 0: raise ValueError('Invalid data in the sparameter file')
  else: portNum = int(portNum)
  import math
  format = format.lower(); mArray = []
  for iiFreq in range(len(data1D)):
    mArray.append({}); index = 0
    for iiRow in range(1,portNum+1):
      (mArray[iiFreq])[iiRow]={}
      for iiCol in range(1,portNum+1): #store as RI always
            if format == 'ma':
              mag = data1D[iiFreq][index]; angle = data1D[iiFreq][index+1]*math.pi/180;
              (mArray[iiFreq])[iiRow][iiCol] = complex(mag*math.cos(angle),mag*math.sin(angle));
              index += 2;
            elif format == 'db':
              mag = math.pow(10,data1D[iiFreq][index]/20); angle = data1D[iiFreq][index+1]*math.pi/180
              (mArray[iiFreq])[iiRow][iiCol] = complex(mag*math.cos(angle),mag*math.sin(angle));
              index += 2
            else:
              (mArray[iiFreq])[iiRow][iiCol] = complex(data1D[iiFreq][index],data1D[iiFreq][index+1]);
            index += 2
    if portNum == 2 and version == '1.0': # special case for 2 port sparameters in v1.0, transponse S12 and S21
      temp= (mArray[iiFreq])[1][2]; (mArray[iiFreq])[1][2] = (mArray[iiFreq])[2][1]
      (mArray[iiFreq])[2][1] = temp;
  return mArray

## Calculate Zdiff and Zse
def getZ(selfData):
  import math,sys
  from .sparamFileUtils import snpToS2pXfmr
  Zse = []; Zdiff = []; Zk = []
## 1 port
  if selfData.portNum == 1:
    for iiFreq in range(len(selfData.freq)):
      S11 = selfData.data[iiFreq][1][1];
      Sdiff = S11
      Zdiff.append(selfData.impedance*(1+Sdiff)/(1-Sdiff)); Zse = Zdiff
## 2 ports
  elif selfData.portNum == 2:
    for iiFreq in range(len(selfData.freq)):
      S11 = selfData.data[iiFreq][1][1]; S12 = selfData.data[iiFreq][1][2];
      S21 = selfData.data[iiFreq][2][1]; S22 = selfData.data[iiFreq][2][2];
      Sdiff = (S11-S12-S21+S22)/2;
      Sse = S11 - (S12*S21)/(S22+1)
      try: Zdiff.append(2*selfData.impedance*(1+Sdiff)/(1-Sdiff))
      except ZeroDivisionError: Zdiff.append(float('inf')); print >> sys.stderr, 'Warning, division by zero:%s' %selfData.filename
      try: Zse.append(selfData.impedance*(1+Sse)/(1-Sse))
      except ZeroDivisionError: Zse.append(float('inf')); print >> sys.stderr, 'Warning, division by zero:%s' %selfData.filename
## 3 ports
  elif selfData.portNum == 3:
    for iiFreq in range(len(selfData.freq)):
      S11 = selfData.data[iiFreq][1][1]; S12 = selfData.data[iiFreq][1][2]; S13 = selfData.data[iiFreq][1][3];
      S21 = selfData.data[iiFreq][2][1]; S22 = selfData.data[iiFreq][2][2]; S23 = selfData.data[iiFreq][2][3];
      S31 = selfData.data[iiFreq][3][1]; S32 = selfData.data[iiFreq][3][2]; S33 = selfData.data[iiFreq][3][3];
      Sdiff = (S11-S12-S21+S22)/2 - (S13*(S31-S32))/(2*(S33-1)) + (S23*(S31-S32))/(2*(S33-1))
      Sse = (S11+S11*S22-S12*S21-S11*S33+S13*S31-S11*S22*S33+S11*S23*S32+S12*S21*S33-S12*S23*S31-S13*S21*S32+S13*S22*S31)/ (S22-S33-S22*S33+S23*S32+1);
      Zdiff.append(2*selfData.impedance*(1+Sdiff)/(1-Sdiff))
      Zse.append(selfData.impedance*(1+Sse)/(1-Sse));
## 4 ports
  elif selfData.portNum in [4,5,6]:
    import sparameter
    xfmrData = sparameter.read(snpToS2pXfmr(selfData)); 
    selfData.freq = xfmrData.freq; selfData.data = xfmrData.data
    for iiFreq in range(len(selfData.freq)):
      S11 = selfData.data[iiFreq][1][1]; S12 = selfData.data[iiFreq][1][2];
      S21 = selfData.data[iiFreq][2][1]; S22 = selfData.data[iiFreq][2][2];
      Zdiff.append(selfData.impedance*((1+S11)*(1-S22)+S12*S21)/((1-S11)*(1-S22)-S12*S21))
      Zse.append(selfData.impedance*((1-S11)*(1+S22)+S12*S21)/((1-S11)*(1-S22)-S12*S21))
      Zk.append(selfData.impedance*(2*S12)/((1-S11)*(1-S22)-S12*S21))  
  else: raise ValueError('7 port or more are not supported')
  return Zdiff, Zse, Zk

## Calculate Self Resonance Frequencies
def getIndSRF(freq,Q):
  import sys
  done=False; maxFreq = False
  if len(Q) < 2: print >> sys.stderr, 'Only one point in the sparameter, cannot extrapolate SRF'; return maxFreq,-1
  for ii in range(2,len(Q)):
    if float(Q[ii-1]) >= 0.0 and float(Q[ii]) < 0.0: maxFreq = freq[ii-1]; done+=1
    if done: break
  return maxFreq,ii-1

## Calculate Self Resonance Frequencies
def getTLRsn(freq,R11):
  import sys
  maxFreq = False
  if len(R11) < 2: print >> sys.stderr, 'Only one point in the sparameter, cannot extrapolate Resonance'; return maxFreq,-1
  for ii in range(2,len(R11)-1):
    if R11[ii] > R11[ii-1] and R11[ii] > R11[ii+1]: maxFreq = freq[ii]; return maxFreq,ii

## Get the key points for Inductor
def indKPI(freq,Q,L):
  import numpy as np, scipy.signal
  srf,srfI = getIndSRF(freq,Q); 
  if srf == False: srf = freq[-1] 
  peak = scipy.signal.argrelextrema(np.array(Q[0:srfI+1]),np.greater)[0]
  peak = peak[-1] if peak.size > 0 else len(Q)-1
  dc = scipy.signal.argrelextrema(np.array(L[0:srfI+1]),np.less)[0]
  dc = dc[-1] if dc.size > 0 else 0  
  Qpeak,Fpeak = Q[peak],freq[peak]; 
  Ldc,Fdc = L[dc],freq[dc]
  return Qpeak,Fpeak,peak,Ldc,Fdc,dc,srf,srfI
