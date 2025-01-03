#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

## Functions
def getErrs(fname,flow,ignoreReg=None):# return error resuls, <ERRORS for HTML>, path to file
  import subprocess as sb, tempfile, os
  errors=[]; tmp = tempfile.TemporaryFile(); 
  if not os.path.isfile(fname): 
    outcome = 'ABORTED||NotStarted'; log = []
    if os.path.isdir(fname): log = list(filter(lambda ff: os.path.splitext(ff)[1]=='.log', os.listdir(fname)))
    if log and os.path.isfile(fname+'/'+log[0]): outcome,errors = getStatusRun(fname+'/'+log[0])
    return outcome,errors,(fname+'/'+log[0] if log else '')
  if flow == 'trclvs_CMP': 
    outcome = 'FAIL'; cmd = "grep -il '^\s*Final comparison result:\s*FAIL' "+fname
    test = sb.run(cmd, shell = True, stdout = subprocess.PIPE,text=True).stdout;
    if test.strip() == '': outcome = 'PASS'
  else:
    outcome = 'ERRORS'; cmd = "grep -il '^\s*TOP LAYOUT.*RESULTS: ERRORS' "+fname
    test = sb.run(cmd, shell = True, stdout = subprocess.PIPE,text=True).stdout; 
    if test.strip() == '': outcome = 'CLEAN'
    else:
      errors = errorDescr(fname);
      if ignoreReg: errors = list(filter(lambda ff: not re.search(r''+ignoreReg,ff,flags=re.I), errors))
      if not errors: outcome = 'CLEAN'
  return outcome,errors,os.path.realpath(fname)
      
def createHtml(results,flowList,dirtyOnly=False):
  flowLine = ''.join(['<td><h3><center>'+flow+'</center></h3></td>' for flow in flowList]); 
  tcLines = []
  for cellName in results.keys():
    cFlowInfo = results[cellName]    
    entry = '<tr><td>'+(cellName)+'</td>'; empty=True
    for flow in flowList:   
      if flow not in cFlowInfo.keys(): entry += '<td></td>'; continue ## check if the cellName has that flow
      outcome,errors,path = cFlowInfo[flow]
      color = 'green' if outcome in ['PASS','CLEAN'] else 'red'
      if outcome in ['ABORTED','RUNNING']: color = 'magenta'
      if color == 'green' and dirtyOnly:  entry += '<td></td>'; continue ## its clean 
      entry += '<td><center><a href="'+path+'" style="color:'+color+'">'+outcome+'</a></center>'; empty=False
      for error in errors: entry += error+'<br>'
      entry += '</td>'
    if not empty: tcLines.append('\n'+entry+'</tr>\n') #if no items in the line (CLEAN when args.dirty is TRUE)
  htmlStr = '<table cellspacing="1" border="1"><tr><td><h3><center>CellName \\ Flow</center></h3></td>'+flowLine+'</tr>\n'
  htmlStr += ''.join(tcLines)+'\n</table>\n'
  fHtml = 'errorDisplay.html'
  with open(fHtml,'wb') as fOut: fOut.write(htmlStr.encode()); return fHtml

def decipher(fname):
  import re, os
  test = re.search(r'(\w+)\.(\w+)', os.path.dirname(fname))
  if test: return test.group(1),test.group(2)
  else: return False,False

def getLogs(path):
  logs = []  
  if os.path.isdir(path):
    for ff in os.listdir(path):
      if re.search('(LVS_ERRORS|TOP_LAYOUT_ERRORS)$',ff): logs.append(path+'/'+ff)
    if not logs: logs.append(path+'/')  
  return logs

def getLvsFlowName(log):
  if re.search('LVS_ERRORS$',log): return 'trclvs_CMP'
  else: return 'trclvs_LAY'

def errorDescr(fname): #make it faster for lden collat
  import re, subprocess
  errors = []
  with open(fname) as fin:
    fetch = False;
    for line in fin:
      if re.search(r'^\s*ERROR SUMMARY',line): fetch = True
      if re.search(r'^\s*ERROR DETAILS',line): break
      if fetch:
        test = re.search(r'^\s*(\S+):',line)
        if test: errors.append(test.group(1))
        test = re.search(r'\.+\s*(\d+)\s+violation',line)
        if test and errors[-1]: errors[-1] = errors[-1]+' -- '+test.group(1)
  return errors	

def getStatusRun(logFile):
  import subprocess
  status = []
  cmd = "sed -n -r '/ *ICV_.*[0-9]*% complete\| *IC Validator did not complete/p' "+logFile
  log = subprocess.run(cmd,shell=True,stdout=subprocess.PIPE,text=True);
  if log.stdout:
    for line in log.stdout.split('\n'):
      if re.search(r'IC Validator did not complete',line): return 'ABORTED',[]
      test = re.search(r'(\d+%) complete',line)
      if test: status.append(test.group(1))
    if len(status)>0: return 'RUNNING',[status[-1]]
  return 'ABORTED',[]
  

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, itertools, re, subprocess, math, sys, itertools, htmlreport
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import numtools, csvUtils
argparser = argparse.ArgumentParser(description='Create an html report for the Runset Runs ICV',formatter_class=argparse.ArgumentDefaultsHelpFormatter)
argparser.add_argument(dest='logs', nargs='+', type=getLogs, help='log dir(s) to compute')
argparser.add_argument('-ignore', dest='ignore', type=str, help=argparse.SUPPRESS) # regex to ignore in the html report
argparser.add_argument('-dirty', dest='dirty', action='store_true', help=argparse.SUPPRESS) # only dirty ones
argparser.add_argument('-csv', dest='csv', action='store_true', help=argparse.SUPPRESS) # print in csv
args = argparser.parse_args()
# Main Begins
##############################################################################
args.logs = list(set(itertools.chain(*args.logs))); args.logs.sort()## Organize input
errors = {}; flowLst=[]
for cc,log in enumerate(args.logs):
  cell,flow = decipher(log)
  if cell and cell not in errors.keys(): errors[cell] = {}
  if cell and flow:
    if flow == 'trclvs': flow = getLvsFlowName(log)
    errors[cell][flow] = getErrs(log,flow,args.ignore)
    flowLst.append(flow)  
## Correct the LVS if missing
for cell,flowInfo in errors.items():
  lvs = ('trclvs_CMP' in flowInfo.keys()); lay = ('trclvs_LAY' in flowInfo.keys())
  if lvs^lay and lvs: errors[cell]['trclvs_LAY'] = getErrs(cell+'.trclvs/','trclvs_LAY')
  if lvs^lay and lay: errors[cell]['trclvs_CMP'] = getErrs(cell+'.trclvs/','trclvs_CMP')
##print the html
fHtml = createHtml(errors, list(set(flowLst)), args.dirty )
subprocess.call('firefox '+fHtml+'&',shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
if args.csv: htmlreport.htmlToCsv(fHtml)
exit()
