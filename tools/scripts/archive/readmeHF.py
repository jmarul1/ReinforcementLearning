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
#   Type >> readmeHF.py -h 
##############################################################################

## imports
import argparse, os, sys, re
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import libUtils

def cleanUp(items):
  if not items: return items
  newLst = []
  for ii in items:
    if re.search(r'^diff$|^nbjob',ii,flags=re.I): continue
    newLst.append(re.sub(r'(_mask)?(drawing|bc)$','',ii,flags=re.I))
  return set(map(str.lower,newLst))

##############################################################################
# Argument Parsing
##############################################################################
argparser = argparse.ArgumentParser(description='Creates the readme file based on HF libQA')
argparser.add_argument(dest='csv', nargs='+',help='csv file(s)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

for iiCsv in args.csv:
  startF = False; results = {}
  with open(iiCsv) as fin:
    for line in fin:
      if not startF:
        if re.search(r'LIB/CELL,',line,flags=re.I): startF = True
	continue
      if re.search(r'^\s*#|^\s*$',line): continue
      # start
      line = line.strip()
      test = re.search(r'(?:\w+/)?(\w+)\s*,\s*(\w+)',line)
      if test: #got a cell 
        cell=test.group(1); status = test.group(2); 
	results[cell] = [status]
	fetch=True; continue
      if fetch: #cell has more details 
        details = line.split(',')[1]
	details = re.search(r'(\w+)',details).group(1) #get the word
	results[cell].append(details)
    ## analyze the data  
    diff = {}; new = {}
    for cell,items in results.items():
      cat = libUtils.getCat(cell)
      if items[0].lower() == 'clean': continue
      if items[0].lower() == 'new':
        if cat not in new.keys(): new[cat] = {}
        if 'NEW' not in new[cat].keys(): new[cat]['NEW'] = []       
        new[cat]['NEW'].append(cell)
      else:
        if cat not in diff.keys(): diff[cat] = {}
	items = cleanUp(items)
	#split fill blockages
	blck = []
	for ff in items:
	  test = re.search(r'(\w+)_fillblockage',ff)
	  if test: blck.append(test.group(1))
	blck = 'Fill blockages update to "'+','.join(sorted(blck))+'" for intended routing' if blck else ''
        #get the rest
	items = filter(lambda ff: not re.search(r'^\w+fillblockage$',ff),items)
	items = ('Updates to "'+','.join(items)+'" for runset compliance') if items else ''	
	##place the values
	if blck != '':
	  if blck not in diff[cat].keys(): diff[cat][blck] = []
	  diff[cat][blck].append(cell)
	if items != '':  
  	  if items not in diff[cat].keys(): diff[cat][items] = []
	  diff[cat][items].append(cell)
    ## print the values
    for jj,eff in enumerate([new,diff]):
      print 'New Collateral:' if jj ==0 else 'Details of Collateral Changes:'
      for ii,main in enumerate(eff.items()):
        cat,item = main
	if ii != 0: print 
        print cat
        for docInfo,cells in item.items():
          print ('- '+docInfo+' on:\n    '+'\n    '.join(cells)) if jj==1 else '  '+'\n  '.join(cells)
      print
