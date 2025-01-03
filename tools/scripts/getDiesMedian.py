#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> plotRF.py -h 
##############################################################################

## Functions
def targetFiles(path):
  import os, argparse, re
  lstFiles = []
  if os.path.isdir(path):
    lstFiles = os.listdir(path); lstFiles = filter(lambda ff: re.search(r'\.csv$',ff,flags=re.I), lstFiles); 
    if any(lstFiles): lstFiles = [path+'/'+ii for ii in lstFiles]; lstFiles = map(os.path.normpath,lstFiles); 
  elif os.path.isfile(path): 
    if os.path.splitext(path)[1]=='.csv': lstFiles = [path]
  else: raise argparse.ArgumentTypeError('File or Dir doesn\'t exist: '+path)
  return lstFiles

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, itertools, sys, re, subprocess
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import plotUtils
argparser = argparse.ArgumentParser(description='Compute the median across dies, grouping by filename (CSV files)')
argparser.add_argument(dest='input', type=targetFiles, nargs='+', help='Directory with CSV files')
argparser.add_argument('-prefix',dest='prefix', default='X-?\d+Y-?\d+', help='die prefix regexp to use')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## get the files
lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();
if not any(lstFiles): raise argparse.ArgumentTypeError('File(s) or Dir(s) given aren\'t or don\'t contain ANY csv files')
results=plotUtils.group(lstFiles,prefix=args.prefix)
for duts in results:
  dut = re.search(r''+args.prefix+'(.*)',duts[0],flags=re.I)
  median = 'XmYm'+dut.group(1)
  cmd = 'averageCsvs.py '+(' '.join(duts))+' > '+median
  subprocess.call(cmd,shell=True)
  print 'Created '+median
