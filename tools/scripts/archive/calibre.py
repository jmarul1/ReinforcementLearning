#!/usr/bin/env python2.7
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> calibre.py -h 
##############################################################################

def getInput(path):
  if not os.path.isfile(path):raise IOError('path does not exist: '+path)
  result = os.path.splitext(path) 
  if result[1].lower() not in ['.gds','.oas','.stm']: raise IOError('path is not (gds/oas/stm): '+path)
  ext = 'stm' if result[1].lower() == '.gds' else result[1].lower().lstrip('.')
  return os.path.relpath(path),os.path.basename(result[0]),ext

def getSn(path):
  if not os.path.isfile(path):raise IOError('path does not exist: '+path)
  result = os.path.splitext(path)
  if result[1].lower() not in ['.sn','.sp']: raise IOError('path is not (sn/sp): '+path)
  return os.path.relpath(path),os.path.basename(result[0]),result[1].lower().lstrip('.')  

      
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess, itertools, re
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import qa, shell
argparser = argparse.ArgumentParser(description='Run Calibre',formatter_class=argparse.ArgumentDefaultsHelpFormatter)
argparser.add_argument(dest='input', nargs='+', type=getInput, help='.gds/.oas/.stm file(s)')
argparser.add_argument('-flow', dest='flow', nargs='+', default=['drcc'], help='DRC FLOW')
argparser.add_argument('-sn', dest='sn', nargs='+', type=getSn, help='.sn file(s) in order of positional (gds inputs) for lvs')
argparser.add_argument('-process', dest='process', default='1231', help='Process')
argparser.add_argument('-runset', dest='runset', default=os.environ['Calibre_RUNSET'], help='Runset Path')
argparser.add_argument('-engine', dest='engine', default = '/nfs/site/disks/icf_fdk_pvr_gwa001/bin/cal.sh', help='Calibre Script')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## run for each file/flow
for cc,(path,cellName,inputType) in enumerate(args.input):
  for flow in set(args.flow):
    ## build the command in shell
    options = ' -p '+args.process+' -d 0 -l '+path+' -t '+cellName+' -r '+args.runset+' -m '+flow
    cmd = args.engine + options
    print 'Running '+cmd+'\n'
    run = subprocess.Popen(cmd, shell=True)
    run.communicate()


