#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def skewGuide(skew): # 0 for skews, 1 for files
  if skew == 'POR':
    POR = ['tttt_Tp25','prcf_Tn40','pcff_Tn40','prcs_Tp125','pcss_Tp125']
    return POR
  else: return []
    
############# MAIN
import sys, os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import argparse, re, subprocess
argparser = argparse.ArgumentParser(description='Remove non inductor layers')
argparser.add_argument(dest='input', nargs='+', help='Directory with skews')
args = argparser.parse_args()

remove = []
for ff in args.input:
  lst = os.listdir(ff)
  for skew in skewGuide('POR'): 
    lst = filter(lambda ff: not(re.search(r''+skew,ff,flags=re.I)), lst)
  for ff in lst:
    subprocess.call('rm -f '+ff,shell=True)
