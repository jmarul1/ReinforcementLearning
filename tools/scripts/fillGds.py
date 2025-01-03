#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def createDir(cell,flow):
  import subprocess
  workDir = cell+'.'+flow
  if os.path.exists(workDir): subprocess.call('chmod -R +w '+workDir+' ; rm -rf '+workDir,shell=True); 
  os.mkdir(workDir)
  return os.path.realpath(workDir)  

def createRingFile(workDir,ring):
  with open(f'{workDir}/p1231_ind_config.svrf','w') as fout: fout.write(f'VARIABLE GR_DIST  {ring[0]}\nVARIABLE GR_WIDTH {ring[1]}\n')
  return f'{workDir}'
def getCells(libName,cellNames):   ## get the cells with support to regular expression
  import os, cadence
  cdsFile = os.getenv('CDSLIB') if os.getenv('CDSLIB') else os.getenv('WARD')+'/cds.lib';
  cdsObj = cadence.readCds(cdsFile); effCells=[]  
  for topCell in cellNames: 
    if os.path.splitext(topCell)[1] in ['.gds','oas']: effCells += [topCell] 
    elif libName: effCells += cdsObj.getLibCells(libName,'^'+(topCell.strip().rstrip('$').lstrip('^'))+'$')
    else: sys.stderr.write('Provide a gds file or cellName/libName\n')
  if not effCells: sys.stderr.write('No GDS files or no cells in the library\n')
  return effCells

def cmdCalibre(gds,cellName,runset,ringFileD):
  import os, calibre
  calEng = os.getenv('MGC_HOME')+'/bin/calibre'; foutStr = ''; format = 'GDS' if os.path.splitext(gds)=='.gds' else 'OASIS'
  ### RING setup ###################################################################
  if ringFileD: foutStr += f'setenv Fillconfig_RUNSET "{ringFileD}"\n'
  ### ENV setup ####################################################################
  foutStr += f'setenv Fill_RUNSET "{runset}"\nsetenv DR_PROCESS {os.getenv("DR_PROCESS")}\n'
  foutStr += f'setenv DR_INPUT_FILE "{gds}"\nsetenv DR_INPUT_CELL {cellName}\nsetenv DR_INPUT_FILE_TYPE {format}\n'
  foutStr += f'setenv FILL_OUTPUT_NAME {cellName}_fill.oas\n'
  ### RUN FILL #####################################################################
  foutStr += f'{calEng} -drc -hier -turbo -hyper {runset}/p1231_fill.svrf > fill.log\n'
  ### merge fill with original layout ##############################################
  foutStr += f'{calEng}drv -a layout filemerge -in {gds} -in {cellName}_fill.oas -out {cellName}_filled.oas > merge.log'
  return foutStr

### Argument Parsing #############################################################
import argparse, os, sys, re, shutil, subprocess, tempfile, re
argparser = argparse.ArgumentParser(description='fill the gds')
argparser.add_argument(dest='cellName', nargs='+', help='cellName (supports regular expressions)')
argparser.add_argument('-runset', dest='runset', default=os.getenv('Calibre_RUNSET'), help='Runset path', type=os.path.realpath)
argparser.add_argument('-lib', dest='libName', help='Library Name')
argparser.add_argument('-ring', dest='ring', nargs = 2, type = float, help='Add Ring giving floating number (um) as: "DistanceFromInductor" "Ring Width')
argparser.add_argument('-noreplace', dest='replace', action='store_false', help='overwrite the gds')
args = argparser.parse_args()

## check ring inputs
if args.ring and (args.ring[0] < 2 or args.ring[1] < 8): raise IOError('DistanceFromInductor should be > 0 and Ring Width should be > 8')
### MAIN ########### #############################################################
cells = getCells(args.libName,args.cellName); outLst = []
for cc in cells:
  ## if gds is given use it
  if os.path.splitext(cc)[1] in ['.oas','.gds']: gdsFile = os.path.realpath(cc); cc = os.path.basename(os.path.splitext(cc)[0]); genGds = False
  else: genGds = True
  ## create the directory and cd into it
  workDir=createDir(cc,'fill'); cwd = os.getcwd(); os.chdir(workDir)
  if genGds: gdsFile = os.path.realpath(cc+'.oas');  print(('... Generating OAS: '+cc+'.oas')); cmd = subprocess.run('strmOut.py '+cc+' -lib '+args.libName+' -keeplog -format oas', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE);
  ## create the ring if requested
  ringFileD = createRingFile(workDir,args.ring) if args.ring else None
  ## create command for CAL and RUN it
  csh= cc+'_'+'fill.csh'
  with open(csh,'w') as fout: fout.write(cmdCalibre(gdsFile,cc,args.runset,ringFileD))
  print(('... Running: '+cc+' for fill')); subprocess.run('csh '+csh, shell=True)
  os.chdir(cwd)
exit()

