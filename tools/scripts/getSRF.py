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
# Description:
#   Type >> getSRF.py -h 
##############################################################################


##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re
argparser = argparse.ArgumentParser(description='Prints the SRF and FreqIndex of the specified files')
argparser.add_argument(dest='files', nargs='+', help='sparameter file')
argparser.add_argument('-csv', dest='csv', action='store_true', help='Output to SRFs.csv')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import sparameter as sp

## get the freqs
results = 'FileName,SRF_diff,SRF_se\n'
for iiFile in args.files:
  if os.path.exists(iiFile) and re.search('\.s\d+p', os.path.splitext(iiFile)[1], flags=re.I): 
    spData = sp.read(iiFile)
    SRF = spData.getSRF()
    iiFile = os.path.splitext(os.path.basename(iiFile))[0]
    diffSRF = str(SRF['diff'])+spData.freqUnits if SRF['diff'] != False else 'None(>'+str(spData.freq[-1])+spData.freqUnits+')'
    seSRF = str(SRF['se'])+spData.freqUnits if SRF['se'] != False else 'None(>'+str(spData.freq[-1])+spData.freqUnits+')'    
    results += ','.join([iiFile,diffSRF,seSRF])+'\n'
  else: print >> sys.stderr,iiFile+' does not exists or is not an sparameter file'

if args.csv: 
  with open('SRFs.csv','w') as fid: fid.write(results)
else: print results
