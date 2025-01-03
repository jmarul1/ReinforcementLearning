#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
     
##############################################################################
# Argument Parsing
##############################################################################
import argparse, sys, os
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import cadence
argparser = argparse.ArgumentParser(description='Get cells from cadence lib')
argparser.add_argument(dest='lib', type=str, help='Library in the cdslib')
argparser.add_argument('-cells', dest='cells', type=str, default='.*', help='regular expression to match')
argparser.add_argument('-p', dest='p',action='store_true', help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
if os.getenv('CDSLIB'): cdsFile = os.getenv('CDSLIB')
else: cdsFile = os.getenv('WARD')+'/cds.lib'
if not os.path.isfile(cdsFile): raise IOError('CDSLIB variable not available')
cdsDt = cadence.readCds(cdsFile); 
if args.lib not in cdsDt.cds.keys(): raise IOError('LIBNAME not in cdsdef: '+args.lib+'\n');
if args.p: print(cdsDt.cds[args.lib]); exit(0)
cells = cdsDt.getLibCells(args.lib,args.cells)
print(' '.join(cells))

