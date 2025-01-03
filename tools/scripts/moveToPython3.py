#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, csv
argparser = argparse.ArgumentParser(description='')
argparser.add_argument(dest='files', nargs='+', help='file(s)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
lines = []
for ff in args.files:
  with open(ff,'r') as fin:
    for line in fin:
      out = re.sub(r'\t','        ',line); lines.append(out)
  with open(ff,'w') as fout: fout.write(''.join(lines))    
