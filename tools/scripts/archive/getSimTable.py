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
#   Type >> getSimTable.py -h 
##############################################################################

def getPinLst(name,project):
  test = re.search(r'(mfc|dcp)',name)
  if not test: return []
  if test.group(1) == 'mfc':
    test = re.search(r'''.*?(?P<p73>adiff|pll|fio|alp|a|b|c)$  #73
                      |.*?mfc\d+(?P<p75>a|b|c).*               #75
		      ''',name,flags=re.X)
    if test.group('p'+project) in ['a','adiff']: pins = {'73':['p1 p2 t3 t3 t3'],'75':['t3 p1 p2 t3 t3']}.get(project) #p1-p2
    elif test.group('p'+project)=='b': pins = ['p1 p2 t3'] #p1-p2,
    elif test.group('p'+project)=='c': pins = ['p1 p2'] #p1-p2,
    elif test.group('p'+project) in ['alp','pll','fio']: pins = ['p1 p2 t3 t3'] #p1-p2,p1-lowsh,p2-lowsh
    else: pins=[]
  else:
    if re.search(r's2s$',name): pins = ['p1 p2 t3']
    elif re.search(r'phvm2$|dcpip.h',name): pins = ['p1 t3 p2']
    else: pins = ['p1 p2']      
  return pins
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, subprocess, tempfile, ckts
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
project = {'fdk73':'73','fdk71':'71','f1275':'75'}.get(os.getenv('PROJECT'))
argparser = argparse.ArgumentParser(description='Generates a table with FEQA Values from Simulation')
argparser.add_argument(dest='subckts', nargs='+', help='subcircuit names')
argparser.add_argument('-sim', dest='sim', choices=['scs','hsp'], default='scs', help='simulator')
argparser.add_argument('-skew', dest='skew', choices={'73':['rfff','tttt','rsss'],'75':['ffff','tttt','ssss','ffvss','ssvff']}.get(project), default='tttt', help='skew')
argparser.add_argument('-includes', dest='includes', type=ckts.readInc, help='Include overwrite, plain text, no comments allowed')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import sparameter as sp, ckt, numtools

## set the frequencies
fFreq, sFreq, mFreq = map(numtools.getScaleNum, ['1M','1M','5M'])
## get the include files
includes,upfVersion = args.includes if args.includes else ckts.getIncludes(args.sim,project,args.skew)
## create working dir
tempDir = os.path.realpath(tempfile.mkdtemp(dir='.'));
## Output
outLst = ['cellName,CmainDiff(fF)']
## run for all subcksts
for subckt in args.subckts:
 ## check the subckt exist
  if not ckts.checkSub(subckt,includes): sys.stderr.write('ERROR: '+subckt+' subckt does not exist\n'); continue
 ## determine the pins based on the type/technology
  pinLst = getPinLst(subckt,project)
 ## get all caps
  caps = []
  for pins in pinLst: #store in this order: p1-p2
   ## create the circuit file and place the subckt
    cktFile = tempfile.mkstemp(dir=tempDir,prefix=subckt+'_',suffix='.'+args.sim)[1]  
    pref = '' if args.sim == 'scs' else '.'
    ter = 'rterm t3 0 resistor r=1u\n' if args.sim =='scs' else 'rterm t3 0 1u\n'
    with open(cktFile,'wb') as fout: fout.write(includes+pref+'subckt testme p1 p2\nxCapMfc '+pins+' '+subckt+'\n'+ter+pref+'ends testme\n')
    cktParam = ckt.read(cktFile)
    if args.sim == 'scs':
      freq,Qd,Cd,Qse,Cse,Rd,Rse= cktParam.getQPR(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='cap')
    else: 
      freq,Qd,Cd,Rd=cktParam.getQPR_AC(firstFreq=fFreq,stepFreq=sFreq,lastFreq=mFreq,device='cap',sim='hsp',rEnd=1e9)    
    caps.append(Cd[0])
  outLst.append(','.join([subckt]+map(lambda ff: numtools.numToStr(ff,3),caps)))
outLst.append('##'+args.sim)
## print the full list
print '\n'.join(outLst)
## erase working directory
subprocess.Popen('sleep 5; rm -rf '+tempDir,shell=True)
exit(0)
