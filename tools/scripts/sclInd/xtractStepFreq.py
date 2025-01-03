#!/usr/bin/env python2.7

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, csv
argparser = argparse.ArgumentParser(description='Stepping freq of sparameter.')
argparser.add_argument(dest='sp', nargs='+', help='sp file(s)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import sparameter as sparam

## run for each csv specified 
csvDFs={}
for spFile in args.sp:
  sp = sparam.read(spFile)
  print sp.stepFreq()
exit(0)
