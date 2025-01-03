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
  for index,cell in enumerate(rowLst): 
    if type(cell) == str or type(cell) == unicode:
      if cell and re.search(r'^\s*'+val,cell): 
        if all: outInd.append(index) 
	else: outInd = index; break
    else:
      if cell.ctype != 0 and re.search(u'^\s*'+val,cell.value):
        if all: outInd.append(index) 
	else: outInd = index; break
  return outInd

def getCells(lvqa,cats=None):
  lista = os.listdir(lvqa)
  finalLst = []
  for ii in lista:
    test = os.path.join(lvqa,ii,'lvqaConfig','text.txt')
    if os.path.isfile(test): finalLst.append(tuple([ii,test]))
  return finalLst  

def readFile(path):
  with open(path) as fid:
    results = {}; category=False; cDot=False 
    for rawLine in fid:
      line = rawLine.split('#')[0].strip() #ignore comments and extra
      if line:
        test = re.search(r'set_devcat\s+(\w+)',line)
	if test: category = test.group(1)
        test=re.search(r':select\s+DOT\s*=\s*(\d+)',line)
	if test: 
	  cDot = 'DOT'+test.group(1); 
	  if cDot not in results.keys(): results[cDot] = {}
	test=re.search(r'set_(\w+?)_flows\s+(.+)',line); 
	if test and cDot: results[cDot][test.group(1)] = test.group(2).split() if test.group(2).split() else []
  return category,results

def csvWrite(sheetObj,row,col,csvStr):
  for iiCol,data in enumerate(csvStr.split(',')): sheetObj.write(row,col+iiCol,data)

def envCheck():
  import os
  project = os.getenv('PROJECT'); errStr = 'Please run this in an environment window, dbmenu, fdk, etc.'
  if project.strip() != '':
    effEnv = {'f1275':'tld75'}.get(project,project)
    return {'fdk73':'intel73lvqa_coverage.xls','f1275':'intel75lvqa_coverage.xls'}.get(project),effEnv
  else: raise EnvironmentError(errStr)  
  
##############################################################################
# Argument Parsing
##############################################################################
fileOutName,env = envCheck() #Error Checking
import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import argparse, os, re, xlwt, numtools, time
argparser = argparse.ArgumentParser(description='Creates a XLS file "intel${project}lvqa_coverage.xls" with cells and flows being used in the LVQA library [by default the lvqa in the current setup]')
argparser.add_argument('-cat', dest='cat', help='Specify a category')
argparser.add_argument('-lvqaLib', dest='lvqaLib', default = os.path.join(os.getenv('FDK_MANAGED_AREA'),env,'oalibs/common/intel'+env[-2:]+'lvqa'), help='Path to the LVQA library')
argparser.add_argument('-dot', dest='dot', nargs='?', const=os.getenv('FDK_DOTPROC'), help='Specify a dot to print csv string')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
if args.dot: args.dot = 'DOT'+args.dot; fileOutName = '/tmp/erase_intel73lvqa_coverage.xls'
else: print "\nReading the lvqa library"; time.sleep(1)
## get the list of cells
listOfCells = getCells(args.lvqaLib); 
cellFlowLst,totalFlows=[{},{}]
for ll,item in enumerate(listOfCells):
  cell,filePath = item
  cat,flows = readFile(filePath)
  if cat:
    if cat not in cellFlowLst: cellFlowLst[cat] = [];
    cellFlowLst[cat].append(tuple([cell,flows]))
  for ii in flows.keys(): ## for each dot
    for jj in flows[ii].keys(): 
      if jj not in totalFlows: totalFlows[jj] = set(flows[ii][jj])
      else: totalFlows[jj].update(flows[ii][jj])
## create workbook
outWbk = xlwt.Workbook()
## figure out flows to print and prepare first two lines of string
fLine = '#FLOWS,'; sLine='Category,TestCase'
for ii in sorted(totalFlows.keys()):  
  fLine+=','+','.join(ii for jj in totalFlows[ii]); 
  sLine+=','+','.join(sorted(totalFlows[ii]))
import time
## put an x for each flow that exists in the testcase
sheets = {}; outLst=[]
for cat in sorted(cellFlowLst): ## traverse through each category
  for cell,flows in cellFlowLst[cat]: ## go through each cell in the category
    for dot in sorted(flows.keys()):   ## go for each dot 
      ## initialize the sheet if necessary then put the first two line
      if dot not in sheets.keys():
        sheets[dot]={}
        sheets[dot]['shObj']=outWbk.add_sheet(dot) 
	sheets[dot]['rrC']=0
	csvWrite(sheets[dot]['shObj'],sheets[dot]['rrC'],0,fLine); sheets[dot]['rrC']+=1 
	csvWrite(sheets[dot]['shObj'],sheets[dot]['rrC'],0,sLine); sheets[dot]['rrC']+=1
	if args.dot and dot == args.dot: outLst.append(fLine); outLst.append(sLine)
      ## create the string testcase with x in the flows and write in on the sheet Obj
      lineLst = [cat,cell] 
      for tt in sorted(totalFlows.keys()):
        for ff in sorted(totalFlows[tt]):
  	  markSt = 'X' if tt in flows[dot] and ff in flows[dot][tt] else ''
	  lineLst.append(markSt)
      csvWrite(sheets[dot]['shObj'],sheets[dot]['rrC'],0,','.join(lineLst)); sheets[dot]['rrC']+=1
      if args.dot and dot == args.dot: outLst.append(','.join(lineLst))      
## save the file
outWbk.save(fileOutName)
## print the string or the info to the prompt
if args.dot: print '\n'.join(outLst)
elif os.path.isfile(fileOutName):
  print '(Remember to keep your LVQA library fully populated)'
  print '\nThe file "./'+os.path.relpath(fileOutName)+'" has the LVQA coverage tables\n'
else: print >> sys.stderr, 'Errors writing the output file, please consult your dealership'
