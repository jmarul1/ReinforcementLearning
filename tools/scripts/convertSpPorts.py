#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

## ARGUMENTS ##
import sys, os
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import argparse, re, sparameter
argparser = argparse.ArgumentParser(description='Creates a new sparameter file by removing ports')
argparser.add_argument(dest='spFile', nargs='+', help='Sparameter Files')
argparser.add_argument('-ports', dest='ports', type=int, nargs='+', default=[1,2], help='Ports to keep, default: 1 2')
args = argparser.parse_args()

## MAIN ##
for inFile in args.spFile:
  sp = sparameter.read(inFile)
  if sp.portNum < len(args.ports): raise IOError('Number of ports input is more than spFile: '+inFile+'\n')
  sp.extractPorts(args.ports)
  newSpStr = sp.writeSpFileStr()
  newFName = os.path.basename(os.path.splitext(inFile)[0]) + '.s'+str(sp.portNum)+'p'
  if os.path.exists(newFName): sys.stderr.write('WARNING: Overwrote '+newFName+'\n')
  with open(newFName, 'wb') as fout: fout.write(newSpStr)
