#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> runset.py -h
##############################################################################

def getInput(path):
  if args.flow[0] == 'tapein': return path,path,'lnf'
  if not os.path.isfile(path):raise IOError('path does not exist: '+path)
  result = os.path.splitext(path)
  if result[1].lower() not in ['.gds','.oas','.stm','.lnf']: raise IOError('path is not (gds/lnf/oas/stm): '+path)
  ext = 'stm' if result[1].lower() == '.gds' else result[1].lower().lstrip('.')
  return os.path.relpath(path),os.path.basename(result[0]),ext

def getSn(path):
  if not os.path.isfile(path):raise IOError('path does not exist: '+path)
  result = os.path.splitext(path)
  if result[1].lower() not in ['.sn','.sp','.cdl']: raise IOError('path is not (sn/sp/cdl): '+path)
  return os.path.relpath(path),os.path.basename(result[0]),result[1].lower().lstrip('.')

def prepFileInput(fPath,format):
  if format == 'stm': tgtPath = os.getenv('PDSSTM') ## get the directory
  elif format == 'oas': tgtPath = os.getenv('PDSOAS')
  elif format == 'lnf': tgtPath = os.getenv('WARD')+'/genesys/lnf';
  elif format == 'sn': tgtPath = os.getenv('WARD')+'/netlists/mkisp'
  elif format == 'sp': tgtPath = os.getenv('WARD')+'/netlists/spice'
  elif format == 'cdl': tgtPath = os.getenv('WARD')+'/netlists/auCdl'
  tgtFile = tgtPath+'/'+os.path.basename(fPath)
  if os.path.realpath(fPath) == os.path.realpath(tgtFile): return tgtFile; ## dont link if already there
  try: os.symlink(os.path.realpath(fPath),tgtFile)
  except OSError: subprocess.call('rm -f '+tgtFile,shell=True); os.symlink(os.path.realpath(fPath),tgtFile)
  return tgtFile

def cleanupJobs(jobs):
  import itertools
  subprocess.call('cleanPdsLogs.py '+(' '.join(itertools.chain(*jobs)))+' -maxduration '+str(args.timeout)+' &',shell=True);

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess, itertools, re
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import qa, shell
argparser = argparse.ArgumentParser(add_help=False)
argparser.add_argument('-flow', dest='flow', nargs='+', default=['drcd'], help='DRC FLOW')
argparser.add_argument('-sn', dest='sn', nargs='+', type=getSn, help='.sn file(s) in order of positional (gds inputs) for lvs')
argparser.add_argument('-mail', dest='mail', const = 'yes', default='no', action='store_const', help='Mail user')
argparser.add_argument('-batch', dest='batch', const = 'batch', default='local', action='store_const', help='Use the batch')
argparser.add_argument('-nocmp', dest='nocmp', const = 'yes', default='no', action='store_const', help='lvs no comp')
argparser.add_argument('-cleanup', dest='cleanup', nargs='?', const='30', type=int, help=argparse.SUPPRESS) ## how many to run before cleaning
argparser.add_argument('-timeout', dest='timeout', default='20', type=int, help=argparse.SUPPRESS) ## maximum time to wait for a job when cleaning
argparser.add_argument('-tail', dest='tail', default='no', action='store_const', const='yes', help=argparse.SUPPRESS) ## xterm with log tail running
argparser.add_argument('-ddisk', dest='ddisk', default='', action='store_const', const='-ddisk', help=argparse.SUPPRESS) ## xterm with log tail running
args = argparser.parse_known_args()[0]
finparser = argparse.ArgumentParser(parents=[argparser],description='Used GPDS to run drc',formatter_class=argparse.ArgumentDefaultsHelpFormatter)
finparser.add_argument(dest='input', nargs='+', type=getInput, help='.gds/.oas/.lnf/.stm file(s)')
args = finparser.parse_args()
##############################################################################
# Main Begins FOR INDUCTOR DR_MSR must be set
##############################################################################
if args.batch == 'local' and len(set(args.input))>11: raise IOError('Use the batch for >10 runs') ## limit number of local jobs
cleanup = []; duplicates = []
## batch options
if args.batch != 'local': args.batch = args.batch+' -nbpool pdx_critical -nbclass "SLES11&&32G&&nosusp" -nbslot /adg/lvd/pd'
## run for each file/flow
for cc,(path,cellName,inputType) in enumerate(args.input):
  if (path,cellName,inputType) in duplicates: continue
  else: duplicates.append((path,cellName,inputType))
  if 'tapein' not in args.flow: prepFileInput(path,inputType)   ## prepare file by looking into he $PDSSTM, $PDSOAS, or $WARD/genesys/lnf
  for flow in set(args.flow):
    list([shell.rmFile(os.getenv('PDSLOGS')+'/'+cellName+'.'+flow+ff) for ff in ['.stats','.iss.log.*']])
    cleanup.append([cellName,flow]);
    if args.sn and flow in ['trclvs', 'drc_eerc']:
      snPath = prepFileInput(args.sn[cc][0],args.sn[cc][2])
    ## build the command in pds
    options = ' -saveworkdir no -autotail '+args.tail+' -mailuser '+args.mail+' -trcpin top -runmode '+args.batch
    if flow == 'tapein': cellName = os.path.splitext(os.path.basename(cellName))[0];
    pdsCmd = '_pypdsbuilder '+args.ddisk+' -laytopcell '+cellName+' -libspec '+cellName+options+' -mode '+flow+' -inputtype '+inputType
    ## add more options if lvs
    if flow == 'trclvs' and args.nocmp == 'no': pdsCmd += ' -topframe check -runcmp yes'+((' -snname '+snPath) if args.sn[cc][2] != '.sn' else '')
    if flow == 'trclvs' and args.nocmp == 'yes': pdsCmd += ' -topframe mixed -tooltype iss -verifytool no'
    if flow == 'drc_eerc': pdsCmd += ' -ddisk yes -verifytool yes -topframe mixed -tooltype iss -outputformat vue'+((' -snname '+snPath) if args.sn[cc][2] != '.sn' else '')
    print(pdsCmd)
    ## run the pds
    print(('#############\nRunning '+flow+' on '+cellName+((' ('+os.path.basename(snPath)+')') if args.sn and flow == 'trclvs' else '')))
    test = subprocess.run(pdsCmd, shell=True, capture_output=True);
    for line in test.stdout.decode().split('\n'):
      if re.search(r'Job\s+Submitted|The NETBATCH job|job.*is already running',line,flags=re.I): print(line)
    ## cleanup option for memory saver
    if args.cleanup and len(cleanup) >= args.cleanup: cleanupJobs(cleanup[:args.cleanup]); del cleanup[:args.cleanup] #call the script to clean the list(cell,flow)
if args.cleanup and cleanup: cleanupJobs(cleanup);

