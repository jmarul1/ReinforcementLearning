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

def chkIn(num):
  import numtools
  num = numtools.getScaleNum(num)
  if numtools.isNumber(num): return num
  else: raise IOError('Provide numbers')
 
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math, subprocess, pandas as pd, sclind, csvUtils, numtools
argparser = argparse.ArgumentParser(description='Find Dimensions of an inductor for given F/L/Q')
argparser.add_argument('-csv', dest='csvFile', default = '/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/AI/trainTables/sparam/indGuideHR_QL.csv', help=argparse.SUPPRESS)
argparser.add_argument(dest='inputs', nargs='+', type=chkIn, help='List values as: freq(GHz) L(nH) minQualityFactor')
argparser.add_argument('-list', dest='list', default = 7, type = int, help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
freq,ind = args.inputs[0]/1e9,args.inputs[1]*1e9
## Read the file
df = sclind.init(args.csvFile)
## Get Closest number of Freq,Linds
Q = args.inputs[2] if len(args.inputs)>2 else None
df.closestNums(freq,ind,Q)
print('####')
outLst = df.getWinnerDims(args.list)
print('\n'.join(outLst))
print('####')

