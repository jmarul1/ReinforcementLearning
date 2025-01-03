#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> runset.py -h 
##############################################################################

def temporalEnvHack():
  import subprocess, os
  test = os.path.basename(os.path.dirname(os.getenv('WARD')))
  print(test)
  if test == 'hyp5dot28':
    intel22rf = '/nfs/pdx/disks/wict_tools/pdk/p1222/1.0/rf2222_r0.5HP4/libraries/rf/pcell/be22/intel22rf'
    subprocess.run(f'addLib {intel22rf}',shell=True)
    
def getCells(libName,cellNames):   ## get the cells with support to regular expression
  import os, cadence
  cdsFile = os.getenv('CDSLIB') if os.getenv('CDSLIB') else os.getenv('WARD')+'/cds.lib';
  cdsObj = cadence.readCds(cdsFile); effCells=[]  
  for topCell in cellNames: 
    if os.path.splitext(topCell)[1].lower() in ['.gds','.oas']: effCells += [topCell] 
    elif libName: effCells += cdsObj.getLibCells(libName,'^'+(topCell.strip().rstrip('$').lstrip('^'))+'$')
    else: sys.stderr.write('Provide a gds file or cellName/libName\n')
  if not effCells: sys.stderr.write('No GDS files or no cells in the library\n')
  return effCells

def cmdIcv(gds,cdlFile,cellName,runset,flow,cpus,overrides=''):
  import os
  if overrides and os.path.isdir(overrides): overrides = '-I '+overrides
  else: overrides = ''
  if flow == 'trclvs' and not os.path.isfile(cdlFile): return 'echo '+cdlFile+' did not generate or does not exist'
  icvEng = os.getenv('ICV_HOME_DIR')+'/bin/LINUX64_L30el/icv ' 
  lvs = ['-sf spice','-s',cdlFile,'-D','_drTOPCHECK=_drcheck'] if flow == 'trclvs' else []  
  flow,layerByLayer = selectFlow(flow); beVar = os.getenv('INTEL_LAYERSTACK')
  if flow not in ['cden_collat','lden_collat']: rsFile = runset+'/'+flow+'.rs'
  else: rsFile = '-I '+runset+'/../../icvutility/'+beVar+'/PXL '+runset+'/../../icvutility/'+beVar+'/'+flow+'.rs' 
  cpus = '-dp'+str(cpus)
  opts = ['-c',cellName,'-i',gds]+lvs+['-D _drPROCESS=_dr'+os.getenv('DR_PROCESS')+' -D _drEnableRF=_drYES',layerByLayer,cpus,'-I','.',overrides,'-I',runset+'/PXL',rsFile]
  opts = opts+(['-f OASIS'] if os.path.splitext(gds)[1].lower()=='.oas' else [''])
  output = ' >& '+flow+'_icv.log'
  return icvEng+(' '.join(opts))+output

def selectFlow(flow):
  import re
  test = re.search(r'^drc_((?:[MV]\d+)|(?:base)|(?:MIM)|(?:NOW)|(?:DNW)|(?:DF)|(?:PL)|(?:DC)|(?:PC)|(?:BM)|(?:DT)|(?:WT))$',flow)
  if test: return 'drcd','-D _dr_select_'+test.group(1)
  else: return flow,''

def getDotTemp():
  test = os.getenv('INTEL_LAYERSTACK')
  return test
  
