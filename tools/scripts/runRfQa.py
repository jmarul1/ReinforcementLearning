#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> runRfQa.py -h 
##############################################################################

def createDir():
  import subprocess, datetime, os
  temp = datetime.date.today().isocalendar(); workArea = str(temp[0])+'ww'+str(temp[1])+'p'+str(temp[2])
  if os.path.exists(workArea):
    if args.update: return os.path.realpath(workArea)    
    else: subprocess.call('rm -rf '+workArea,shell=True)
  os.mkdir(workArea)
  return os.path.realpath(workArea)  

def readQaInstructions(csv):
  import csvUtils
  csv = csvUtils.dFrame(csv); out=[]; 
  for lib,cell,flows in zip(csv['libName'],csv['cellName'],csv['flows']):
    for ff in flows.split(','): 
      cmd = createCmd(lib,cell,ff)
      if cmd: out.append([lib,cell,ff,cmd]);
  return out

def createCmd(lib,cell,flow):
  import tempfile
  effFlow = flow.split('_')
  if effFlow[0].lower() in ['cal','icv'] and effFlow[1] in ['drcd','drcc','denall','trclvs','lvs','QRC']:
    engine = 'runIcv.py' if effFlow[0].lower() == 'icv' else 'runCalibre.py'
    cmd = [engine,cell,'-lib',lib,'-flow',effFlow[1]]  
  elif effFlow[0].lower() in ['cal','icv'] and effFlow[1] in ['xtract']:
    if effFlow[0].lower() == 'icv': cmd = ['/nfs/pdx/disks/wict_wd/pkurahas/extract',lib,cell,'-qa']  
    else: cmd = ['/nfs/pdx/disks/wict_wd/sravikum/scripts/cal_xtract',lib,cell]  
  elif flow in ['sim','simulation','montecarlo']:
    cmd = ['/nfs/pdx/disks/wict_wd/jmarulan/myDocs/qaScripts/invokeOcean.py',cell,'-lib',lib]
  elif flow in ['postlayout','postsimulation']:
    cmd = ['/nfs/pdx/disks/wict_wd/jmarulan/myDocs/qaScripts/invokeOcean.py',cell,'-lib',lib,'-post']
  else: return None
  return ' '.join(cmd)

def getReport(lib,cell,flow,logFile):
  import re, os
  logFile=os.path.realpath(logFile)
  with open(logFile) as fin:
    for line in fin:
      if re.search(r'^\s*\\i', line): continue
      test1 = re.search(r'QA_RESULTS[_:].+:\s*(RUN\s+COMPLETE|SUCCESS|PASS)',line,flags=re.I) ##### LOOKING FOR
      ### QA_RESULTS_CELLNAME: PASS
      ### QA_RESULTS:CELLNAME:PASS
      if test1: return [lib,cell,flow,['PASS',logFile]]
  return [lib,cell,flow,['FAIL',logFile]]

def convertReport(report):
  from collections import OrderedDict
  reportDt = {}; flows = []
  for lib,cell,flow,result in report:
    if lib not in list(reportDt.keys()): reportDt[lib]={}
    if cell not in list(reportDt[lib].keys()): reportDt[lib][cell]=OrderedDict()
    reportDt[lib][cell][flow] = result; flows.append(flow)
  return reportDt,list(set(flows))
    
def createHtml(workArea,report):
  reportDt,flows = convertReport(report)
  with open(workArea+'/'+'mainRunlog.html','w') as mainLog:
    mainLog.write('<table cellspacing="4" border="1"><tr><td><center><h3>'+('</h3></center></td><td><center><h3>'.join(['libName','cellName']+flows))+'</h3></center></td></tr>\n')
    for lib,cellDt in list(reportDt.items()):
      for cell,flowDt in list(cellDt.items()):
        for flow in flows: # create a new list to append to lib,cell,flows
          effFlows = []
          for flow in flows:
            if flow not in list(flowDt.keys()): effFlows.append(' ')
            else: effFlows.append('<a href="'+flowDt[flow][1]+'"><font color='+('green' if flowDt[flow][0]=='PASS' else 'red')+'>'+flowDt[flow][0]+'</a></font>')
        mainLog.write('<tr><td><center>'+('</center></td><td><center>'.join([lib,cell]+effFlows))+'</center></td></tr>\n')
  return workArea+'/'+'mainRunlog.html'

def createReportOnly(logDir):
  import os, re
  report = []
  for ff in os.listdir(logDir):
    test = re.search(r'(.+)\.(.+)\.log$',ff,flags=re.I)
    if test:
      lib,cell,flow = 'qaLib',test.group(1),test.group(2)
      report.append(getReport(lib,cell,flow,logDir+'/'+ff))
  html = createHtml('.',report)  
  print(html)      
  return html
      
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, shutil, subprocess, tempfile, re, qa, shell
argparser = argparse.ArgumentParser(description='Run the RF qa in a library')
argparser.add_argument(dest='csv', help='csv with instructions')
argparser.add_argument('-mail', dest='mail', nargs='+', default=[], help='Users to mail')
argparser.add_argument('-report', dest='reportDir',help=argparse.SUPPRESS)
argparser.add_argument('-update', dest='update', action='store_true',help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
if args.reportDir: html = createReportOnly(args.reportDir);   subprocess.call('firefox '+html+'&',shell=True); exit(1)
##############################################################################
# Main Begins
##############################################################################
## create the directory
workArea = createDir()
## create the flow commands
cmds = readQaInstructions(args.csv);
## run the flows and read the output
report = []; left = len(cmds)
for lib,cell,flow,cmd in cmds:
  print(('\n... Running '+(' '.join([lib,cell,flow]))+' still to go: -'+str(left))); left-=1
  logFile = workArea+'/'+cell+'.'+flow+'.log';
  ## run the script
  with open(logFile,'w') as fLog: test = subprocess.Popen('cd '+workArea+' ; '+cmd,stdout=fLog,stderr=fLog,shell=True); log = test.communicate(); 
  report.append(getReport(lib,cell,flow,logFile)) 
# report = [['intel22rf_qa', 'rf_xtr_inverter_chain', 'drcd', ('PASS','PASS')], ['intel22rf_qa', 'rf_xtr_inverter_chain', 'trclvs',('PASS','PASS')],['intel22rf_qa', 'rf_xtr_inverter_chain', 'extraction', ('PASS','PASS')],['intel22rf_qa', 'rf_xtr_inverter_chain2', 'simulation', ('FAIL','/nfs/pdx/home/jmarulan/work_area/transfer/test.csv')]]
## create the htmlReport
html = createHtml(workArea,report)
## e-mail
if args.mail:
  with open(html) as fin: body='Subject: '+os.path.basename(workArea)+' - runArea: '+os.path.realpath(workArea)+'\n'+'Content-Type: text/html\n'+re.sub(r'/nfs/','file://pdxsmb.pdx.intel.com/nfs/',fin.read())
  for user in args.mail: cmd = "echo '"+body+"' | sendmail "+user; subprocess.call(cmd,shell=True)
else:
  subprocess.call('firefox '+html+'&',shell=True)
