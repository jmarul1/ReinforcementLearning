#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret							     #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.  	     #
#									     #
# This is the property of Intel Corporation and may only be utilized	     #
# pursuant to a written Restricted Use Nondisclosure Agreement  	     #
# with Intel Corporation.  It may not be used, reproduced, or		     #
# disclosed to others except in accordance with the terms and		     #
# conditions of such agreement. 					     #
#									     #
# All products, processes, computer systems, dates, and figures 	     #
# specified are preliminary based on current expectations, and are	     #
# subject to change without notice.					     #
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def isInList(inStr,lista):
  import os, re
  inStr = os.path.splitext(inStr)[0]
  for ii in lista:
    ii = os.path.splitext(ii)[0]
    if re.search(r''+args.prefix+'.*?'+inStr,ii): return True
  return False

## MAIN ##
import argparse, os
argparser = argparse.ArgumentParser(description='This finds missing files in dir 2 using dir 1 files')
argparser.add_argument('-main', dest='main', help='Main directory')
argparser.add_argument('-test', dest='test', help='Test directory')
argparser.add_argument('-mainext', dest='mainext', help='Main directory extension')
argparser.add_argument('-testext', dest='testext', help='Test directory extension')
argparser.add_argument('-common', dest='common', action='store_true', help='Test directory extension')
argparser.add_argument('-prefix', dest='prefix', default='', help='Regular expresion to prefix the Test directory files')
args = argparser.parse_args()
##
files = os.listdir('.')
mainFiles = filter(lambda ff: os.path.splitext(ff)[1] == args.mainext, os.listdir(args.main))
testFiles = filter(lambda ff: os.path.splitext(ff)[1] == args.testext, os.listdir(args.test))

output = []
for ii in mainFiles:
  if args.common:
    if isInList(ii, testFiles): output.append(ii)
  elif not isInList(ii, testFiles): output.append(ii)

if any(output): 
  for ii in output: print ii
else: print '\nPerfect match\n'
