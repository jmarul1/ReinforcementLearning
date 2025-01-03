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

import argparse, csvUtils, re, subprocess, os, libUtils

# Argument Parsing
argparser = argparse.ArgumentParser(description='Create oamap from bb cdf')
argparser.add_argument(dest='target',nargs = '+',help='target')
args = argparser.parse_args()

clean = lambda ff: re.sub(r'[()"]','',ff.strip())
keys = ['cat','cell','libName','model','symbol','pins']; outputStr = ','.join(keys)+'\n'
for target in args.target:
  with open(target,'rb') as fin:    
    fetch=False; libName = "intel73custom"; cell=model=os.path.splitext(os.path.basename(target))[0]
    for line in fin:
      test = re.search(r'LIBRARY\s*=\s*(.*)',line,flags=re.I)
      if test: libName = test.group(1)
      test = re.search(r'simInfo\s*[-~]\s*>\s*auCdl',line,flags=re.I)
      if test: fetch = True; continue
      test = re.search(r'termOrder(.*)',line,flags=re.I)
      if fetch and test: pins = test.group(1); continue
      test = re.search(r'modelname(.*)',line,flags=re.I)
      if fetch and test and clean(test.group(1)): model = test.group(1)
      if fetch and re.search(r'simInfo',line,flags=re.I): break
    outputStr+=','.join(map(clean,[libUtils.getCat(cell),cell,libName,model,'symbol',pins])) + '\n'

## print 
output = csvUtils.strToDict(outputStr)
output = csvUtils.sortDict(output,keys)
sizes = map(lambda ff: max(map(len,ff)),[output[ii] for ii in keys[1:]])
cat = ''
for line in zip(*[output[ii] for ii in keys]):
  temp = libUtils.getCat(line[1])
  if cat != temp: cat = temp; print '/// '+cat
  outLine = ''
  for jj,item in enumerate(line[1:]):
    spaces = ''.join([' ' for ss in xrange(sizes[jj]-len(item))])
    outLine += item+spaces+'  '
  print outLine