def createCdl(lib,cellName,include):
  import subprocess, os
  if os.path.splitext(cellName)[1] in ['.cdl','.sp']: cdlFile = cellName;
  else:
    incFiles = ' -include '+(' '.join(include)) if include else ''; cdlFile = os.path.realpath(cellName+'.sp')
    cmd = subprocess.run('strmCdl.py '+cellName+incFiles+' -lib '+lib, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    with open(f'{cellName}.cdllog','w') as fout: fout.write(cmd.stderr+cmd.stdout)
  return cdlFile
       
def getFlows(runset):
  import subprocess,os,re
  if not runset: return ['No_Flows_Available']
  cmd = subprocess.Popen("find "+runset+" -name '*.rs' | grep -v defines",shell=True,stdout=subprocess.PIPE)
  flows = cmd.communicate()
  flows = [os.path.splitext(os.path.basename(ff))[0] for ff in flows[0].decode().split()]
  flows = [ff for ff in flows if re.search(r'(^tapein)|drc|lvs|den', ff)]
  for ii in range(1,9): flows.append('drc_M'+str(ii)); flows.append('drc_V'+str(ii))
  flows+=['drc_base','drc_MIM','drc_NW','drc_NOW','drc_DNW','drc_DF','drc_PL','drc_DC','drc_PC','drc_BM','drc_DT','drc_WT']
  flows+=['cden_collat','lden_collat'] #utility
  return flows

def getLayerMap(runset):
  import subprocess
  beVar = os.getenv('INTEL_LAYERSTACK')
  layermap = [os.getenv('INTEL_PDK')+'/libraries/tech/pcell/'+beVar+'/intel22tech/intel22tech.layermap',os.getenv('INTEL_PDK')+'/libraries/tech/pcell/'+beVar+'/intel22tech/intel22tech.objectmap']
  if not os.path.isfile(layermap[0]): 
    cmd = subprocess.Popen("find "+runset+"/PXL -name 'p*.map'",shell=True,stdout=subprocess.PIPE)
    layermap = cmd.communicate()
  return layermap[0].strip()
  
def createDescription(runset):
  flows = getFlows(runset)
  flows.sort(); cols = 5
  descrip = 'Available Physical Verification flows:\n'
  for nn,flow in enumerate(flows):
    if nn == 0: descrip += 'ICV Flows:\n'
    maxL = max(len(ii) for ii in flows)+1;
    space = ''.join(' ' for jj in range(maxL-len(flow)))
    descrip += flow+space
    if (nn+1)%cols == 0: descrip += '\n'
  return descrip

def createDir(cell,flow):
  import subprocess
  workDir = cell+'.'+flow
  if os.path.exists(workDir): subprocess.call('chmod -R +w '+workDir+' ; rm -rf '+workDir,shell=True,stderr = subprocess.PIPE);  #try to erase
  if not os.path.exists(workDir): os.mkdir(workDir)
  return os.path.realpath(workDir)  

def readResults(cell,workDir):
  import re
  if cell+'.RESULTS' not in os.listdir(workDir): return False
  with open(workDir+'/'+cell+'.RESULTS') as fin: result=fin.read(); test=re.search(r'RESULTS:\s*(RUN)?\s*ABORT',result,flags=re.I)
  if test: sys.stderr.write(result); return False
  return True

def useBatchMode(cells,cdls,lib,flows,overrides,includes,jobsP,cpus):
  import netbatch as nb; from jobFeed import waitForJobs; import os
  cells = getCells(lib,cells); jobs = []; countLvs = 0; print('\n')
  lib = (' -lib '+lib) if lib else ''  
  for cell in cells:
    for flow in flows:
      if flow == 'trclvs' and cdls and countLvs < len(cdls): cdl = ' -cdl '+cdls[countLvs]; countLvs+=1
      else: cdl = ''
      cmd = 'runIcv.py '+cell+lib+cdl+' -flow '+flow+' -overrides '+overrides+' -include '+(' '.join(includes))+' -cpus '+str(cpus)
      if len(jobs) < jobsP:
        if cdl:
          cdl =  os.path.basename(cdl.lstrip(' -cdl '))
          if os.path.splitext(cell) in ['.gds','.oas']: print(('Netbatch submission: '+(','.join([cell,cdl,flow]))))  # whend gds/cdl pair
          else: print(('Netbatch submission: '+(','.join([lib.lstrip(' -lib '),cell,cdl,flow]))))  # when lib,cell,cdl pair
        elif os.path.splitext(cell) == '.gds': print(('Netbatch submission: '+(','.join([cell,cdl,flow]))))
        else: print(('Netbatch submission: '+(','.join([lib.lstrip(' -lib '),cell,flow])))) # when lib,cell
        jobs.append(nb.submit(cmd,interactive=True))
      else: waitForJobs(jobs,False);
  while len(jobs) > 0: waitForJobs(jobs,False)
  print('ALL Jobs completed')
  exit()

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, shutil, subprocess, tempfile, re, qa,pdkutils
tempParser = argparse.ArgumentParser(add_help=False)
tempParser.add_argument('-runset', dest='runset', default=os.getenv('INTEL_RUNSETS'), help='Runset path')
tempArgs = tempParser.parse_known_args()[0]
argparser = argparse.ArgumentParser(parents=[tempParser],description=createDescription(tempArgs.runset),formatter_class=argparse.RawTextHelpFormatter,usage='runIcv.py cellName [cellName ...] [-h] [-lib LIBNAME] [-runset RUNSET] [-flow {see below} [flow ...]] [-include INCLUDE] [-overrides OVERRIDE]')
argparser.add_argument(dest='cellName', nargs='+', help='cellName (supports regular expressions)')
argparser.add_argument('-lib', dest='libName', help='Library Name')
argparser.add_argument('-flow', dest='flow', nargs='+', metavar='Flow', choices=getFlows(tempArgs.runset), default=['drcd'], help='DRC flow, see above')
argparser.add_argument('-overrides', dest='overrides', default=os.getenv('WARD')+'/icv/overrides', help='Override Directory')
argparser.add_argument('-include', dest='include', nargs = '+', default=pdkutils.getCdlIncludes(), help='Include file(s)')
argparser.add_argument('-batch', dest='batch', nargs='?', const=100, type=int, help='use netbacth, provide max # jobs to run in parallel, default to 100')
argparser.add_argument('-cdl', dest='cdl', nargs='+', type = os.path.realpath, help=argparse.SUPPRESS)
argparser.add_argument('-cpus', dest='cpus', default = 2, type=int, help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

###USE THE NETBATCH in PARALLEL ##########
if args.batch: useBatchMode(args.cellName,args.cdl,args.libName,args.flow,args.overrides,args.include,args.batch,args.cpus if args.cpus else 20)
###USE THE NETBATCH in PARALLEL ##########
temporalEnvHack()
cells = getCells(args.libName,args.cellName); outLst = []; count = 0; 
for cc in cells:
  ## if gds is given use it
  if os.path.splitext(cc)[1].lower() in ['.gds','.oas']: gdsFile = os.path.realpath(cc); cc = os.path.basename(os.path.splitext(cc)[0]); genGds = False
  else: genGds = True
  for flow in args.flow:
    ## create the directory and cd into it
    workDir=createDir(cc,flow); cwd = os.getcwd(); os.chdir(workDir)
    if genGds: ## generate gds
      layermap = getLayerMap(args.runset); gdsFile = os.path.realpath(cc+'.gds'); print(gdsFile)
      print(('... Generating GDS: '+cc+'.gds')); 
      cmd = subprocess.Popen('strmOut.py '+cc+' -lib '+args.libName+' -layermap '+layermap+' -keeplog', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE); cmd.communicate();
    ## generate cdl
    if flow == 'trclvs': 
      if args.cdl and count < len(args.cdl): cdlFile = createCdl(args.libName,args.cdl[count],args.include); count+=1
      else: print(('... Generating CDL: '+cc+'.sp')); cdlFile = createCdl(args.libName,cc,args.include);  
    else: cdlFile = False
    ## create command for ICV and RUN it
    csh= cc+'_'+flow+'.csh'
    with open(csh,'w') as fout: fout.write(cmdIcv(gdsFile,cdlFile,cc,args.runset,flow,args.cpus,overrides=args.overrides)+'\n')
    print(('... Running: '+cc+' for '+flow)); subprocess.call('source '+csh, shell=True)    
    os.chdir(cwd)
    ## read the results
    if readResults(cc,workDir): outLst.append('QA_RESULTS:'+cc+'_'+flow+': RUN COMPLETE');# print outLst[-1]
    else: outLst.append('QA_RESULTS:'+cc+'_'+flow+': ABORTED'); #print outLst[-1]
## print the report  
print(('-------------\n'+('\n'.join(outLst))))
exit()
