#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
 
def checkDir(path):
  if not os.path.isdir(path): raise IOError('Out directory does not exist: '+path)
  else: return path

def checkIn(path):
  if not os.path.isfile(path): raise argparse.ArgumentTypeError('File does not exist: '+path)
  if os.path.splitext(path)[1] != '.TOP_LAYOUT_ERRORS': raise argparse.ArgumentTypeError('File is not DRC') 
  return open(path,'rb')

## Argument Parsing
import sys, re, argparse, os, subprocess
argparser = argparse.ArgumentParser(description='Get worst violation for error')
argparser.add_argument(dest='inputFile', nargs='+', type=checkIn, help='file(s) .TOP_LAYOUT_ERRORS')
argparser.add_argument('-rule', dest='rule', type=str, required=True, help='Rule to extract')
argparser.add_argument('-param', dest='param', type=str, required=True, help='Parameter')
#argparser.add_argument('-complex', dest='complex', default='RI', choices = ['RI','MA','DB'], help='complex data format')
#argparser.add_argument('-outdir', dest='outdir', default='.', type=checkDir, help='Out dir, defaults to current')
args = argparser.parse_args()
## Main Begins
numExp = '([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
for ff in args.inputFile:
  rule = fetch = False; dt={}
  for line in ff:
    if re.search('ERROR DETAILS',line): fetch = True
    if not fetch: continue
    if re.search(r''+args.rule+':.*',line,flags=re.I):
      rule = line
    test = re.search(r'calcDensity\s*=\s*'+numExp,line,flags=re.I)
    if test and rule: 
      if rule not in dt.keys(): dt[rule] = []
      dt[rule].append(float(test.group(1)))
  for ii in dt.keys():
    print ii, '\n'.join(map(str,sorted(dt[ii]))[0:10])
      
