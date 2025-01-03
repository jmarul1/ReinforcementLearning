#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def checkPosNum(number):
  if isNumber(number) and float(number) > 0: return number
  else: raise IOError('Please give a valid number > 0: '+number)

def checkEx(number):
  if isNumber(number) and float(number) >= 0: return number
  else: raise IOError('Please give a valid number >= 0: '+number)
  
##############################################################################
# Argument Parsing
##############################################################################
import sys, os; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import re, layout, argparse, ltdstack; from numtools import isNumber, numToStr
argparser = argparse.ArgumentParser(description='Modifies LTD files with given dummy and losstangent values',formatter_class=argparse.RawTextHelpFormatter)
argparser.add_argument(dest='inputFile', nargs='+',help='LTD file(s)')
argparser.add_argument('-exclude', dest='exclude', type=checkEx, help='exclude number from the top (oxides). DEFAULTS to oxides >= topMetal')
argparser.add_argument('-dummy', dest='dummy', type=checkPosNum, default='1', help='Dummification factor. DEFAULTS to "1.0"')
argparser.add_argument('-losstan', dest='ltb', type=checkEx, default='0', help='Loss Tangent for Dielectrics. DEFAULTS to whatever in the LTD')
argparser.add_argument('-csvstack', dest='csv', action='store_true', help='create *.csv stack files')
argparser.add_argument('-shortstack', dest='shortStack', nargs='?', const = '4', default='4', type=checkPosNum, help='ShortStack of the top 4 or <whateverTheInputIs>')
argparser.add_argument('-csvonly', dest='csvOnly', action='store_true', help='create *.csv stack files only')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## Compute the materials and assign Intrinsic lossTangent
conds,diels,semis = [],set(),set(); 
for inputFile in args.inputFile:
  foutName = os.path.basename(os.path.splitext(inputFile)[0])
  stackInfo = ltdstack.read(inputFile)
  stackInfo.applyDumLt(args.dummy,args.ltb,args.exclude)
  ## remove layers based on the shortstack
  if args.shortStack: stackInfo.rmLayers(int(args.shortStack))
  ## print the ltd file
  ltdName =  foutName+'_'+args.dummy.replace('.','p')+'dum_'+args.ltb.replace('.','p')+'lt.ltd'
  if not args.csvOnly: stackInfo.printLtd(ltdName)
  ## print the csv if requested
  if args.csv or args.csvOnly: stackInfo.printCsv(foutName+'.csv')
