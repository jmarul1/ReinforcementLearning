#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2014, Intel Corporation.  All rights reserved.               #
#                                                                            #
# This is the property of Intel Corporation and may only be utilized         #
# pursuant to a written Restricted Use Nondisclosure Agreement               #
# with Intel Corporation.  It may not be used, reproduced, or                #
# disclosed to others except in accordance with the terms and                #
# conditions of such agreement.                                              #
#                                                                            #
# All products, processes, computer systems, dates, and figures              #
# specified are preliminary based on current expectations, and are           #
# subject to change without notice.                                          #
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> filterSp.py -h 
##############################################################################

def chInParam(inVal):
  if re.search(r'[Ss]\d{2}',inVal): return inVal.upper()
  else: raise argparse.ArgumentTypeError('Invalid Snn argument: '+inVal)  

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, re, sys
argparser = argparse.ArgumentParser(description='Extrapolates the Snn specified')
argparser.add_argument(dest='spFiles', nargs='+', help='sparameter file(s)')
argparser.add_argument('-params', dest='params', nargs='+', type=chInParam, default=['S11'], help='Parameter to extrapolate')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import sparameter as sp

for spFile in args.spFiles:
  resultStr = '! Touchstone file modified by MM\n! 1-port S-Parameter Data\n'
  sparam = sp.read(spFile)
  optionLine = map(str.strip, ['#','GHZ',sparam.dataType,'RI','R',str(sparam.impedance)])
  # print the option line
  if all(optionLine): resultStr += ' '.join(optionLine)+'\n'
  # print the matrix with parameters specified
  sparamLines = '\n'.join(str(freq)+'\t'+'\t'.join(' '.join(map(str,(sparam.data[ff][int(pp[1])][int(pp[2])].real,sparam.data[ff][int(pp[1])][int(pp[2])].imag))) for pp in args.params) for ff,freq in enumerate(sparam.freq))
  resultStr += sparamLines
  # new file and save
  newfile = os.path.splitext(spFile)[0]+'.s'+('1' if len(args.params) == 1 else 'n')+'p'; 
#  if os.path.isfile(newfile): print >> sys.stderr,'ERROR: '+newfile+' already exists... skipping'; continue
  with open(newfile,'wb') as fout: fout.write(resultStr)
  print newfile+'      ... Created'
exit(0)
