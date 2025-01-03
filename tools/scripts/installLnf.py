#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################


def createTgt(lnf,lib):
  import cadence
  cdsFile = os.getenv('CDSLIB');  cdsObj = cadence.readCds(cdsFile)
  path = cdsObj.getLibPath(lib)
  lnfDir = path+'/'+lnf+'/lnf'
  if not os.path.exists(lnfDir) or os.path.isfile(lnfDir): # create the directory if it doesnt exist
    if os.path.isfile(lnfDir): os.remove(lnfDir)
    os.makedirs(lnfDir)
    with open(lnfDir+'/master.tag','wb') as fout: fout.write('-- Master.tag File, Rev:1.0\nlnf.dat')
  tgt = lnfDir+'/lnf.dat'
  return tgt
  

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, shutil
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import shell
argparser = argparse.ArgumentParser(description='Copy the LNF to the cell in the Lib')
argparser.add_argument(dest='lnf', nargs='+', help='lnf file(s)')
argparser.add_argument('-lib', dest='lib', required=True, help='Targe Lib')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
for lnf in args.lnf:
  if not (os.path.exists(lnf) or os.path.isfile(lnf)): raise IOError('File does not exists: '+lnf)
  cellName = os.path.basename(os.path.splitext(lnf)[0])
  tgt = createTgt(cellName,args.lib)
  if os.path.islink(tgt):  print 'Did not copy, cellView is probably not checked out: '+lnf
  else: 
    shutil.copy(lnf,tgt)
    print 'COPIED -- : '+args.lib+'/'+cellName+'/lnf/lnf.dat'
  
  
