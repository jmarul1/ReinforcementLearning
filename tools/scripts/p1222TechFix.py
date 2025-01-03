#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, sys, os, re
argparser = argparse.ArgumentParser(description='Replace ICF layers with AD')
argparser.add_argument(dest='skCode', nargs='+', help='text file(s)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))

## run for each ff specified 
for ff in args.skCode:
  output = []
  newFile = os.path.basename(ff); newFile = os.path.splitext(newFile)[0]+'_new'+os.path.splitext(newFile)[1]
  with open(ff, 'rb') as fin:
    for line in fin:
      newLine = re.sub(r'"m(?P<num>\d+)"',r'"metal\g<num>"',line)
      newLine = re.sub(r'"v(?P<num>\d+)"',r'"via\g<num>"',newLine)
      newLine = re.sub(r'"tcn"',r'"diffcon"',newLine)
      newLine = re.sub(r'"gcn"',r'"polycon"',newLine)
      output.append(newLine)
  with open(newFile, 'wb') as fout:
    fout.write(''.join(output))
