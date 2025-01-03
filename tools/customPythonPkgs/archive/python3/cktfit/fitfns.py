##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2020, Intel Corporation.  All rights reserved.               #
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
#   Initialize the module for circuit paramteres
#
##############################################################################

class readSp():

  ## Get Q and L
  def __init__(self,spFile):
    import sparameter as sparam, numpy as np
    sp = sparam.read(spFile)
    Qd,Ld,Qse,Lse,Rd,Rse,k12 = sp.getQLR(); srf = sp.getIndSRF()[1]; 
    self.freq,self.qd,self.ld = list(map(np.array,[sp.freq[0:srf],Qd[0:srf],Ld[0:srf]]))
    self.Qpeak,self.Fpeak,self.peakI,self.Ldc,self.Fdc,self.dcI,self.srf,self.srfI = sparam.indKPI(self.freq,self.qd,self.ld)

  ## Re Sample in frequency steps
  def resample(self,resample=1):
    import sparameter as sparam, numpy as np; from scipy.interpolate import CubicSpline
    maxF = self.freq[-1]
    splineQd,splineLd = CubicSpline(self.freq,self.qd),CubicSpline(self.freq,self.ld) ## Build spline and interpolate
    fEff = list(np.arange(resample,int(maxF),resample));
    self.freq,self.qd,self.ld = fEff,splineQd(fEff),splineLd(fEff)
    self.Qpeak,self.Fpeak,self.peakI,self.Ldc,self.Fdc,self.dcI,self.srf,self.srfI = sparam.indKPI(self.freq,self.qd,self.ld)

class readCkt():

  ## Get Q and L
  def __init__(self,csvFile):
    import re
    self.ckts = {}; 
    with open(csvFile) as fin:
      for line in fin:
        if re.search(r'^\s*#',line): continue
        line = line.split('#')[0]
        entries = line.split(','); key,value=list(map(str.strip, entries[0:2]))
        self.ckts[key.upper()] = value

  ## Create the netlist
  def createScs(self,outFile=None,label=None):
    import tempfile
    outFile = outFile or tempfile.mkstemp(suffix='.scs')[1] 
    fL = f'*{label}\n' if label else ''
    values=[fL+'subckt equiv_rlck 1 2',
    '   Cc    1    2    capacitor   c={}*1e-15'.format(self.ckts['CC']),
    '  Rs1    1    4    resistor    r={}'.format(self.ckts['RS']),
    '  Ls1    4    3    inductor    l={}*1e-9'.format(self.ckts['LS']),
    '  Ls2    3    5    inductor    l={}*1e-9'.format(self.ckts['LS']),
    '  Rs2    5    2    resistor    r={}'.format(self.ckts['RS']),
    ' Rsk1    1    6    resistor    r={}'.format(self.ckts['RSK']),
    ' Lsk1    6    4    inductor    l={}*1e-9'.format(self.ckts['LSK']),
    ' Rsk2    2    7    resistor    r={}'.format(self.ckts['RSK']),
    ' Lsk2    7    5    inductor    l={}*1e-9'.format(self.ckts['LSK']),
    ' Cox1    1    8    capacitor   c={}*1e-15'.format(self.ckts['COX']),
    ' Cox2    2    9    capacitor   c={}*1e-15'.format(self.ckts['COX']),
    ' Cox3    3    10   capacitor   c={}*1e-15'.format(self.ckts['COX3']),
    'Rsub1    8    0    resistor    r={}'.format(self.ckts['RSUB']),
    'Rsub2    9    0    resistor    r={}'.format(self.ckts['RSUB']),
    'Rsub3    10   0    resistor    r={}'.format(self.ckts['RSUB3']),
    'K12 mutual_inductor coupling={} ind1=Ls1 ind2=Ls2'.format(self.ckts['K12']),
    'ends equiv_rlck']
    with open(outFile,'wb') as fout: fout.write( ('\n'.join(values)).encode())
    self.scs = outFile

  def runSim(self,steps,maxf):
    import subprocess, sparameter as sparam
    freqs = str(steps)+'G '+str(steps)+'G '+str(maxf)+'G'
    cmd = 'calculateQLNetlist.py '+self.scs+' -maxfreq '+freqs
    test = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE)
    csvStr = test.communicate()[0].decode(); self.freq,self.qd,self.ld = [],[],[]
    if csvStr.strip() == '': return False
    for ii,line in enumerate(csvStr.split('\n')):
      if ii==0 or line.strip()=='': continue
      vals = list(map(float,line.split(',')))
      self.freq.append(vals[0]); self.qd.append(vals[1]); self.ld.append(vals[2])
    self.Qpeak,self.Fpeak,self.peakI,self.Ldc,self.Fdc,self.dcI,self.srf,self.srfI = sparam.indKPI(self.freq,self.qd,self.ld)    
    return True

  def mathSim(self,steps,maxf):
    import numpy as np, sparameter as sparam, math, warnings
    freqs = np.arange(steps,maxf,steps)
    self.freq,self.qd,self.ld = [],[],[]
    LS,LSK = list(map(lambda ff: float(ff)*1e-9, [self.ckts['LS'],self.ckts['LSK']]))
    COX,COX3,CC = list(map(lambda ff: float(ff)*1e-15, [self.ckts['COX'],self.ckts['COX3'],self.ckts['CC']]))
    RS,RSK,RSUB,RSUB3 = list(map(float,[self.ckts['RS'],self.ckts['RSK'],self.ckts['RSUB'],self.ckts['RSUB3']]))
    K12 = float(self.ckts['K12'])
    warnings.filterwarnings('error')
    for freq in freqs:
      try:
        w = 2*3.1416*freq*1e9
        ZS = w*LS*1j + RS*(RSK+w*LSK*1j)/(RS+RSK+w*LSK*1j)
        ZC = 1/(w*CC*1j); ZOX= RSUB + 1/(w*COX*1j); ZOX3 = RSUB3 + 1/(w*COX3*1j)
        ZM = w*K12*LS*1j      
        IM1 = 1/(ZOX*(ZM+ZS)/(ZM+ZS+ZOX3)+ZS+ZM)
        Y11 = Y22 =  1/ZC + 1/ZOX     + IM1
        Y12 = Y21 = -1/ZC - 1/(ZM+ZS) + IM1
        Zd = 4/(Y11-Y12-Y21+Y22)
        Zse = 2/(Y11+Y22)
      except (ZeroDivisionError,RuntimeWarning): continue
      if not (math.isfinite(Zd.imag) and math.isfinite(Zd.real) and Zd.real > 0): continue
      self.qd.append(Zd.imag/Zd.real); self.ld.append(Zd.imag*1e9/w); self.freq.append(freq)
    if len(self.qd) < 2: return False
    self.Qpeak,self.Fpeak,self.peakI,self.Ldc,self.Fdc,self.dcI,self.srf,self.srfI = sparam.indKPI(self.freq,self.qd,self.ld)    
    return True
