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
#   Type >> csvToXlsxSheets.py -h 
##############################################################################

## Functions
import sys, os
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import argparse, numtools
def greaterThanOne(number):
  if numtools.isNumber(number) and number.isdigit() and int(number) >=1: return int(number)
  else: raise argparse.ArgumentTypeError('invalid int or < 1 value: \''+number+'\'')
  
##############################################################################
# Argument Parsing
##############################################################################
argparser = argparse.ArgumentParser(description='Combines a list of csv files into a single excel file')
argparser.add_argument(dest='csvFiles', nargs='+', help='csv file(s)')
argparser.add_argument('-filter', dest='filter', nargs='?', type=greaterThanOne, default=1, const=1, help='add auto filter to the specified by default first row. (not relevant for gnumeric compatible files)')
argparser.add_argument('-gnumeric', dest='gnumeric', action='store_true', help='make the output file gnumeric compatible')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import os, csv, re, xlwt
import xlsxwriter as xls

outWbk = xlwt.Workbook() if args.gnumeric else xls.Workbook('csvCompilation.xlsx')
csvFiles = set(args.csvFiles); sheetNameLst = []
for iiFile in csvFiles:
  if os.path.exists(iiFile):
    # Read the file in csv
    tempData = os.path.splitext(os.path.basename(iiFile))[0][0:28]
    sheetName = tempData
    for cc in xrange(100): 
      if sheetName in sheetNameLst: sheetName= tempData+'_'+str(cc)
      else: break
    print sheetName
    sheetNameLst.append(sheetName)
    if cc == 100: raise IOError('Too many sheets with the same name, seriously what the heck')
    sheet = outWbk.add_sheet(sheetName) if args.gnumeric else outWbk.add_worksheet(name=sheetName)
    csvData = csv.reader(open(iiFile, 'rb'), delimiter=',')
    # print the file in excel to a sheet
    lenFilterRow = 1
    for rowData in csvData:
      for column in range(len(rowData)):
        if numtools.isNumber(rowData[column]): sheet.write(int(csvData.line_num-1),int(column),float(rowData[column]))
	else: sheet.write(int(csvData.line_num-1),int(column),rowData[column])
      if csvData.line_num == args.filter: lenFilterRow = len(rowData) 
    if not args.gnumeric and args.filter:
      rowFilter = str(args.filter)
      sheet.autofilter('A'+rowFilter+':'+numtools.numToLetter(lenFilterRow)+rowFilter)
# Save it
if args.gnumeric: outWbk.save('csvCompilation.xls') 
else: outWbk.close()
