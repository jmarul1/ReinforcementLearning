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
##############################################################################

def computeAccuracy(spFile,cktCsv,spSampling=0.5,printCsvsDir=None,sim=None):
  from .fitfns import readSp, readCkt
  import pandas as pd, os, re
  ## read the sparameter
  sp = readSp(spFile); sp.resample(resample=spSampling) # sp.freq/qd/ld have the values
  ## read the ckt
  ckt = readCkt(cktCsv); 
  if sim == 'pymm':        runSt = ckt.mathSim(spSampling,sp.freq[-1])  #MATH 
  else: ckt.createScs(); runSt = ckt.runSim(spSampling,sp.freq[-1])   #CKT SPECTRE
  if runSt == False: return 1e12,1e12,1e12# bad input, set minimize to 1e12 to make a point
  ## we have the values matching freqs points, so compare
  orig = pd.DataFrame({'freq':sp.freq,'Qd':sp.qd,'Ld':sp.ld}) # Ld is in nH
  test = pd.DataFrame({'freq':ckt.freq,'Qd':ckt.qd,'Ld':ckt.ld}) # Ld is in nH
  ## compute the delta
  QdScore = (orig['Qd'].astype(float)-test['Qd'].astype(float))**2
  LdScore = (orig['Ld'].astype(float)-test['Ld'].astype(float))**2
  ## range test: start from minimum of 10% of SRF and dcI && end range at min of Fpeak*2, srf
  start = min(abs(sp.freq-0.1*sp.srf).argmin(), sp.dcI); 
  end = min(abs(sp.freq-2*sp.Fpeak).argmin(),sp.srfI)
  ## summarize the deltas, L goes from dc to 2*peak as above
  LdScore = LdScore.iloc[sp.dcI:end+1].mean() #sp.peakI+1
  QdScore = QdScore.iloc[start:end+1].mean()
  ## add srf to the scores
  srfScore = 0.5*(sp.srf - ckt.srf)**2+0.5*(sp.qd[sp.srfI]-ckt.qd[ckt.srfI])**2
  ## save the outputs in a file
  if printCsvsDir:
    header = ['Freq(GHz)','Qdiff','Ldiff(nH)']; studyName = os.path.basename(os.path.splitext(cktCsv)[0])
    orig.to_csv(f'{printCsvsDir}/{studyName}_orig_QL.csv',index=False,header=header);   test.to_csv(f'{printCsvsDir}/{studyName}_test_QL.csv',index=False,header=header)
  return QdScore,LdScore,srfScore
