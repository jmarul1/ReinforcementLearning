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
#   Type >> getViol.py -h 
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='This extracts violations greater than the value provided.')
argparser.add_argument(dest='srcFile', help='Layout Error File')
argparser.add_argument('-rule', dest='rule', default='LD_212', help='the rule that must be checked')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

import sys, re, math
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import sparameter as sp

## Get real path of the file 
if os.path.exists(args.srcFile):
  srcFile = os.path.realpath(args.srcFile); destFileName = os.path.splitext(os.path.basename(args.srcFile))[0]
  violation = args.rule
else: print('Layout Error File '+args.srcFile+' does not exists'); exit(1)

## open the file 
with open(srcFile) as fidIn:
  startErrAnal = False
  for line in fidIn:
    if re.search(r''+violation,line) and startErrAnal == False:
      startErrAnal = True
      continue
    if startErrAnal:
      print line
    
    
