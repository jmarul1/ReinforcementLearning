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
#   Type >> getMfcSimTable.py -h 
##############################################################################

def getPinName(pins,template):
  lstNames = ['Cmain(fF)','Clowsh1(fF)','Clowsh2(fF)','Cupsh1(fF)','Cupsh2(fF)'] #MFC
  lstAssign = [['mfcport1 mfcport2','mfcport1 vss','mfcport1 mfcvcc','capvcc pgate','capvcc vss','capsig ngate','ngate vss']] #main
  lstAssign.append(['mfcport1 mfclowershield','capvcc midnode']); lstAssign.append(['mfcport2 mfclowershield','midnode vss']) #lower
  lstAssign.append(['mfcport1 mfcuppershield']); lstAssign.append(['mfcport2 mfcuppershield']) #upper
  pins = map(lambda ff: ff.split('_')[0],pins.split(' '))
  pins = map(lambda ff: re.sub(r'(vss)x$',r'\1',ff,flags=re.I), pins)
  for ii,test in enumerate(lstAssign): 
    if (' '.join([pins[0],pins[1]]) in test) or (' '.join([pins[1],pins[0]]) in test): return lstNames[ii]
  return False
    
def getLineInfo(line,template):
  test = re.search(r'(\S+)\s+(\S+)\s+(\S+).*?\*.*?('+numExp+'\w?)',line)
  if test: 
    pins = ' '.join([test.group(2),test.group(3)]);     
    value = str(numtools.getScaleNum(test.group(4))*1e15)
#    value = test.group(4)
    return getPinName(pins,template),value
  return False    

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
argparser = argparse.ArgumentParser(description='Generates a table with Cap Values from the model files for MFCs and Decaps')
argparser.add_argument(dest='model', nargs='+', type=file, help='Model file(s)')
argparser.add_argument('-template',dest='template',default='mfc|dcp', help='Template category expression')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import csvUtils as csv, numtools

## Output
keys = ['cellName','Cmain(fF)','Clowsh1(fF)','Clowsh2(fF)','Cupsh1(fF)','Cupsh2(fF)']
## run for all files
entangle=False; dt = {}
numExp = '([+-]?\d+)(\.\d*)?(?:[eE]([+-]?\d+))?'
for model in args.model:
  for line in model:
    line = line.strip()
    ## skip comments
    if re.search(r'^\*',line): continue
    line = line.split('$')[0]
    test = re.search(r'^\.?subckt\s+(\S+)\s+(.*)',line,flags=re.I)
    if not(entangle) and test: subckt = test.group(1); pins=test.group(2).split(); entangle=True; continue## find the SUBCKT and pins
    test = re.search(r'^\.?ends',line,flags=re.I)
    if entangle and test: entangle=False; continue
    if entangle and re.search(r''+args.template,subckt,flags=re.I): 
      info = getLineInfo(line,args.template)
      if info:
        if subckt not in dt.keys(): dt[subckt]={}
        dt[subckt][info[0]] = info[1]
## print the dictionary
outLst = [','.join(keys)]
subcktLst = sorted(filter(lambda ff: re.search(r'mfc',ff,flags=re.I),dt.keys()))+sorted(filter(lambda ff: re.search(r'dcp',ff,flags=re.I),dt.keys()))
for subckt in subcktLst:
  outLst.append(','.join([subckt]+[dt[subckt][key] for key in keys if key in dt[subckt].keys()]))
print '\n'.join(outLst)
exit(0)
