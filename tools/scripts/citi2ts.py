#!/usr/bin/env python3.7.4
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
##############################################################################

def convertToSp(path,outName,ext):
  """Run citi2ts and put in the cwd"""
  import subprocess as sb, os
  if sb.call(os.path.expanduser('~jmarulan/work_area/utils/scripts/citi2ts')+' '+path,shell=True) == 0:
    srcName = os.path.basename(os.path.splitext(path)[0])+ext; outName += ext
    if not(os.path.realpath(os.getcwd())==os.path.realpath(os.path.dirname(path)) and srcName==outName):
      sb.call('mv '+os.path.dirname(path)+'/'+srcName+' '+outName,shell=True)
    return True
  else: return False

def calcRange(argsIn):
  citiObj = argsIn.citi[0]
  dT = vars(argsIn); offset=0; suffix=''
  for ii in range(len(citiObj.VAR)-1):
    size = reduce(lambda x,y: x*y,[ff[2] for ff in citiObj.VAR[ii+1:]])
    offset += size*(citiObj.VAR[ii][3].index(dT[citiObj.VAR[ii][0]])) #get the index of the value
    suffix += '_'+numtools.numToStr(dT[citiObj.VAR[ii][0]]).replace('.','p')+'_'+citiObj.VAR[ii][0]
  return list(range(offset,offset+citiObj.VAR[-1][2])),suffix  

def getOuts(data):
  out=[]; indDict={}; sp=[]
  for ii,val in enumerate(data):
    if re.search(r'^S',val[1],flags=re.I): sp.append(ii)
    else: out.append(val[1]); indDict[val[1]] = [ii]
  if sp: indDict['S'] = sp; out=['S']+out
  return out,indDict
  
##############################################################################
# Argument Parsing
##############################################################################
import sys, argparse, os, re, subprocess as sb, citi, operator, tempfile, numtools
from functools import reduce
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
tempParser = argparse.ArgumentParser(add_help=False)
tempParser.add_argument(dest='citi', nargs='+', type=citi.read, help='CITI file(s)'); 
if any([re.search('-h|--help',ii) for ii in sys.argv[1:]]) or len(sys.argv[1:]) == 0: tempParser.print_help()
temp = tempParser.parse_known_args()[0];
argparser = argparse.ArgumentParser(parents=[tempParser],description='Convert CITI to Sparameter based on the input if any'); kOps=[]
for options in [var for var in temp.citi[0].VAR[:-1]]: #ignore the last element
  kOps.append(options[0]) ## future enhancement
  argparser.add_argument('-'+options[0],dest=options[0],choices=options[3],default=options[3][0],help='Select one value for '+options[0]+', defaults to "'+options[3][0]+'"')
options,indDict = getOuts(temp.citi[0].DATA)
argparser.add_argument('-out',dest='out',choices=options,default=options[0],help='Output value, defaults to "'+options[0]+'"')
args = argparser.parse_args()
##calculate the range for the Parameters to be extracted
effRangeI,suffix = calcRange(args); 
effRange = operator.itemgetter(*effRangeI); effOutInd = indDict.get(args.out);#print effRangeI; exit()
## foreach citifile given
for citiClass in args.citi:
  if kOps:
    outLst = ['CITIFILE '+citiClass.version]
    outLst.append('NAME '+citiClass.dataKey)
    outLst.append('VAR '+' '.join(map(str,citiClass.VAR[-1][0:-1])))
    for ii in effOutInd: outLst.append(' '.join(citiClass.DATA[ii][:-1]))
    outLst.append('VAR_LIST_BEGIN\n'+('\n'.join(citiClass.VAR[-1][-1]))+'\nVAR_LIST_END')	
    for ii in effOutInd: outLst.append('BEGIN\n'+('\n'.join(effRange(citiClass.DATA[ii][-1])))+'\nEND')
    ## create the new citi and convert
    tempCiti=tempfile.mkstemp(suffix='.citi')[1]
    with open(tempCiti,'wb') as fOut: fOut.write('\n'.join(outLst));
  else: tempCiti=os.path.relpath(citiClass.filename)
  outName,ext = os.path.basename(os.path.splitext(citiClass.filename)[0])+suffix,'.s'+str(citiClass.portNum)+'p'  
  if not convertToSp(tempCiti,outName,ext): sys.stderr.write('Could not create touchstone sparameter for: '+tempCiti+'\n')

