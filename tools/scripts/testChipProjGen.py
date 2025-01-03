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
##############################################################################

def padCoor(): origin = tuple([55.441,1974.24]); pitch = tuple([0,-397.44]); return origin,pitch
  
def checkFile(path):
  import csvUtils
  csv = csvUtils.dFrame(path)
  return csv

def getKeys(keys):  ## get the keys
  import re
  coorK = rowK = dutK = False
  for kk in keys:
    if re.search(r'coord',kk,flags=re.I): coorK = kk
    elif re.search(r'rowName',kk,flags=re.I): rowK = kk
    elif re.search(r'dutName',kk,flags=re.I): dutK = kk
  if not all([coorK,rowK,dutK]): raise IOError('Bad header keys for input file')
  return rowK,dutK,coorK

def getRowData(csv):
  import re
  rowK,dutK,coorK = getKeys(csv.keys())
  rowData = {}; padOr,padPitch = padCoor()
  for row,dut,coor in zip(csv[rowK],csv[dutK],csv[coorK]):
    if row not in rowData.keys(): rowData[row] = []
    coor = tuple(map(lambda ff: float(str.strip(ff)), coor.split(','))) #coordinates of the row
    pitchM = len(rowData[row]); effPadOr = ma.addPoints(padOr,map(lambda ff: pitchM*ff, padPitch))
    coor = ma.addPoints(coor,effPadOr)    
    rowData[row].append([dut,coor])
    if re.search(r''+args.ref,dut,flags=re.I): ref = coor
  return ref,rowData

def changeNotch(coor,direction):
  if direction == 'ND': newX = coor[0]; newY = coor[1]
  elif direction == 'NU': newX = coor[0]*-1; newY = coor[1]*-1;
  elif direction == 'NR': newX = coor[1]*-1; newY = coor[0]; 
  elif direction == 'NL': newX = coor[1]; newY = coor[0]*-1;   
  else: raise IOError('error')
  if newX == 0: newX=0.0
  if newY == 0: newY=0.0
  return newX,newY
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse,sys,os,re
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import mathUtils as ma
argparser = argparse.ArgumentParser(description='Creates the Project File for Measurements')
argparser.add_argument(dest='csv', type=checkFile, help='csv file with header:\n##rowName,dutName,coordinates##')
argparser.add_argument('-notch', dest='notch', default='NR', choices = ['ND','NU','NR','NL'], help='Notch direction, default=NR')
argparser.add_argument('-refdut', dest='ref', default='open', help='Reference DUT, default=open')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

ref,rowData = getRowData(args.csv);
out = []; cals = []; count = 0
for rowName,rowData in rowData.items():
  for dut,coor in rowData:
    coor = ma.addPoints(coor,map(lambda ff: -1*ff, ref))
    coor = changeNotch(coor,args.notch)### swap coordinates
    coor = ' '.join(map(str,coor) )
    if re.search(r'open',dut,flags=re.I): cals.append(' '.join([dut,coor,'SP OP1 N N 0']))
    elif re.search(r'short',dut,flags=re.I): cals.append(' '.join([dut,coor,'SP SH1 N N 0']))
    else: out.append(' '.join([dut,coor,'SP DUT OP1 SH1 0'])); 
    count+=1
print '\n'.join([str(count)]+cals+sorted(out))
