#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def printMatdb(conds,diels,semis,foutName):
  output = ['<!DOCTYPE Materials>','<Materials>',]
  output.extend(['  <Conductors>']+conds+['  </Conductors>']) ##print conductors
  output.extend(['  <Dielectrics>']+layout.sortOxides(diels,prefixExp='name="')+['  </Dielectrics>']) ##print dielectrics
  output.extend(['  <Semiconductors>']+semis+['  </Semiconductors>','  <roughness/>\n</Materials>']) ##print semiconductors
  with open(foutName,'wb') as fout: fout.write('\n'.join(output))

def printSubst(stack,layers,vias,foutName):
  output = ['<!DOCTYPE Substrate>','<SubstrateModel>']
  output.extend(['  <stack BAL_TYPE="NONE" BAL_NUM="0">']+stack+['  </stack>'])
  output.extend(['  <layers>']+layers+['  </layers>'])
  output.extend(['  <vias>']+vias+['  </vias>'])  
  output.extend(['  <substrates/>','</SubstrateModel>'])  
  with open(foutName,'wb') as fout: fout.write('\n'.join(output))

def copyTechFiles(files,outdir):
  import shutil
  for ff in files: 
    if os.path.isfile(ff):
      tgt = '.'.join(ff.split('.')[1:])
      if not(os.path.isfile(tgt)): shutil.copyfile(ff,outdir+'/'+tgt)
    else: sys.stderr.write('Could not copy: '+ff+'\n')

def checkDir(path):
  if not os.path.isdir(path): raise IOError('Outdirectory does not exist: '+path)
  else: return path

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
import re, layout, argparse, indstack; from numtools import numToStr as n2s, isNumber
argparser = argparse.ArgumentParser(description='Creates momentum files\n - *.subst\n - materials.matdb\n',formatter_class=argparse.RawTextHelpFormatter)
argparser.add_argument(dest='inputFile', nargs='+',help='file(s) ending with .eqvStack')
argparser.add_argument('-exclude', dest='exclude', type=checkEx, help='exclude number from the top (oxides). DEFAULTS to oxides >= topMetal')
argparser.add_argument('-dummy', dest='dummy', type=checkPosNum, default='1', help='Dummification factor. DEFAULTS to "1.0"')
argparser.add_argument('-ltb', dest='ltb', type=checkEx, default=0, help='Loss Tangent for Dielectrics. DEFAULTS to "0.0"')
argparser.add_argument('-csvstack', dest='csv', action='store_true', help='create *.csv stack files')
argparser.add_argument('-outdir', dest='outdir', default='.', type=checkDir, help='Target folder, defaults to current')
argparser.add_argument('-shortstack', dest='shortStack', nargs='?', const = '4', help='ShortStack of the top 4 or <whateverTheInputIs>')
argparser.add_argument('-ltt', dest='ltt', type=checkEx, default=0, help='Loss Tangent for top Dielectrics. DEFAULTS to "0.0"')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
lti = args.ltt
## Compute the materials and assign Intrinsic lossTangent
conds,diels,semis = [],set(),set(); 
for inputFile in args.inputFile:
  stackInfo = indstack.read(inputFile,dummy=args.dummy,exclude=args.exclude,lti=lti,ltb=args.ltb,PR=None)
  foutName = os.path.basename(os.path.splitext(stackInfo.fileName)[0])
## get the materials
  temp = stackInfo.getMatdb()
  conds.extend(temp[0]); diels.update(temp[1]); semis.update(temp[2])
## modify the substrates based on the materials
  stack,layers,vias = stackInfo.getSubstrate(indMetals=args.shortStack)
## print the substrate files
  printSubst(stack,layers,vias,args.outdir+'/'+foutName+'_'+str(stackInfo.dumF).replace('.','p')+'D_'+str(stackInfo.ltb).replace('.','p')+'lt.subst')
## copy the library.tech and tech.db
#  copyTechFiles(stackInfo.techfiles,args.outdir)
## print the csv if requested
  if args.csv:
    with open(args.outdir+'/'+foutName+'.csv','wb') as fout: fout.write(stackInfo.printCsv())
## print the materials file
printMatdb(conds,diels,list(semis),args.outdir+'/materials.matdb')


