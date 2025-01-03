#!/usr/bin/env python2.7
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
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> simSpList.py -h
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='This program simulates all the sparameter files in the given folder.')
argparser.add_argument('-dir', dest='spDir', required=True, help='sparameter folder')
argparser.add_argument('-freq', dest='reqFreq', type=float, help='Peaking values are extracted at this freq in GHz otherwise at peaking Qdiff')
argparser.add_argument('-tcoil', dest='tcoil', action='store_true',help='Do TCoil Calculations at peaking Qdiff or specified frequency (only s3p files)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import os, re, sys
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import sparameter as sp

if not os.path.exists(args.spDir):
  print 'Directory does not exists'
  exit(1)
else: spDir = os.path.realpath(args.spDir)

## Get the files for measurements
listOfFiles = os.listdir(spDir); onceRun = False; 
fileNameOut = 'outputList.csv'; tableNameOut = 'peakingResults.csv'; tableCoilNameOut = 'tcoilResults.csv'
fidOut = open(fileNameOut, 'w')
fidOutTable = open(tableNameOut, 'w')
if args.tcoil: fidOutTCoil = open(tableCoilNameOut, 'w')
    
## print the labels
fidOut.write('Top Metal,N,S,W,D,Y,skew,Frequency(GHz),');
fidOut.write('Qdiff,Ldiff(nH),Qse,Lse(nH),Other\n');
fidOutTable.write('Top Metal,N,S,W,D,Y,skew,PeakFreqDiff(GHz),Qdiff,Ldiff(nH),PeakFreqSe,Qse,Lse(nH),SRF(GHz),Other\n');
if args.tcoil: fidOutTCoil.write('Top Metal,N,S,W,D,Y,skew,PeakFreqDiff(GHz),L1ToCt(nH),L2ToCt(nH),R1ToCt(Ohms),R2ToCt(Ohms),kL1L2,C11 (fF),C22 (fF),C33 (fF)\n')

## go through each file
fNumExp = '(\d+(?:p\d+)?)'; countSim = 0;
for iiFile in listOfFiles:
## skip if not an sparameter file
  if not re.search('\.s\d+p', os.path.splitext(iiFile)[1],flags=re.I):
    continue

## extract the values with two type of files
  test1 = re.search(r'[bd]8\dsind(spiral|symml|symint)([a-z]+[0-9]+){1,2}.*_'+fNumExp+'N_'+fNumExp+'S_'+fNumExp+'W_'+fNumExp+'Di?_'+fNumExp+'Y_(lowQ|typQ|highQ)\.s\dp$',iiFile,flags=re.I)
  test2 = re.search(r'[bd]8\dsind(spiral|symml|symint)([a-z]+[0-9]+){1,2}.*_'+fNumExp+'N_'+fNumExp+'S_'+fNumExp+'W_'+fNumExp+'Di?_'+fNumExp+'Y_(.+)_(lowQ|typQ|highQ)\.s\dp$',iiFile,flags=re.I)
  test3 = re.search(r'[bd]8\dsind(spiral|symml|symint)([a-z]+[0-9]+){1,2}(lowQ|typQ|highQ).*_'+fNumExp+'N_'+fNumExp+'S_'+fNumExp+'W_'+fNumExp+'Di?_'+fNumExp+'Y_?(.*)\.s\dp$',iiFile,flags=re.I)
  test4 = re.search(r'[bd]8\dsind(spiral|symml|symint)?([a-z]+[0-9]+){1,2}(ct)?l'+fNumExp+'n.*(lowQ|typQ|highQ)(.*)\.s\dp$',iiFile,flags=re.I)
  if test1:
    topMetal=test1.group(2); N=test1.group(3); S=test1.group(4); W=test1.group(5); D=test1.group(6); Y=test1.group(7);
    inductorSkew=test1.group(8); other=iiFile
  elif test2:
    topMetal=test2.group(2); N=test2.group(3); S=test2.group(4); W=test2.group(5); D=test2.group(6); Y=test2.group(7);
    inductorSkew=test2.group(9); other=test2.group(8)+'_'+iiFile
  elif test3:
    topMetal=test3.group(2); N=test3.group(4); S=test3.group(5); W=test3.group(6); D=test3.group(7); Y=test3.group(8);
    inductorSkew=test3.group(3); other=test3.group(9)+'_'+iiFile
  elif test4:
    topMetal=test4.group(2); N='n/a'; S='n/a'; W='n/a'; D='n/a'; Y='n/a'; 
    inductorSkew=test4.group(5); other=test4.group(6)+'_'+iiFile
  else:
    other=iiFile; topMetal='n/a'; N='n/a'; S='n/a'; W='n/a'; D='n/a'; Y='n/a'; inductorSkew='n/a';

## get the simulated values
  print('Simulating '+iiFile)
  sparam=sp.read(spDir+'/'+iiFile)
  spFull = sparam.getQLR()
  resultDiff = [spFull[0],spFull[1]]; resultSe = [spFull[2],spFull[3]]
  if args.tcoil and re.search('\.s3p', os.path.splitext(iiFile)[1],flags=re.I):
    resultTCoil = sparam.getTCoilFns()

## get the Q at the frequency specified based or the peak based on Qse/Qdiff and print to the peaking file
  fidOutTable.write(','.join([topMetal,N,S,W,D,Y,inductorSkew])+',');        
  if args.tcoil and re.search('\.s3p', os.path.splitext(iiFile)[1],flags=re.I): 
    fidOutTCoil.write(','.join([topMetal,N,S,W,D,Y,inductorSkew])+',');        
  reqFreqInd = False
  if args.reqFreq:
    reqFreqInd = sparam.freq.index(args.reqFreq) if args.reqFreq in sparam.freq else False
  if reqFreqInd:
    QdPt = resultDiff[0][reqFreqInd]; QsePt = resultSe[0][reqFreqInd]; LdPt = resultDiff[1][reqFreqInd]; LsePt = resultSe[1][reqFreqInd];
    freqPtQd = sparam.freq[reqFreqInd]; freqPtQse = sparam.freq[reqFreqInd]
    if args.tcoil and re.search('\.s3p', os.path.splitext(iiFile)[1],flags=re.I): 
      L1ToCt = resultTCoil[0][reqFreqInd]; R1ToCt = resultTCoil[1][reqFreqInd]; L2ToCt = resultTCoil[2][reqFreqInd]; R2ToCt = resultTCoil[3][reqFreqInd]; 
      kL1L2 = resultTCoil[4][reqFreqInd]; C11 = resultTCoil[5][reqFreqInd]; C22 = resultTCoil[6][reqFreqInd]; C33 = resultTCoil[7][reqFreqInd]
  else:
    [QdPt,QdPtInd] = [max(resultDiff[0]),resultDiff[0].index(max(resultDiff[0]))]
    [QsePt,QsePtInd] = [max(resultDiff[0]),resultSe[0].index(max(resultSe[0]))]
    LdPt = resultDiff[1][QdPtInd]; LsePt = resultSe[1][QsePtInd]
    freqPtQd = sparam.freq[QdPtInd]; freqPtQse = sparam.freq[QsePtInd]
    if args.tcoil and re.search('\.s3p', os.path.splitext(iiFile)[1],flags=re.I): 
      L1ToCt = resultTCoil[0][QdPtInd]; R1ToCt = resultTCoil[1][QdPtInd]; L2ToCt = resultTCoil[2][QdPtInd]; R2ToCt = resultTCoil[3][QdPtInd]; 
      kL1L2 = resultTCoil[4][QdPtInd]; C11 = resultTCoil[5][QdPtInd]; C22 = resultTCoil[6][QdPtInd]; C33 = resultTCoil[7][QdPtInd]

## get SRF
  SRF = sparam.getSRF();

## print the peaking or requested values
  fidOutTable.write(','.join([str(freqPtQd),str(QdPt),str(LdPt),str(freqPtQse),str(QsePt),str(LsePt)]))
  if SRF['diff']: fidOutTable.write(','+str(SRF['diff']))
  elif SRF['se']: fidOutTable.write(','+str(SRF['se'])+'_se')
  else: fidOutTable.write(',NoSRF')
  fidOutTable.write(','+other+'\n')        
  if args.tcoil and re.search('\.s3p', os.path.splitext(iiFile)[1],flags=re.I): 
    fidOutTCoil.write(','.join([str(freqPtQd),str(L1ToCt),str(L2ToCt),str(R1ToCt),str(R2ToCt),str(kL1L2),str(C11),str(C22),str(C33)]));   fidOutTCoil.write(','+other+'\n')        

## print in the output file
  for iiFreq in range(len(sparam.freq)):
    fidOut.write(','.join([topMetal,N,S,W,D,Y,inductorSkew,str(sparam.freq[iiFreq]),str(resultDiff[0][iiFreq]),str(resultDiff[1][iiFreq]),str(resultSe[0][iiFreq]),str(resultSe[1][iiFreq])]))
    fidOut.write(','+other+',\n');

## update counter
  countSim+=1;

print('Total number of Simulated Files were: '+str(countSim))
fidOut.close(); fidOutTable.close()
