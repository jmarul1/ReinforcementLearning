#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> runset.py -h 
##############################################################################

def getCells(libName,cellNames):   ## get the cells with support to regular expression
  import os, cadence
  cdsFile = os.getenv('CDSLIB') if os.getenv('CDSLIB') else os.getenv('WARD')+'/cds.lib';
  cdsObj = cadence.readCds(cdsFile); effCells=[]  
  for topCell in cellNames: 
    if os.path.splitext(topCell)[1]=='.gds': effCells += [topCell] 
    elif libName: effCells += cdsObj.getLibCells(libName,'^'+(topCell.strip().rstrip('$').lstrip('^'))+'$')
    else: sys.stderr.write('Provide a gds file or cellName/libName\n')
  if not effCells: sys.stderr.write('No GDS files or no cells in the library\n')
  return effCells

def cmdCalibre(gds,cellName,runset,flow,cdl):
  import os, calibre
  calEng = '/nfs/pdx/disks/wict_tools/eda/mentor/calibre/2016.4_38-aoi/bin/calibre '
  calEng = os.getenv('MGC_HOME')+'/bin/calibre '
  qrcEng = os.getenv('QRC_HOME')+'/bin/qrc '
  if os.getenv('PROCESS_NAME'): process = os.getenv('PROCESS_NAME').lstrip('p')
  else: process = os.getenv('PROJECT').lstrip('p'); 
  output = ['source $Calibre_RUNSET/p'+process+'.env']
  output += ['setenv DR_INPUT_FILE '+gds]
  output += ['setenv DR_INPUT_FILE_TYPE GDS'] 
  output += ['setenv DR_INPUT_CELL '+cellName]   
  if flow in ['lvs','QRC'] and cdl: 
    output += ['setenv DR_SCH_FILE '+cdl,'setenv DR_SCH_CELL '+cellName]    
    if flow == 'lvs':
      output += [calEng+'-spice '+cellName+'.net $Calibre_RUNSET/p'+process+'_'+flow+'.svrf >& netgen.log']
      output += [calEng+'-hier -lvs -layout '+cellName+'.net $Calibre_RUNSET/p'+process+'_'+flow+'.svrf >& '+flow+'_calibre.log']
    else:
      calibre.copyQRCFiles(os.getcwd(),cellName+'.spf',cdl) #copy the files for qrc
      output += ['setenv DR_CASESENSITIVE YES','setenv DR_RCEXTRACT YES','setenv DR_EXTRACT_CUSTOM_MIM YES']  
      output += [calEng+'-hier -turbo -lvs $Calibre_RUNSET/p'+process+'_lvs.svrf >& lvs_calibre.log']
      output += [calEng+'-query svdb < $Calibre_RUNSET/query.cmd >& query.log']
      output += [qrcEng+'-lic_queue -cmd qrc_urcl.cmd -64 >& qrc.log']
            
  else:  
    output += [calEng+'-drc -hier $Calibre_RUNSET/p'+process+'_'+flow+'.svrf >& '+flow+'_calibre.log']
  return '\n'.join(output)

def createCdl(lib,cellName,include):
  import subprocess, os
  if os.path.splitext(cellName)[1] in ['.cdl','.sp']: cdlFile = cellName
  else:
    incFiles = ' -include '+(' '.join(include)) if include else ''; cdlFile = cellName+'.sp'
    cmd = subprocess.Popen('strmCdl.py '+cellName+incFiles+' -lib '+lib, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE);
    cmd.communicate()
      
def getFlows(runset):
  import subprocess,os
  if not runset: return ['No_Flows_Available']
  cmd = subprocess.run("find "+runset+" -name '*.svrf' | grep 'drc\|lvs\|den\|IP' | grep -v 'windows\|black'",shell=True,stdout=subprocess.PIPE)
  flows = cmd.stdout.decode()
  flows = [re.sub(r'^p\d+_','',os.path.splitext(os.path.basename(ff))[0]) for ff in flows.split()]
  return flows+['QRC']

def getLayerMap():
  import subprocess
  layerDir = os.getenv('INTEL_PDK')+'/libraries/tech/pcell'
  cmd = subprocess.Popen("find "+layerDir+" -name '*.layermap'",shell=True,stdout=subprocess.PIPE,text=True)
  layermap = cmd.communicate()[0]
  cmd = subprocess.Popen("find "+layerDir+" -name '*.objectmap'",shell=True,stdout=subprocess.PIPE,text=True)
  objectmap = cmd.communicate()[0]
  return layermap,objectmap
  
def createDescription(runset):
  flows = getFlows(runset)
  flows.sort(); cols = 5
  descrip = 'Available Physical Verification flows:\n'
  for nn,flow in enumerate(flows):
    if nn == 0: descrip += 'Calibre Flows:\n'
    maxL = max(len(ii) for ii in flows)+1;
    space = ''.join(' ' for jj in range(maxL-len(flow)))
    descrip += flow+space
    if (nn+1)%cols == 0: descrip += '\n'
  return descrip

def createDir(cell,flow):
  import subprocess
  workDir = cell+'.'+flow
  if os.path.exists(workDir): subprocess.call('chmod -R +w '+workDir+' ; rm -rf '+workDir,shell=True); 
  os.mkdir(workDir)
  return os.path.realpath(workDir)  

def readResults(cell,flow,workDir,cleanup):
  import re
  files = os.listdir(workDir)
  if flow == 'lvs' and 'lvs.report' not in files: return False
  elif flow == 'QRC' and cell+'.spf' not in files: return False
  elif flow != 'lvs' and 'drc.sum' not in files: return False
  ## drc.sum/lvs.report are there
  if cleanup: subprocess.run('rm -rf '+' '.join([f'{workDir}/{ff}' for ff in files if not re.search(r'^(lvs.report|drc.sum)$',ff)]),shell=True)
  return True

