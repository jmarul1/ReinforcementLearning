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
# Report bugs to: Mauricio Marulanda
# Description:
#   Type >> runset.py -h 
##############################################################################

def checkGds(path):
  if os.path.isfile(path):
    if os.path.splitext(path)[1] in ['.gds','.oas','stm']: return os.path.realpath(path)
    else: return False
  else: raise argparse.ArgumentTypeError('File doesn\'t exist or is a directory: '+path)

def checkCdl(path):
  if os.path.isfile(path):
    if os.path.splitext(path)[1] in ['.cdl','.sp']: return os.path.realpath(path)
    else: return False
  else: raise argparse.ArgumentTypeError('File doesn\'t exist or is a directory: '+path)

def getDotProcess(tool='icv'): 
  if tool == 'calibre': return {'3':'dotThree','4':'dotFour','5':'dotFive','6':'dotSix'}.get(os.getenv('FDK_DOTPROC'),os.getenv('FDK_DOTPROC'))
  else: return '_dr'+{'3':'dotThree','4':'dotFour','5':'dotFive','6':'dotSix'}.get(os.getenv('FDK_DOTPROC'),os.getenv('FDK_DOTPROC'))

def getProject(): import os; return {'fdk73':'1273','fdk71':'1271','f1275':'1275'}.get(os.getenv('PROJECT'))  

def runIcv(flow,gdsPath,layoutType,topCell,cdlPath,overRidePath,workDir):
  import tempfile, os
  project = getProject()
  cwd = os.getcwd();      overrides = '-I '+os.path.realpath(overRidePath) if overRidePath else ''
  result = '#!/usr/bin/env tcsh\n'#source /nfs/ch/disks/ch_icf_fdk_pvr_002/cal_share/shell/icv/.cshrc.icv\n'
  if flow=='lvs':
    ruleFile = args.runset+'/trclvs.rs'
    result += 'echo "Running ICV nettran"\n'
    result += 'icv_nettran -sp '+cdlPath+' -sp-slashSpace -outName ./'+topCell+'.netlist.icv_format >& '+topCell+'.netlist2icv.log\n'
    netlist=' -s '+topCell+'.netlist.icv_format -sf ICV -D NOCLD -D REMOVE_DANGLING_PORT_NONE -D _drSECTION_LEVEL=_drYES -D _drLVS=1 -vue -D _drPRUNE=_drNONE -D _drICFDEVICES=1 -D _drEXTRACT_CUSTOM_MIM -D _drICFMIM'
    cpydb = ' '+overrides
  else:
    if not(os.path.isdir('CPYDB') or project == '1271'): # assume that if exists, no need to create, #subprocess.call('chmod -R +w CPYDB; rm -r CPYDB',shell=True)  
      shutil.copytree(os.path.join(args.runset,'CPYDB'),'CPYDB')
    if project != '1271': subprocess.call('chmod -R +w CPYDB',shell=True)  
    ruleFile = args.runset+'/'+flow + '.rs' if flow not in ['cmden_collat','cden_collat','lden_collat','drcd_pin_check','template_checker'] else args.runset+'/UTILITY/'+flow + '.rs'
    netlist=' -ex -D _drPRUNE=_drNONE -D _drICFDEVICES=1'
    if flow == 'drcd' and args.onlydrc: netlist += ' -D _dr'+args.onlydrc ##only run a metal
    if flow == 'drcd' and project=='1275': netlist += ' -D _drEnable_All_Metal_Template' ##only 1275
    if flow == 'denallIP': overrides+=denallOverwrite(flow,workDir)
    cpydb = ' -I '+cwd+' '+overrides
  if not os.path.isfile(ruleFile): argparse.ArgumentTypeError('Invalid/Unsupported flow for ICV')   
  result += 'echo "Running '+flow+'"\n'        
  result += 'icv -dp'+str(args.cpu)+' -turbo -D _drMaxError='+str(args.maxError)+' -D _drPROCESS='+getDotProcess()+' '+netlist
  result += ' -c ' + topCell + ' -i '+gdsPath+' -f '+layoutType+cpydb+' -I '+args.runset+'/PXL '+ruleFile+'  >& '+flow+'.log\n'
  foutN = tempfile.mkstemp(prefix=flow+'_',suffix='.tcsh',dir=workDir)[1]
  with open(foutN,'wb') as fout: fout.write(result)
  return foutN
  
