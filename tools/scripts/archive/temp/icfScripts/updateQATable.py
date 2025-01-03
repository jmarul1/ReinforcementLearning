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
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> updateQATable.py -h 
##############################################################################

def prepareInput(path):
  import os, re, sys
  if not os.path.isdir(path): raise argparse.ArgumentTypeError('Path doesn\'t exist: '+path)
  test = re.search(r'(pcell|pycell)',path)
  if test: return test.group(1),path
  else: print >> sys.stderr,'Path does not specify pcell/pycell, "pcell" assumed'; return 'pcell',path
  
def format(wb,**kArgs):
  import xlsxwriter as xls
  link_f = wb.add_format({'color':'blue','underline':1})
  heading_f = wb.add_format({'color':'black','bg_color':'#FFCC99','bold':True,'align':'left','font_size':11})
  request = kArgs.get('tipo','default')
  semiDef = wb.add_format({'font_size':kArgs.get('size',10),'color':kArgs.get('color','black'),'bold':kArgs.get('bold',False),'align':kArgs.get('align','center')})
  return {'hyperlink':link_f,'heading':heading_f,'default':semiDef}.get(request)

def owner(category):
  import re
  ownDt = {'varactor':'Seo','decap':'Alex','mfc':'CT','tmdio':'Alex','cpr':'Alex','tcn':'Alex','pattern':'CT','hybrid':'Alex','gnac':'Alex','esd_wrappers':'Matt','bgdio':'Alex','ind':'Mauricio','scalable':'Mauricio','esd':'Anish','dnw_mvs':'CT'}
  test=re.search(r'(varactor|decap|mfc|tmdio|cpr|tcn|pattern|hybrid|gnac|esd_wrappers|bgdio|ind|scalable|esd|dnw_mvs)',category,flags=re.I)
  if test: return ownDt.get(test.group(1).lower(),'Mauricio')
  else: return 'Mauricio'

def getDispoDt(inCsv):
  import csvUtils
  newDict={'template':[],'dispo':[],'ar':[]}; dt = csvUtils.dFrame(inCsv);
  for ii,oatype in enumerate(dt['OATYPE']):
    newDict['template'].append('#'.join([oatype,dt['FLOW'][ii],dt['CATEGORY'][ii]]))
    newDict['dispo'].append(decodeMe(dt['ERROR_COMMENTS'][ii]))
    newDict['ar'].append(decodeMe(dt['AR'][ii]))
  return newDict

def decodeMe(string):
  try: string.encode('ascii','ignore')
  except UnicodeDecodeError: return 'ASCII ISSUE'
  else: return string

##############################################################################
# Argument Parsing
##############################################################################
import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import argparse, os, re, xlrd
argparser = argparse.ArgumentParser(description='Update the excel sheet with tab comments')
argparser.add_argument(dest='qa', help='Path to the qa excel table')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
mainName = u'A'; commentInd = 6
excelObj = xlrd.open_workbook(args.qa);
sheets = excelObj.sheet_names()
## look for the A sheet
mainSh = excelObj.sheet_by_name(mainName); dt={}
## go line by line
for rr in xrange(mainSh.nrows):
  cells = filter(lambda ff: ff.ctype!=0,mainSh.row(rr))
  if len(cells) < 3: continue
  ## get the flow and cell
  flow = unicode(cells[2].value)
  cell = cells[0].value
  ## find the sheet and get the cell comment
  if flow not in sheets: continue
  testSh = excelObj.sheet_by_name(flow)
  if flow not in dt.keys(): dt[flow] = map(lambda ff: ff.value,testSh.col(0))
  if cell in dt[flow]: found = testSh.cell(dt[flow].index(cell),commentInd).value
  else: continue
  print cell, flow, found
