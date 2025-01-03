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
#   Type >> averageCsvs.py -h 
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, csv
argparser = argparse.ArgumentParser(description='This program takes the median across all csv files.')
argparser.add_argument(dest='csvFiles', nargs='+', help='csv file(s)')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: average.csv')
argparser.add_argument('-mean', dest='mean', action='store_true', help='choose mean, default is median')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import numpy as nu, csvUtils

## run for each csv specified 
csvDFs={}
for iiCsvFile in args.csvFiles: csvDFs[iiCsvFile] = csvUtils.dFrame(iiCsvFile,text=False)
## get the keys for the columns as they are consistent
colKeys = csvDFs[iiCsvFile].keys()
## average each line accross all columns
aveEntry = {}
for iiCol in colKeys:
  entry = []
  for iiCsv,iiData in csvDFs.items():
    entry.append(iiData[iiCol])  
  aveEntry[iiCol] = nu.mean(nu.array(entry),axis=0).tolist() if args.mean else nu.median(nu.array(entry),axis=0).tolist()
## prepare the data
results = ','.join(colKeys) + '\n';
for iiRow in xrange(len(aveEntry[colKeys[0]])):
  results += ','.join(map(str,[aveEntry[colKey][iiRow] for colKey in colKeys]))+'\n'
#print results if csv enable print values in csv file ## else print to the prompt
if args.csvFile:
  with open('average.csv','w') as fout:
    fout.write(results)
else: print(results)
exit(0)