def runCal(flow,gdsPath,layoutType,topCell,cdlPath,workDir):
  import tempfile
  project = getProject()
  result = '#!/usr/bin/env tcsh\n' #source /nfs/ch/disks/ch_icf_fdk_pvr_002/cal_share/shell/cal/.cshrc.cal\n'  
  result += 'setenv Calibre_RUNSET '+args.runset+'\nsetenv DR_PROCESS '+getDotProcess(args.tool)+'\nsource $Calibre_RUNSET/p'+project+'.env\nsetenv DR_INPUT_FILE '+gdsPath+'\n'
  result += 'setenv DR_INPUT_FILE_TYPE '+layoutType+'\nsetenv DR_LAY_CELL '+topCell+'\n'
  result += 'setenv DR_EXTRACT_CUSTOM_MIM YES\n' # in 1275
  if flow in ['HV','drcdcon']: result += 'setenv CALIBRE_ENABLE_NET_APEX 1\n'
  if flow == 'lvs':
    result += 'setenv DR_SCH_FILE '+cdlPath+'\nsetenv DR_SCH_CELL '+topCell+'\n'
    engine = '-'+flow+' -spice lay.sp ' 
  else: engine = '-drc '
  ruleFile = args.runset+'/p'+project+'_'+flow+'.svrf'; #localRuleFile = 'local_'+flow+'.svrf'  
  if not os.path.isfile(ruleFile): argparse.ArgumentTypeError('Invalid/Unsupported flow for Calibre')  
  result += 'echo "Running '+flow+'"\n'        
  result += 'calibre '+engine+'-hier -turbo -hyper '+ruleFile+' >& '+flow+'.log\n'
  foutN = tempfile.mkstemp(prefix=flow+'_',suffix='.tcsh',dir=workDir)[1]
  with open(foutN,'wb') as fout: fout.write(result)
  #with open(workDir+'/'+localRuleFile,'wb') as fout: fout.write('LAYOUT INPUT EXCEPTION SEVERITY POLYGON_DEGENERATE 1\nLAYOUT INPUT EXCEPTION SEVERITY MISSING_REFERENCE 1\nINCLUDE '+ruleFile+'\n')
  return foutN

def putInCwd(topCell,workDir):
  if args.tool == 'icv':
    for ii in ['.TOP_LAYOUT_ERRORS','.LVS_ERRORS']:
      if os.path.isfile(workDir+'/'+topCell+ii): shutil.copyfile(workDir+'/'+topCell+ii,flow+'_'+args.tool+'.'+topCell+ii)
  else:
    ending = {'lvs.report':'.lvs_report','lvs.report.ext':'.lvs_report_ext','layout.erc.summary':'.layout_erc_summary'}
    for ii in ['lvs.report','lvs.report.ext','layout.erc.summary']:
      if os.path.isfile(workDir+'/'+ii): shutil.copyfile(workDir+'/'+ii,flow+'_'+args.tool+'.'+topCell+ending.get(ii,ii))

