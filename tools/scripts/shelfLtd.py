#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

##############################################################################
# Intel Top Secret                                                           #
##############################################################################

def checkTech(tech):  
  techs = ['1222','1231','1272','1274','1275','1276','1278']
  if tech not in techs: raise IOError('Wrong technology')
  shelf = 'fshelf'+tech[-2:]
  return tech,shelf

def checkDot(dot):
  dot = int(dot)
  if dot >= 0: return str(dot)

def checkUpf(upf):
  import re
  if re.search(r'^x\d+r\d+(\w+)?$',upf): return upf
  else: raise IOError('Bad upf input, must be x#r#')

def checkIn(inDir):
  import os
  if not os.path.isdir(inDir): raise IOError('Input is not a directory')
  if not os.listdir(inDir): raise IOError('Directory is empty')
  return os.path.realpath(inDir)
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess, re
argparser = argparse.ArgumentParser(description='Shelf LTD Directory')
argparser.add_argument(dest='shelf', type=checkIn, help='ltd directory')
argparser.add_argument('-tech', dest='tech', required=True, type=checkTech, help='technology')
argparser.add_argument('-dot', dest='dot', required=True, type=checkDot, help='dot process')
argparser.add_argument('-upf', dest='upf', required=True, type=checkUpf, help='upf version')
argparser.add_argument('-comm', dest='comm', default='EMStack shelf post', help='Comment to shelf')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
## Setup command
cmd = '/nfs/pdx/disks/adip.disks.0/tool/bin/release2ADshelf --debug --input '+args.shelf+' --area keysightemstack --process '+args.tech[0]
target = ' --dot_process '+args.dot+' --shelfversion ad-'+args.tech[0]+'.'+args.dot+'-'+args.upf
if args.tech[0] == '1278': target += ' --spec mdk_spec102.csv'
cmd = cmd+target
print(cmd)
## args
print('##############################')
print(('source: '+args.shelf))
print(('tech: '+args.tech[1]))
print(('dot: '+args.dot))
print(('version: '+args.upf))
proceed = input('##############################\nproceed to shelf, yes or no: ')
## run 
if re.search(r'^(yes|no|y|n)$',proceed,flags=re.I):
  if proceed in ['yes','y']: test = subprocess.Popen(cmd,shell=True); test.communicate()
else: print('Wrong input, quiting')

