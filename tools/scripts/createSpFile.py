#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2014, Intel Corporation.  All rights reserved.               #
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
#   Type >> spAnalysis.py -h 
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math 
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
argparser = argparse.ArgumentParser(description='Creates an sparameter from the subckt using the ports listed')
argparser.add_argument(dest='cktFiles', nargs='+', help='subcircuit file')
argparser.add_argument('-maxfreq', dest='maxFreq', nargs='+', default = ['50G'], help='Maximum frequency with units attached, default=65G. [You can also give "start stop" or "start step stop"; with units attached i.e. 10G 1G 50G]')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import subprocess, ckt, numtools
## run for each file specified 
for iiCktFile in args.cktFiles:
  ## Get real path of the file and decide for how many ports
  if os.path.exists(iiCktFile) and re.search(r'\.(scs|sp|hsp|spf)$',os.path.splitext(iiCktFile)[1],flags=re.I):
    cktFile = os.path.realpath(iiCktFile); cktFileName = os.path.splitext(os.path.basename(cktFile))[0]
    cktParam = ckt.read(cktFile)
  else: print('Subcircuit file '+iiCktFile+' either does not exists or is not a spectre/hspice file'); continue
  ## Set freqs
  if len(args.maxFreq) == 1: mFreq = args.maxFreq[0]; fFreq = 0.01*numtools.getScaleNum(mFreq); sFreq = fFreq
  elif len(args.maxFreq) == 2: fFreq, mFreq = args.maxFreq; sFreq = 0.01*numtools.getScaleNum(mFreq)
  elif len(args.maxFreq) == 3: fFreq, sFreq, mFreq = args.maxFreq
  else: raise IOError('Wrong number of frequencies fool')
  ## Simulate the subckt and get the file
  tempDir,sparamFile = cktParam.spAnalysis(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq)#,tmpTarget='.')
  subprocess.call('cp '+sparamFile+' '+cktFileName+os.path.splitext(sparamFile)[1],shell=True)
  ## Clean the directory
  if tempDir=='/tmp': subprocess.call('sleep 5 && rm -r '+tempDir+' &',shell=True)
exit(0)