def getFlows(tool,override=None):
  import os, re
  project = getProject(); calRunset = os.getenv('Calibre_RUNSET'); icvRunset = os.getenv('INTEL_RUNSETS')
  if tool == 'calibre':
    if not(calRunset and os.path.isdir(calRunset)): return ['NONE']#['gden','DFM','IPall','drcc','lvs','drcdcon','HV','denall_collat','cmden']
    flows = filter(lambda ff: os.path.splitext(ff)[1]=='.svrf',os.listdir(os.getenv('Calibre_RUNSET')))
    flows = filter(lambda ff: ff!='',map(lambda ff: '_'.join(os.path.splitext(ff)[0].split('_')[1:]),flows) )
  else:
    if not(icvRunset and os.path.isdir(icvRunset)): return ['NONE']#['lvs','grden','gden','drcd','drc_TUC','drc_SK','drc_LU','drc_IPall','drc_IOgnac','drc_IL','drc_HV','dfm']+['cmden_collat','cden_collat','lden_collat','drcd_pin_check','template_checker'] 
    utility = '/Utility' if project=='1271' else '/UTILITY'
    if override: sourceFlows = os.listdir(os.getenv('INTEL_RUNSETS'))+os.listdir(os.getenv('INTEL_RUNSETS')+utility)+os.listdir(os.getenv('INTEL_RUNSETS')+'/PXL')
    else: sourceFlows = os.listdir(os.getenv('INTEL_RUNSETS'))+os.listdir(os.getenv('INTEL_RUNSETS')+utility)
    flows = filter(lambda ff: os.path.splitext(ff)[1]=='.rs',sourceFlows)
    flows = map(lambda ff: os.path.splitext(ff)[0], flows)
  flows = set(map(lambda ff: re.sub('.*lvs.*','lvs',ff),flows))
  return list(flows)

def denallOverwrite(flow,workDir):
  files = [(args.runset+'/PXL/'+ff,jj) for ff,jj in (('p12745_LDcfg.rs','LD'),('p12745_CDcfg.rs','CD'),('p12745_CMcfg.rs','CM')) if args.runset+'/PXL/'+ff]
  if not files: return ''
  fins = map(lambda ff: (open(ff[0],'rb'),ff[1]),files)
  ##  read and replace
  for fin,repl in fins:
    with open(workDir+'/'+os.path.basename(fin.name),'wb') as fout: fout.write(re.sub(r'(g_'+repl+'_STEP_VAR\s*=\s*)\d+(\.\d+|\.)?',r'\g<1>'+str(args.window)+'.0',fin.read(),flags=re.I)); fin.close() 
  return ' -I .' #we know we are working at that dir    

def createDescription(icv,cal):
  icv.sort(); cal.sort(); cols = 5
  descrip = 'Available Physical Verification flows:\n'
  for nn,tool in enumerate((icv,cal)):
    descrip += 'ICV Flows:\n' if nn==0 else 'CALIBRE Flows:\n'  
    maxL = max(len(ii) for ii in tool);
    for ii,flow in enumerate(tool):
      space = ''.join(' ' for jj in xrange(maxL-len(flow)))
      descrip += flow+space
      if (ii+1)%cols == 0: descrip += '\n'
    if len(tool)%cols != 0: descrip +='\n\n'
  return descrip
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, shutil, subprocess, tempfile, re
icvChoices = getFlows('icv'); calChoices = getFlows('calibre')
tempParser = argparse.ArgumentParser(add_help=False)
tempParser.add_argument('-tool', dest='tool',default='icv', choices = ['calibre','icv'],help='tool to use, defaults to ICV')
tempArgs = tempParser.parse_known_args()[0]; toolChoices = calChoices if tempArgs.tool == 'calibre' else icvChoices ## parse the tool argument
argparser = argparse.ArgumentParser(parents=[tempParser],description=createDescription(icvChoices,calChoices), formatter_class=argparse.RawTextHelpFormatter,usage='runset.py gds [gds ...] [-h] [-tool {calibre,icv}] [-runset RUNSET] [-flow {see below} [flow ...]] [-cdl CDL] [-overrides OVERRIDE]')
argparser.add_argument(dest='gds', nargs='+', type=checkGds, help='gds file(s)')
argparser.add_argument('-runset', dest='runset', default=os.getenv('Calibre_RUNSET') if tempArgs.tool == 'calibre' else os.getenv('INTEL_RUNSETS'),help='runset path, defaults to $INTEL_RUNSETS(icv) and $Calibre_RUNSET(calibre)')
argparser.add_argument('-flow', dest='flow',metavar = 'See above',choices=toolChoices,nargs='+',default=['drcc'] if tempArgs.tool=='calibre' else ['drcd'], help='flow to run, defaults to drcd(icv) or drcc(calibre)')
argparser.add_argument('-cdl', dest='cdl', type=checkCdl, help='cdl path when running lvs, only one gds is supported')
argparser.add_argument('-overrides', dest='override', help='override directory path')
argparser.add_argument('-cpu', dest='cpu', choices=range(1,16),default=16,type=int,help=argparse.SUPPRESS)
argparser.add_argument('-onlydrc', dest='onlydrc',default='',nargs='?',help=argparse.SUPPRESS)
argparser.add_argument('-cleanup', dest='clean',action='store_true',help=argparse.SUPPRESS)
argparser.add_argument('-ws', dest='window',type=int,default=32,help="Step Window for denallIP, 2 < integer < 32")
argparser.add_argument('-maxerror', dest='maxError',type=int,default=30000,help=argparse.SUPPRESS)
args = argparser.parse_args();
##############################################################################
# Main Begins
##############################################################################

