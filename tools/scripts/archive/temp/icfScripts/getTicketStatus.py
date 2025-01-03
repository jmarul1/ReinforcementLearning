#!/usr/bin/env python2.7
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
#   Type >> getQACover.py -h 
##############################################################################

def findVal(rowLst,val,all=False):
  outInd = [] if all else None
  test = re.compile(r'\b'+val,flags=re.I)
  for index,cell in enumerate(rowLst): 
    if type(cell) in [str,unicode]: # compare strings
      if cell and test.search(cell): 
        if all: outInd.append(index) 
	else: outInd = index; break
    else:
      if cell.ctype in [0,1,2,3] and test.search(unicode(cell.value)): #compare cells with str/num only
	if all: outInd.append(index) 
	else: outInd = index; break
  return outInd

def createTT(specSh):
## create ticket tuples
  output = []; idIndex = commIndex = None;
  for rr in xrange(specSh.nrows):
    lineLst = specSh.row(rr)
    if idIndex == None: ## find the id
      test = findVal(lineLst,'id');
      if test != None:
  	idIndex = test; commIndex = findVal(lineLst,'(Notes?|Comments?)'); continue
    else: ## we have an id
      idVal = str(int(lineLst[idIndex].value)) if lineLst[idIndex].ctype in [1,2,3] and numtools.isNumber(lineLst[idIndex].value) else ''
      commVal =  lineLst[commIndex].value.encode('ascii','ignore') if commIndex!=None and lineLst[commIndex].ctype in [1,2,3] else ''
      output.append(tuple([idVal,commVal]))
  return [ff for ff in output if numtools.isNumber(ff[0])]
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math
argparser = argparse.ArgumentParser(description='Updates tickets sheet with new tickets from the input file if given')
argparser.add_argument(dest='newTickets',type= lambda ff: os.path.splitext(ff)[1] in ['.xls','.xlsx'] and ff, help='New excel file with new tickets under sheetName Sheet1')
argparser.add_argument('-src', dest='srcFile', default=os.path.join(os.getenv('transferDir'),'TLD Ticket System.xlsx'), help='Excel Sheet where current tickets are (will use the latest date sheet \"YYwwWW\"')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import xlrd, numtools, xlsxwriter as xls, time

## Open the src Excel Sheet and new Excel/Csv
if not os.path.isfile(args.srcFile): raise IOError('File does not exist :'+args.srcFile)
if not os.path.isfile(args.newTickets): raise IOError('File does not exist :'+args.newTickets)

## Get the old ticket tuples
xlsObj = xlrd.open_workbook(args.srcFile)
try: sheetName = sorted(filter(lambda ff: re.search(r'(\d+)?ww\d+(\.\d)?',ff,flags=re.I),xlsObj.sheet_names()))[-1]
except IndexError: raise IOError('File has wrong sheet names: '+','.join(xlsObj.sheet_names()))
specSh = xlsObj.sheet_by_name(sheetName)
oldTT = createTT(specSh); oldTickets = [ff[0] for ff in oldTT]; 

## Get the latest ticket sheet and attach the old comment and create a new file
xlsObj = xlrd.open_workbook(args.newTickets)
try: sheetName = filter(lambda ff: re.search(r'Sheet\d+|new',ff,flags=re.I),xlsObj.sheet_names())[-1]
except IndexError: raise IOError('File has wrong sheet names: '+','.join(xlsObj.sheet_names()))
specSh = xlsObj.sheet_by_name(sheetName)
## Create new sheet workbook 
outWbk = xls.Workbook(os.path.join(os.path.dirname(os.path.realpath(args.srcFile)),'output.xlsx'))
newSh  = outWbk.add_worksheet(time.strftime('%y'+'ww'+str(int(time.strftime('%W'))+1)))
idIndex = commIndex = None;
for rr in xrange(specSh.nrows):
  lineLst = specSh.row(rr)
  ## write the line
  for cc,cell in enumerate(lineLst):
    newSh.write(rr,cc,cell.value)
  if idIndex == None: ## find the id
    test = findVal(lineLst,'id');
    if test != None: idIndex = test; newSh.write(rr,len(lineLst),'Notes/Comments')
  else: ## we have an id
    idVal = str(int(lineLst[idIndex].value)) if lineLst[idIndex].ctype in [1,2,3] and numtools.isNumber(lineLst[idIndex].value) else None
    if idVal != None: # look and place the comment
      comm = oldTT[oldTickets.index(idVal)][1] if idVal in oldTickets else ''
      newSh.write(rr,len(lineLst),comm)
outWbk.close()
