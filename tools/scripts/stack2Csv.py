#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

import sys, os, re, layout; from numtools import numToStr as n2s
PR = None # you can give none for no limitation in decimals

def getViaOffset(via,metals):
  prefix = 'tm' if re.search(r'^t',via) else 'm'
  metal = prefix + re.search(r'(\d+)$',via).group(1)
  return float(metals[metal][0])+float(metals[metal][1])
  
def getMVTable(dt,offGuide=False):
  import re
  outLst = [];
  for layer in layout.sortMetalVia(dt.keys()):
    bot = getViaOffset(layer,offGuide) if offGuide else float(dt[layer][0]);
    tc = float(dt[layer][1])
    top = bot+tc;
    outLst.append(','.join([layer,n2s(bot,PR),n2s(top,PR),n2s(tc,PR),'1',n2s(dt[layer][2],PR,True)] ))
  outLst.reverse()
  return outLst

def getOxides(dt,mComp,skip='0'):
  bLayer = 'first'; outLst=[]; skip= len(filter(lambda ff: re.search(r'oxide|c4',ff,flags=re.I),dt.keys())) - int(skip); oo=1
  for layer in layout.sortOxides(dt.keys()):
    bot = 0 if bLayer == 'first' else float(dt[bLayer][0])
    top = float(dt[layer][0]); tc = top-bot
    bLayer = layer;
    if re.search(r'oxide|c4',layer,flags=re.I): uncomp = dt[layer][1] if oo>skip else str(float(dt[layer][1])/float(mComp)); oo+=1;
    else: uncomp = dt[layer][1]
    outLst.append(','.join([layer,n2s(bot,PR),n2s(top,PR),n2s(tc,PR),'1',n2s(dt[layer][2],PR,True),n2s(uncomp,PR),n2s(dt[layer][1],PR)]))
  outLst.reverse()
  return outLst

##############################################################################
# Argument Parsing
##############################################################################
import argparse
argparser = argparse.ArgumentParser(description='Convert the eqvStack to csv')
argparser.add_argument(dest='inputFile', nargs='+', type=file, help='file(s) ending with eqvStack (only one)')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "INPUTFILE.csv"')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
header = {}; stack = {'Layer':{},'Metal':{},'Via':{}};
numExp = '([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
for inputFile in args.inputFile:
  for line in inputFile:
  ## find the process, skew, temp, BUMP factor, exclusion from top
    for var in ['PROCESS','SKEW','TEMP','BUMP_EPSR_FACTOR','DUMMY_EXCLUDE_FROM_TOP']:
      test = re.search(r'^'+var+'.*\[(.*)\]',line,flags = re.I)
      if test: header[var] = test.group(1)
  ## find the epi and find the substrate
    test1 = re.search(r'EPI\s+SIGMA\s+=\s+(\d+)',line,flags = re.I);   test2 = re.search(r'SUBSTRATE\s+SIGMA\s+=\s+(\d+)',line,flags = re.I)
    if test1: header['EPI'] = test1.group(1)
    if test2: header['SUBSTRATE'] = test2.group(1)
  ## get all the oxides, metals, vias
    for var in ['Layer','Metal','Via']:
      test1 = re.search(r''+var+'\s+#.*?"(.*)"',line,flags = re.I)
      test2 = filter(lambda ff: ff!='', re.findall(r''+numExp,line,flags = re.I));
      if test1 and test2: stack[var][test1.group(1)] = test2[-3:] #store as top_height,epsr,sigma or bottom_height,thickness,sigma
  ## convert to csv and print
  outLst = ['#PROCESS='+os.path.basename(header['PROCESS'])]; del header['PROCESS']
  for var in header.keys(): outLst.append('#'+var+'='+header[var])
  outLst += ['Metal,Zbot(um),Ztop(um),Tc(um),mur(ur),Sigma@'+header['TEMP']+'C(S/m)']
  outLst += getMVTable(stack['Metal'])
  outLst += ['Via,Zbot(um),Ztop(um),Tc(um),mur(ur),Sigma@'+header['TEMP']+'C(S/m)']
  outLst += getMVTable(stack['Via'],offGuide=stack['Metal'])
  outLst += ['Oxide/Substrate,Zbot(um),Ztop(um),Thickness(um),mur(ur),Sigma'+'C(S/m),EpsrUncomp,EpsrComp']
  outLst += getOxides(stack['Layer'],header['BUMP_EPSR_FACTOR'],header['DUMMY_EXCLUDE_FROM_TOP'])
  name = os.path.splitext(os.path.basename(inputFile.name))[0]+'.csv'
  if args.csvFile:
    with open(name,'wb') as fout: fout.write('\n'.join(outLst))
  else:  print '\n'.join(outLst)
