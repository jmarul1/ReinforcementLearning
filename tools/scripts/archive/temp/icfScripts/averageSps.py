#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.               #
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
#   Type >> averageSps.py -h 
##############################################################################

## imports
import argparse, os, sys, re
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import sparameter as sp, numpy as nu

def checkIn(sparam):
  if os.path.isfile(sparam) and re.search(r'\.s\d+p$',os.path.splitext(sparam)[1],flags=re.I): 
    return sp.read(sparam)
  else: raise argparse.ArgumentTypeError('File doesn\'t exist or is not an sparameter file: '+sparam)

def getHeader(sparam):
  import numtools
  out = '! Touchstone format v2.0\n'
  out += '# '+sparam.freqUnits+' S RI R '+numtools.numToStr(sparam.impedance)+'\n'
  return out

def getDataStr(freqLst,dataLst):
  out = ''
  for ff,sLineLst in zip(freqLst,dataLst):
    sLineEff = ['{0:15.5e} {1:15.5e}'.format(ii.real,ii.imag) for ii in sLineLst]
    out += ' '.join([ff]+sLineEff)+'\n'
  return out
  
##############################################################################
# Argument Parsing
##############################################################################
argparser = argparse.ArgumentParser(description='This program calculates the capacitances and quality factors of a capacitor sparameter file.')
argparser.add_argument(dest='spFiles', nargs='+', type=checkIn, help='sparameter file(s)')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: Compilation_Q(L|C).csv')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## check frequencies match up  
if not all(map(lambda ff: args.spFiles[0].freq == ff.freq, args.spFiles)): raise argparse.ArgumentTypeError('Files do not have same frequencies')

## run for each frequency averaging all the sparameters
final = []; fLst = []
for ii,freq in enumerate(args.spFiles[0].freq):
  ## calculate for each row each col
  fLst.append('{0:15.5e}'.format(freq*1e9/args.spFiles[0].freqM)); spData = []
  for rr in sorted(args.spFiles[0].data[ii].keys()):
    for cc in sorted(args.spFiles[0].data[ii][rr].keys()): 
      ## calculate the average for that matrix entry
      medVal = nu.median(nu.array([sparam.data[ii][rr][cc] for sparam in args.spFiles]))
      spData.append(medVal)
      ## append to the final the [list of vals]      
  final.append(spData) #order is 11 12 13 ... 1m ... 21 22 23 ... n1 n2 n3 ... nm
## print the sparameter
outStr = getHeader(args.spFiles[0])
outStr += getDataStr(fLst,final) 
## if csv enable print values in csv file ## else print to the prompt
if args.csvFile:
  ext = os.path.splitext(args.spFiles[0].filename)[1]
  with open('averageSp'+ext,'w') as fout: fout.write(outStr)
else: print(outStr)
exit(0)
