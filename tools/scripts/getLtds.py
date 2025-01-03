#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess
argparser = argparse.ArgumentParser(description='Get the LTDs inside a directory as directory.ltd')
argparser.add_argument(dest='dirs', nargs='+', help='LTD dir(s)')
argparser.add_argument('-target', dest='target', default='.', help='Target directory')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))

for dd in args.dirs:
  if not os.path.isdir(dd): continue
  files = os.listdir(dd)
  if not 'proj.ltd' in files: continue
  newName = os.path.basename(dd)
  newName = newName.rstrip('_MoM')+'.ltd'
  cmd = 'cp '+dd+'/proj.ltd '+args.target+'/'+newName
  test = subprocess.call(cmd,shell=True)
  if test >= 0: print 'copied '+newName
  
