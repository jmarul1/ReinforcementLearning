#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
 
import sys; sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import argparse, os, re, subprocess

def getEmDirs(path):
  if not os.path.isdir(path): raise IOError('Not valid dir: '+path)
  temp = [ii for ii in [path+'/'+ff for ff in os.listdir(path)] if re.search(r'^em',os.path.basename(ii),flags=re.I)]
  if not temp: raise IOError('Dir does not have EM dirs: '+path)
  return temp

def checkDir(path):
  if not os.path.isdir(path): raise IOError('Not valid dir: '+path)
  return path
  
## Argument Parsing
argparser = argparse.ArgumentParser(description='Copy EM dirs from ref to targets')
argparser.add_argument(dest='tgt', nargs='+', type=checkDir, help='CellName Dir(s) to target')
argparser.add_argument('-ref', dest='ref', required=True, type=getEmDirs, help='Directory of Ref cell REF/layout/EM_FOLDERs')
argparser.add_argument('-copy', dest='copy', action='store_false', help='Copy True|"False"')
args = argparser.parse_args()

## Copy all dirs to the tgt and create AEL file for simulation file generation
simulation = []
for tgt in args.tgt:
  temp = os.path.realpath(tgt); libName = os.path.basename(os.path.dirname(temp)); cellName = os.path.basename(temp)
  for emDir in args.ref:
    cmd = 'cp -fRLT '+emDir+' '+tgt+'/'+os.path.basename(emDir)
    if args.copy: subprocess.call(cmd, shell=True)
    print((emDir+' created in '+tgt))
    emDir = os.path.basename(emDir.replace('%',''))
    simulation.append('dex_em_writeSimulationFiles("'+('","'.join([libName,cellName,emDir,'simulation/'+libName+'/'+cellName+'/layout/'+emDir+'_MoM']))+'");')

with open('createSimulationFiles.ael','wb') as fout: fout.write('\n'.join(simulation))
print(('Load "'+os.path.realpath('createSimulationFiles.ael')+'" to create simulation files'))
