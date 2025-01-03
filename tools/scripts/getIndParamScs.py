#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
 
## ARGS ##
import sys, os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'));
import argparse, itertools, getIndParamCsv, ckt
argparser = argparse.ArgumentParser(description='Creates CKT Param list (R,C,L,K) based on SCS')
argparser.add_argument(dest='input', nargs ='+',help='Input files')
args = argparser.parse_args();

## MAIN ##

## GET THE CIRCUIT ELEMENTS and UPDATE THE MAIN KEYS for each file
cktKeys = set(); cktItems = {}
for iiFile in args.input:
  effName = os.path.basename(os.path.splitext(iiFile)[0])
  rlckDt = ckt.read(iiFile,full=True).rlck
  cktKeys.update(rlckDt.keys())
  cktItems[effName] = rlckDt

## GET THE SECOND PART OF THE HEADER (CKT ELEMENT LABELS)
cktKeys = sorted(cktKeys)

## Create the results lst 
results = []; 
for effName in sorted(cktItems.keys()):
  ## GET THE DIMENSIONS from the file name
  dims,dimVals = getIndParamCsv.getParamDims(effName); passiveVals = []
  ## GET THE CKT ELEMENT VALUE
  for passive in cktKeys:
    if passive in cktItems[effName].keys(): passiveVals.append(cktItems[effName][passive])
    else: passiveVals.append('NA')  
  results.append(','.join(dimVals+passiveVals+[effName]))
## COMBINE THE TWO HEADERS
results.insert(0,dims+','+(','.join(cktKeys))+',fileName');

## PRINT ##
print '\n'.join(results)
exit()  

