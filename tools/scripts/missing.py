#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret							     #
##############################################################################
# Copyright (C) 2020, Intel Corporation.  All rights reserved.  	     #
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

def matchI(regex,string): 
  test = re.search(r''+regex,string)
  if test and any(test.groups()): return ''.join(test.groups())
  else: return string 

## MAIN ##
import argparse, os, re, pandas as pd
argparser = argparse.ArgumentParser(description='Compare files inside two directories and print common, only in dir1, and only in dir2')
argparser.add_argument(dest='dir1', help='Directory 1')
argparser.add_argument(dest='dir2', help='Directory 2')
argparser.add_argument('-regex1', dest='regex1', default='.*', help='Directory 1 regular expression')
argparser.add_argument('-regex2', dest='regex2', default='.*', help='Directory 2 regular expression')
args = argparser.parse_args()
##
dir1 = pd.Index(list(map(lambda ff: matchI(args.regex1,ff), os.listdir(args.dir1) )))
dir2 = pd.Index(list(map(lambda ff: matchI(args.regex2,ff), os.listdir(args.dir2) )))
col1 = pd.Series(dir1.difference(dir2),name=os.path.basename(args.dir1)+'_only'); col2 = pd.Series(dir2.difference(dir1),name=os.path.basename(args.dir2)+'_only')
common = pd.Series(dir1.intersection(dir2), name = 'Common')
out = (pd.concat([common,col1,col2],axis=1))
print(out.to_string())