## Check if the runset is valid
if not os.path.isdir(args.runset): raise argparse.ArgumentTypeError('Rule directory is not valid: '+args.runset)

## Run for each FLOW 
project = os.getenv('PROJECT'); assert project; workDirLst=[]
for flow in args.flow:
  ## Error checking and flow fixing
  if flow == 'lvs': 
    if not args.cdl and args.onlydrc == 'trace': 
      args.cdl = tempfile.mkstemp(prefix='dummy',suffix='.cdl')[1]
      with open(args.cdl,'wb') as cdlOut: cdlOut.write('.subckt dummy n p\n.ends\n'); 
    elif not args.cdl: raise argparse.ArgumentTypeError('CDL is needed for LVS')
    if len(args.gds) > 1: raise argparse.ArgumentTypeError('Only one gds is supported for lvs')
  ## Run for each GDS 
  for iiGds in filter(lambda ff: ff!=False, set(args.gds)):
    topCell,ext = os.path.splitext(os.path.basename(iiGds))
    gdsType = ('GDSII' if args.tool == 'icv' else 'GDS') if ext in ['.gds','.stm'] else 'OASIS'
    statusFile = '.'+topCell+'_'+flow+'_'+args.tool+'.running'
    if os.path.isfile(statusFile): print ' '.join(['INFO:',args.tool,flow,'for',topCell,'is already running']); continue ## make sure not running twice in the same folder
    with open(statusFile,'wb') as fout: fout.write('Running log file\n') ## create the running file
    ## create the working dir
    workDir = flow+'_'+args.tool+'.'+topCell; 
    if args.clean: workDir = os.path.realpath(tempfile.mkdtemp(prefix=workDir+'_'))
    elif not os.path.exists(workDir): os.mkdir(workDir) ## asume you have written permissions 
    elif os.path.isfile(workDir): subprocess.call('chmod -R +w '+workDir+' ; rm -f '+workDir,shell=True); os.mkdir(workDir)
    workDirLst.append(workDir)
    ## create the files and run  
    if args.tool == 'icv':
      runFile = runIcv(flow,iiGds,gdsType,topCell,args.cdl,args.override,workDir)
      print '\n##\nUsing ICV with the script: '+os.path.realpath(runFile) if args.clean else os.path.relpath(runFile)+'\n'
    else:
      runFile = runCal(flow,iiGds,gdsType,topCell,args.cdl,workDir)
      print '\n##\nUsing Calibre with the script: '+os.path.realpath(runFile) if args.clean else os.path.relpath(runFile)+'\n'  
    test = subprocess.call('cd '+workDir+' ; tcsh '+os.path.basename(runFile),shell=True)
    ## Copy the results
    if test != 0: print '\n##\nThere were tool errors with '+args.tool
    else: 
      putInCwd(topCell,workDir)
      print '\n##\nSuccess running '+args.tool+' on '+topCell+ext
    os.remove(statusFile)

if args.clean: subprocess.call('sleep 5 && rm -rf '+' '.join(workDirLst)+' &',shell=True)      
