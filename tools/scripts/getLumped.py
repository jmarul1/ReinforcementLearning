#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def computeParams(freqs,yP):
  Cox1 = []; Cox2 = []; Ls = []; Rs = []; Cp = []; Rp = []; Qd = []
  for ii in range(len(freqs)):
    denom = 2*math.pi*freqs[ii]
    if denom < 1e-15: continue
    Y11 = yP['Y11'][ii]; Y22 = yP['Y22'][ii]
    Y12 = yP['Y12'][ii]; Y21 = yP['Y21'][ii]
    Zdiff = 4/(Y11+Y22-Y21-Y12); Qdiff = Zdiff.imag/Zdiff.real
    Yseries = (-Y12-Y21)/2;  Zseries = 1/Yseries
    Rpe, Cpe = 1/Yseries.real, Yseries.imag/denom
    Rse, Lse = Zseries.real, Zseries.imag/denom
    Cox1.append((Y11+Y12).imag/denom); Cox2.append((Y22+Y21).imag/denom)
    Ls.append(Lse); Rs.append(Rse); Cp.append(Cpe); Rp.append(Rpe)
    Qd.append(Qdiff)
  return Ls,Rs,Cp,Rp,Cox1,Cox2

def diffMode(spData):
  import math
  k12 = []
  for iiFreq in range(len(spData.freq)):
    denom = 2*math.pi*spData.freq[iiFreq]
    S11 = spData.data[iiFreq][1][1]; S12 = spData.data[iiFreq][1][2]; S13 = spData.data[iiFreq][1][3]; S14 = spData.data[iiFreq][1][4];
    S21 = spData.data[iiFreq][2][1]; S22 = spData.data[iiFreq][2][2]; S23 = spData.data[iiFreq][2][3]; S24 = spData.data[iiFreq][2][4];
    S33 = spData.data[iiFreq][3][3]; S34 = spData.data[iiFreq][3][4]; S31 = spData.data[iiFreq][3][1]; S32 = spData.data[iiFreq][3][2];
    S43 = spData.data[iiFreq][4][3]; S44 = spData.data[iiFreq][4][4]; S42 = spData.data[iiFreq][4][2]; S41 = spData.data[iiFreq][4][1];    
    Sd11 = (S11+S22-S12-S21)/2; Zd11 = 2*spData.impedance*(1+Sd11)/(1-Sd11); L1 = Zd11.imag/denom
    Sd22 = (S33+S44-S34-S43)/2; Zd22 = 2*spData.impedance*(1+Sd22)/(1-Sd22); L2 = Zd22.imag/denom
    Sd12 = (S13-S14-S23+S24)/4 + (S31-S32-S41+S42)/4;
    Zd12 = 2*spData.impedance*(1+Sd12)/(1-Sd12); M=Zd12.imag/denom
    k12.append(M/(L1*L2)**0.5)
  return k12

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='Gets the lumped model equivalent of s2p/s4p')
argparser.add_argument(dest='spFiles', nargs='+', help='sparameter file(s)')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "spfile"_QL.csv')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import sys, re, math
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import sparameter as sp, numtools

## run for each sparameter specified 
for iiSpFile in args.spFiles:
## Get real path of the file and decide for how many ports
  if os.path.exists(iiSpFile) and re.search(r'\.(s\d+p|c.?ti)$',os.path.splitext(iiSpFile)[1],flags=re.I):
    spFile = os.path.realpath(iiSpFile); spFileName = os.path.splitext(os.path.basename(spFile))[0]
    sparam = sp.read(spFile)
  else: print('Sparameter file '+iiSpFile+' either does not exists or is not an sparameter file'); continue
  params = sparam.getYParams(ports=[1,2]); 
  results = 'Freq(GHz),Ls(pH),Rs(Ohms),Cp(fF),Rp(Ohms),Cox1(fF),Cox2(fF)\n'  
  lumpedElems = computeParams(sparam.freq,params)
  for freq,Ls,Rs,Cp,Rp,Cox1,Cox2 in zip(sparam.freq,*lumpedElems):
    results += (','.join(map(str,[freq,1e3*Ls,Rs,1e6*Cp,Rp,1e6*Cox1,1e6*Cox2])))+'\n'
## if csv enable print values in csv file ## else print to the prompt
  if args.csvFile:
    with open(spFileName+'_LM.csv','w') as fout:
      fout.write(results)
  else: print(results)
