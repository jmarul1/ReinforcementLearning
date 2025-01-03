#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

##############################################################################
# Description:
#   Type >> extract.py -h 
##############################################################################

 
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess, itertools
argparser = argparse.ArgumentParser(description='Wrapper for Peter\'s script')
argparser.add_argument(dest='cellName', nargs='+', help='cellName')
argparser.add_argument('-lib',dest='lib',help='LibName')
argparser.add_argument('-blackbox', dest='blackbox', nargs='+', help='BlackBox Cells')
argparser.add_argument('-accurate', dest='acc', action='store_true', help='Accurate')
argparser.add_argument('-temperature', dest='temp', default='25', help='Temperature')
argparser.add_argument('-dirty',dest='dirty', action='store_true', help='Run with LVS dirty')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
script = "/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/extractMM"
for ff in set(args.cellName):
  blackbox = '-b '+(' '.join(args.blackbox)) if args.blackbox else ''
  accurate = '-j accurate' if args.acc else ''
  cmd = ' '.join([script,args.lib,ff,blackbox,accurate])
  print( cmd)
  subprocess.call(cmd,shell=True)
