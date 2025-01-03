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

import sys
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import csvUtils, argparse, re, tempfile, subprocess
## filter fn
def filterMe(cells,conds,key): 
  newLst = []
  for cell,cond in zip(cells,conds):
    cell = re.sub(r'.\*$','',cell,count=1)
    if re.search(r''+key,cond,flags=re.I): newLst.append(cell)
  return newLst
## runset

def createRunsetCsv():
  fid=tempfile.TemporaryFile()
  cmd = subprocess.Popen('python /p/fdk/gwa/jmarulan/utils/scripts/getBbTucDnwOa.py',stdout=subprocess.PIPE,shell=True)
  cmd = cmd.communicate()
  if cmd[1]: sys.stderr.write('Problems creating runset csv\n')
  fid.write(cmd[0]); fid.seek(0)
  result = csvUtils.dFrame(fid); fid.close();
  return result
  
## ARGUMENTS
argparser = argparse.ArgumentParser(description='Compares Reference CSV to Runset TUC/BB/TUC/OAMAP')
argparser.add_argument(dest='ref', type=csvUtils.dFrame, help='reference.csv')
argparser.add_argument('-runset', dest='runset', type=csvUtils.dFrame, help='runset.csv')
args = argparser.parse_args()
##
if not args.runset: args.runset = createRunsetCsv()

missing={}; targets = ['blackbox','tuc','dnwSupport']
for check,key in zip(targets,['yes','yes','no']):
  ## get the reference cells
  ref = filterMe(args.ref['cellName'],args.ref[check],key)
  ## get the runset cells
  runset = filterMe(args.runset['cellName'],args.runset[check],key)
  ## check that all the reference cells exist in the runset
  missing[check]=filter(lambda cc: not(cc in runset), ref)

outLst = ['#Missing in the runset but expected by US',','.join(targets)]

for ii in xrange(max(map(len,[missing[ii] for ii in missing]))):
  outLst.append(','.join([(missing[key][ii] if ii < len(missing[key]) else '') for key in targets]))

print '\n'.join(outLst)