def getIncludes(): 
  cdl = []
  if os.getenv('INTEL_RF'):
    cmd = subprocess.run("find "+os.getenv('INTEL_RF')+"/libraries/rf/cdl -name '*.cdl'",shell=True,stdout=subprocess.PIPE)
    cdl += [re.sub(r'\n',' ',cmd.stdout.decode()).strip()]
  if os.getenv('INTEL_PDK'):      
    cmd = subprocess.run("find "+os.getenv('INTEL_PDK')+"/models/custom/cdl -name '*.cdl'",shell=True,stdout=subprocess.PIPE)
    cdl += [re.sub(r'\n',' ',cmd.stdout.decode()).strip()]
  return cdl

def useBatchMode(cells,cdlF,lib,flows,includes,pool,cleanup):
  import netbatch as nb, os, multiprocessing
  cells = getCells(args.libName,args.cellName); jobs = {}; pool = multiprocessing.Pool(pool); timeout = 460; remains=False
  cleanup = ' -cleanup ' if cleanup else ' '
  lib = (f' -lib {lib} ') if lib else ''  
  for cell in cells:
    for flow in flows:
      cdl = f' -cdl {cdlF}' if flow == 'lvs' and cdlF else ''
      cmd = f'runCalibre.py {cell}{lib}{cdl} -flow {flow}{cleanup}-include '+(' '.join(includes)); 
      jobs[f'{cell}{lib} {flow}'] = pool.apply_async(nb.submitV2,(cmd,),{'interactive':True,'stdout':None,'stderr':True})
  for jobName,jobP in jobs.items(): 
    try: jobP.get(timeout*60); ## wait for the jobs
    except Exception as err: print(f'JOB: {jobName} canceled, it took more than {timeout} minutes'); remains=True
  if remains: print('Some Jobs Not Completed'); pool.terminate()
  else: print('ALL Jobs Completed')

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, shutil, subprocess, tempfile, re
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import qa, shell
tempParser = argparse.ArgumentParser(add_help=False)
tempParser.add_argument('-runset', dest='runset', default=os.getenv('Calibre_RUNSET'), help='Runset path')
tempArgs = tempParser.parse_known_args()[0]
argparser = argparse.ArgumentParser(parents=[tempParser],description=createDescription(tempArgs.runset),formatter_class=argparse.RawTextHelpFormatter,usage='runCalibre.py cellName [cellName ...] [-h] [-lib LIBNAME] [-runset RUNSET] [-flow {see below} [flow ...]] [-include INCLUDE]')
argparser.add_argument(dest='cellName', nargs='+', help='cellName (supports regular expressions)')
argparser.add_argument('-lib', dest='libName', help='Library Name')
argparser.add_argument('-flow', dest='flow', nargs='+', metavar='Flow', choices=getFlows(tempArgs.runset), default=['drcc'], help='DRC flow, see above')
argparser.add_argument('-include', dest='include', nargs = '+', default=getIncludes(), help='Include file(s)')
argparser.add_argument('-batch', dest='batch', nargs='?', const=100, type=int, help='use netbacth, provide max # jobs to run in parallel, default to 100')
argparser.add_argument('-cdl', dest='cdl', type = os.path.realpath, help=argparse.SUPPRESS)
argparser.add_argument('-cleanup', dest='cleanup', action='store_true', help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
######## if NETBATCH 
if args.batch: useBatchMode(args.cellName,args.cdl,args.libName,args.flow,args.include,args.batch,args.cleanup); exit(0)
########
cells = getCells(args.libName,args.cellName); outLst = []
for cc in cells:
  ## if gds is given use it
  if os.path.splitext(cc)[1] == '.gds': gdsFile = os.path.realpath(cc); cc = os.path.basename(os.path.splitext(cc)[0]); genGds = False#rem = False
  else: genGds = True ## generate gds
  for flow in args.flow:
    ## create the directory and cd into it
    workDir=createDir(cc,flow); cwd = os.getcwd(); os.chdir(workDir)
    if genGds: ## generate gds
      layermap,objectmap = getLayerMap(); gdsFile = os.path.realpath(cc+'.gds');
      print(('... Generating GDS: '+cc+'.gds')); 
      cmd = subprocess.run('strmOut.py '+cc+' -lib '+args.libName+' -layermap '+layermap+' -keeplog', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE);
    ## generate cdl
    if args.cdl: cdlFile = args.cdl
    elif flow in ['lvs','QRC']: print(('... Generating CDL: '+cc+'.sp')); createCdl(args.libName,cc,args.include); cdlFile = os.path.realpath(cc+'.sp')
    else: cdlFile = None
    ## create command for CAL and RUN it
    csh= cc+'_'+flow+'.csh'
    with open(csh,'w') as fout: fout.write(cmdCalibre(gdsFile,cc,args.runset,flow,cdlFile)+'\n')
    print(('... Running: '+cc+' for '+flow)); subprocess.run('csh '+csh, shell=True)
    os.chdir(cwd)
    ## read the results
    if readResults(cc,flow,workDir,args.cleanup): outLst.append('QA_RESULTS:'+cc+'_'+flow+': SUCCESS'); print((outLst[-1]))     ## clean directory for lesser space if requested, leaving only the drc.dum and lvs.report
    else: outLst.append('QA_RESULTS:'+cc+'_'+flow+': FAIL'); print((outLst[-1]))   
## print the report  
print(('-------------\n'+('\n'.join(outLst))))
exit()
