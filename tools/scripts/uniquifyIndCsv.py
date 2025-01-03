#!/usr/bin/env python3.7.4
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
##############################################################################
import sys,os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import warnings
warnings.simplefilter("ignore")    
##############################################################################
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math, subprocess, pandas as pd
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import csvUtils, numtools
argparser = argparse.ArgumentParser(description='Find Dimensions of an inductor for given F/L/Q')
argparser.add_argument(dest='csvFile',help='csv file')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## Read the file
csvDf = pd.read_csv(args.csvFile,comment='#')
csvDf = csvDf.sort_values(by=['fileName','Fd_full(GHz)']).reset_index(drop=True)
print(csvDf)
fetch = False; indeces=[]; inds=[]
for ii in range(len(csvDf)):
  if csvDf['Qd_full'][ii] < 0 or  csvDf['Ld_full(nH)'][ii]<0: fetch=False; continue
  if not csvDf['fileName'][ii] in inds: inds.append(csvDf['fileName'][ii]); fetch=True; indeces.append(ii); continue
  if fetch and csvDf['Fd_full(GHz)'][ii] > csvDf['Fd_full(GHz)'][ii-1]: # current more than previous
    indeces.append(ii)
  else: fetch = False
#import pdb; pdb.set_trace()
csvDf = csvDf.iloc[indeces,:]
csvDf.to_csv('test.csv',index=False)
print(csvDf)
