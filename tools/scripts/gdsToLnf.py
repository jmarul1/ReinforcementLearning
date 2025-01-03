#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################


def checkGds(path):
  if not os.path.isfile(path):raise IOError('path does not exist: '+path)
  result = os.path.splitext(path) 
  if result[1].lower() not in ['.gds','.stm']: raise IOError('path is not (gds/stm): '+path)
  return path


##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import shell
argparser = argparse.ArgumentParser(description='Convet GDS to LNF')
argparser.add_argument(dest='gds', nargs='+', help='gds file(s)')
argparser.add_argument('-process', dest='process', default = os.getenv('PROCESS_NAME'), help='Overwrite process')
argparser.add_argument('-keeplogs', dest='keepLogs', action='store_true', help='Keep Log Files')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
print 'Setting up environment variables ...'
nikeTech = os.getenv('NIKE_TECH_DIR')
os.environ['OA_TECH_DIR'] = nikeTech+'/OATechFiles_DM4'; 
print '$OA_TECH_DIR = $NIKE_TECH_DIR/OATechFiles_DM4'
cadRoot = os.getenv('CAD_ROOT')
os.environ['LD_LIBRARY_PATH'] = os.getenv('LD_LIBRARY_PATH')+':'+cadRoot+'/for_suse11/'
print '$LD_LIBRARY_PATH = $LD_LIBRARY_PATH:$CAD_ROOT/for_suse11/'

for gdsFile in args.gds:
  cmd = '/stm2lnf/v4.0/bin/stm2lnf -stream '+gdsFile+' -libpath . -process p'+args.process;   print '$CAD_ROOT'+cmd;
  cmd = cadRoot+cmd
  print cmd
  test = subprocess.Popen(cmd,shell=True); test.communicate()
  if not args.keepLogs: 
    for log in ['GDSII.input.*','p1268.oatf','via_tech']: shell.rmFile(log) #remove logs
