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
#   Type >> createNetlist.py -h 
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math, ckt, numtools
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
argparser = argparse.ArgumentParser(description='This creates a netlist to be run in spectre to calculate quality factors of an inductor subcircuit file.')
argparser.add_argument(dest='cktFiles', nargs='+', help='subcircuit file')
argparser.add_argument('-sim', dest='sim', choices=['scs','hsp'], help='specify the simulator')
argparser.add_argument('-sp','-sparam', dest='sp', action='store_true', help='uses sparameter where possible while building the netlist')
argparser.add_argument('-maxfreq', dest='maxFreq', nargs='+', default = ['50G'], help='Maximum frequency with units attached, default=65G. [You can also give "start stop" or "start step stop"; with units attached i.e. 10G 1G 50G]')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## run for each file specified 
for iiCktFile in args.cktFiles:
  ## Get real path of the file and decide for how many ports
  if os.path.exists(iiCktFile) and re.search(r'\.(scs|sp|hsp)$',os.path.splitext(iiCktFile)[1],flags=re.I):
    cktFile = os.path.realpath(iiCktFile); cktFileName = os.path.splitext(os.path.basename(cktFile))[0]
    indckt = ckt.read(cktFile)
  else: print('Subcircuit file '+iiCktFile+' either does not exists or is not a spectre/hspice file'); continue
  ## Set freqs
  if len(args.maxFreq) == 1: mFreq = args.maxFreq[0]; fFreq = 0.01*numtools.getScaleNum(mFreq); sFreq = fFreq
  elif len(args.maxFreq) == 2: fFreq, mFreq = args.maxFreq; sFreq = 0.01*numtools.getScaleNum(mFreq)
  elif len(args.maxFreq) == 3: fFreq, sFreq, mFreq = args.maxFreq
  else: raise IOError('Wrong number of frequencies fool')
  fFreq,sFreq,mFreq = map(numtools.getScaleNum, [fFreq,sFreq,mFreq])
  ## Create outputfile
  if args.sim == 'hsp':
    scsTuple = ckt.createHspFile('.',indckt.modelName,indckt.ports,indckt.cktFile,fFreq,sFreq,mFreq,1e9) 
  else:
    if args.sp:  scsTuple = ckt.createScsFile('.',indckt.modelName,indckt.ports,indckt.cktFile,fFreq,sFreq,mFreq)
    else: scsTuple = ckt.createACScsFile('.',indckt.modelName,indckt.ports,indckt.cktFile,fFreq,sFreq,mFreq,1e9) 

