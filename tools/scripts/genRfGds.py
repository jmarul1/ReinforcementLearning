#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> genRfGds.py -h 
#   Generates inductors from skill into GDS
##############################################################################

def checkIn(path):
  import os
  if os.path.isfile(path): return os.path.realpath(path)
  else: raise IOError('path does not exist: '+path)

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, tempfile, re, subprocess
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
argparser = argparse.ArgumentParser(description='Generate GDS of INDS/XFMRS/TLs')
argparser.add_argument(dest='csv', nargs='+', help='csv file with parameters and either ind|xfmr in the file')
group = argparser.add_mutually_exclusive_group()
group.add_argument('-genind', dest='genInd', action='store_true', help='Generate the inductor table "indparam.csv')
group.add_argument('-genxfmr', dest='genXfmr', action='store_true', help='Generate the xfmr table "indparam.csv')
argparser.add_argument('-pcell', dest='pcellLib', default = 'jmarulan_lib', help='Library with pcell')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
if args.genInd:
  print('\n###################### IND TABLE ##############################')
  print('instName , indType ,    w   ,   dx   ,   dy   ,   tl   ,   ts')
  print('type     , string  , string , string , string , string , string')
  print('#EXAMPLE ,   oct   ,   10u  ,  100u  ,  100u  ,   5u   ,   5u')
  print()
  exit() 
if args.genXfmr:
  print('\n########################## XFMR TABLE ##################################')
  print('instName , indType ,  wM8   ,  wM7   , doM8   , doM7   ,   tl   ,   ts')
  print('type     , string  , string , string , string , string , string , string')
  print('#EXAMPLE ,   oct   ,   10u  ,  4.5u  ,  100u  ,  100u  ,   5u   ,   5u')
  print()
  exit() 
#################################################################################
for csv in args.csv:
## name of the file
  if re.search(r'ind',csv): pcell = 'mmind2t'
  elif re.search(r'xfmr',csv): pcell = 'mmxfmr'
  else: raise IOError('Make sure name of the file has "ind" for inductor or "xfmr" for transformers in the namefile.csv')
  ## Create il file
  ilFile = tempfile.mkstemp(suffix='.il')[1]
  with open(ilFile,'w') as fout:
    fout.write('load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/cdsinit")\n')
    fout.write(f'lst = adCreateSclCellQa("{args.pcellLib}" "{pcell}" "{os.path.realpath(csv)}")\nlst = buildString(lst)\n')
    userlib = os.getenv('USER')+'_lib'
    fout.write('cmd = strcat("strmOut.py -lib jmarulan_lib -flatten -- " lst)\nsystem(cmd)')
  ## run the file
  log = tempfile.mkstemp(suffix='.log')[1]
  cdsLib = '$WARD/cds.lib' if os.path.isfile(os.getenv('WARD')+'/cds.lib') else '$CDSLIB'
  cmd = 'virtuoso -nograph -log '+log+f' -cdslib {cdsLib} -replay '+ilFile
  subprocess.call(cmd,shell=True)
  print('\n## Finished running: '+ilFile+' with log: '+log)
