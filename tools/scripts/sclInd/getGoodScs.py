#!/usr/bin/env python2.7
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import csvUtils, numtools
argparser = argparse.ArgumentParser(description='Get the filenames under tolerance for error')
argparser.add_argument(dest='error',nargs='+', help='AverageErr.csv file(s) generated from the printErrsSpScs script')
argparser.add_argument('-lonly',dest='lonly', action='store_true', help='Lonly Pass')
argparser.add_argument('-qonly',dest='qonly', action='store_true', help='Qonly Pass')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## key arguments
lK,qK,fileK = 'statusLd','statusQd','fName'
## read the main files
for fin in args.error:
  csv = csvUtils.dFrame(fin)
  for fi,q,l in zip(csv[fileK],csv[qK],csv[lK]):
    if args.qonly and q == 'PASS': print fi
    elif args.lonly and l == 'PASS': print fi
    elif q == 'PASS' and l == 'PASS': print fi
exit(0)
