#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def skewGuide(skew=0): # 0 for skews, 1 for files
  POR = ['ttttQ_(-40|-5|70|110|125)C',
                   'prcfQ_(-5|25|70|110|125)C','pcffQ_(-5|25|70|110|125)C',
		   'prcsQ_(-40|-5|25|70|110)C','pcssQ_(-40|-5|25|70|110)C']
  MIG = ['ttttQ_(-5|110)C', #MIG
                   'prcfQ_(-5|25|110|125)C','pcffQ_(-5|25|110|70)C',
		   'prcsQ_(-40|-5|25|110)C','pcssQ_(-5|25|110|70)C']
  OLD = ['ttttQ_(-5|110)C', #OLD TECH
                   'prcfQ_(-40|-5|25|110|70|125)C','pcffQ_(-5|25|110|70)C',
		   'prcsQ_(-40|-5|25|110|70|125)C','pcssQ_(-5|25|110|70)C']
  CST = ['ttttQ_(-5)C', #CUSTOM TECH
                   'prcfQ_(-5|25|110|70)C','pcffQ_(-5|25|110|70)C',
		   'prcsQ_(-5|25|110|70)C','pcssQ_(-5|25|110|70)C']
  fileCleanUpPOR = ['tttt_T(n40|n5|p70|p110|p125)C',
                 'prcf_T(n5|p25|p70|p110|p125)C','pcff_T(n5|p25|p70|p110|p125)C',
	         'prcs_T(n40|n5|p25|p70|p110)C','pcss_T(n40|n5|p25|p70|p110)C']
  fileCleanUpMIG = ['tttt_T(n5|p125)C', #MIG
                 'prcf_T(n5|p25|p70|p110|p125)C','pcff_T(n5|p25|p70|p110)C',
	         'prcs_T(n40|n5|p25|p70|p110)C','pcss_T(n5|p25|p70|p110)C']
  fileCleanUpOLD = ['tttt_T(n5|p125)C', #OLD
                 'prcf_T(n40|n5|p25|p70|p110|p125)C','pcff_T(n5|p25|p70|p110)C',
	         'prcs_T(n40|n5|p25|p70|p110|p125)C','pcss_T(n5|p25|p70|p110)C']
  fileCleanUpCST = ['tttt_T(n5|p125)C', #CUSTOM
                 'prcf_T(n5|p25|p70|p110)C','pcff_T(n5|p25|p70|p110)C',
	         'prcs_T(n5|p25|p70|p110)C','pcss_T(n5|p25|p70|p110)C']
  if skew != 0: return fileCleanUpCST
  else: return CST

def correctCSV(ff,fromLayer):
  import subprocess, indstack
  remove = indstack.getMVBelow(fromLayer)
  for ii in remove:
    cmd = "sed -ri '/^("+ii.upper()+"|"+ii.lower()+")\\s*,/d' "+ff
    subprocess.call(cmd,shell=True)
  cmd = "sed -ri '/BUMP_EPSR|DUMMY_EXCLUDE/d' "+ff
  subprocess.call(cmd,shell=True)
  with open('temp.temp','wb') as tempF: tempF.write('#VERSION='+args.version+'\n')
  cmd = "awk -F , '{print $1 \",\" $2 \",\" $3 \",\" $4 \",\" $5 \",\" $6 \",\" $8 \",\" $9}' "+ff+" >> temp.temp; mv temp.temp "+ff  
  subprocess.call(cmd,shell=True)

def correctMom(ff,fromLayer,cleanSkews=None):
  import subprocess, indstack, re
  remove = indstack.getMVBelow(fromLayer)
  remove += ['v1tf','tfr']
  for ii in remove:
    cmd = "sed -ri '/=\\s*\"\\s*("+ii.upper()+"|"+ii.lower()+")\\s*_/d' "+ff
    subprocess.call(cmd,shell=True)
  if cleanSkews:
    skewsCleanUp = skewGuide(skew=0)		 
    for skew in skewsCleanUp:
      cmd = "sed -ri '/"+skew+"/d' "+ff
      subprocess.call(cmd,shell=True)    

############# MAIN
import sys, os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import argparse, re, subprocess
argparser = argparse.ArgumentParser(description='Remove non inductor layers')
argparser.add_argument(dest='input', nargs='+', help='CSV/SUBST/MATDB file(s) to compute')
argparser.add_argument('-upto',dest='fromLayer', required=True, type=str, help='Remove from this layer and below')
argparser.add_argument('-cleanskews',dest='cleanSkews', action='store_true', help='Keep only valid SKEW combinations')
argparser.add_argument('-version',dest='version', default='UNKNOWN', help='Version')
args = argparser.parse_args()

for ff in args.input:
  if os.path.splitext(ff)[1] == '.csv': correctCSV(ff,args.fromLayer)
  elif os.path.splitext(ff)[1] in ['.subst','.matdb']: correctMom(ff,args.fromLayer,args.cleanSkews)
  else: continue

if args.cleanSkews:
  fileCleanUp = skewGuide(skew=1)
  for skew in fileCleanUp:    
    eraseLst = filter(lambda ff: re.search(r''+skew,ff), args.input)
    map(lambda ff: subprocess.call('rm '+ff,shell=True), eraseLst)

