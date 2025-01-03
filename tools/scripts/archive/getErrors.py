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
#   Type >> getErrors.py -h
##############################################################################

## Functions
def getErrs(fname):#in a list error space count
  fetch = False; errors = []; errName=count=False; errDes = []
  with open(fname,'rb') as fin:
    for line in fin:
      if re.search(r'^\s*ERROR\s+SUMMARY',line): fetch=True
      if fetch:
        test = re.search(r'^\s*(\w+)\s*:',line)
	if test: errName = test.group(1); 
        test = re.search(r'\s+(\d+)\s+violations?\s+found',line);
	if test: count = test.group(1)
        if errName and not count: errDes.append(line.split(':')[-1].strip())
	if errName and count: 
	  if args.ignore and re.search(r''+args.ignore,errName,flags=re.I): errName=count=False; errDes=[];
	  else: errors.append(tuple([errName,count,' '.join(errDes)])); errName=count=False; errDes=[];
      if re.search(r'^\s*ERROR\s+DETAILS',line): break
  return errors #list of tuples, each tuple has error - count

def createHtml(results,flowList):
  tcLine = ''.join(['<td><h3>'+tc+'</h3></td>' for tc in results.keys()]); 
  flowLines = ''
  for flow in flowList:
    flowLines += '<tr><td>'+flow+'</td>'
    for cellName,cFlowInfo in results.items():
      entry = '<table><tr><td>'+'</td></tr><tr><td>'.join(['</td><td>'.join(ii) for ii in cFlowInfo[flow]])+'</td></tr></table>' if flow in cFlowInfo.keys() else ''      
      flowLines += '\n<td>'+entry+'</td>'
    flowLines += '</tr>\n'
  htmlStr = '''<table cellspacing="1" border="1"><tr><td><center><h3>CellName\\Flow</center></h3></td>'''+tcLine+'''</tr>
<body>\n'''+flowLines+'''\n</body></table>\n<p><i><small>Contact Mauricio HTML Productions for support<small><i><p>''' 
  fHtml = 'errorDisplay.html'
  with open(fHtml,'wb') as fOut: fOut.write(htmlStr); return fHtml
      
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, itertools, re, subprocess
import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python'); import numtools, lvqaUtils
argparser = argparse.ArgumentParser(description='Create an html report for Runset Runs')
argparser.add_argument(dest='input', nargs='+', type=lvqaUtils.targetFiles, default=[lvqaUtils.targetFiles('.')], help='Dir(s) or file(s) to compute')
argparser.add_argument('-ignore', dest='ignore', default='',type=str, help='Regular expression to ignore errors')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## Check for the input
lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();
if not any(lstFiles): raise argparse.ArgumentTypeError('File(s) or Dir(s) given aren\'t or don\'t contain ANY report files')

## Run for each file creating the table
results = {}; flowList=set();
for entry in lstFiles:
  cell,flow,tool = lvqaUtils.getEntryInfo(entry); 
  errors = getErrs(entry); flowList.update([flow])
  if cell not in results.keys(): results[cell]={}; 
  results[cell][flow] = errors if errors else 'CLEAN'    
fHtml = createHtml(results,flowList)
subprocess.call('/p/foundry/env/bin/arora '+fHtml+'&',shell=True)
exit()
