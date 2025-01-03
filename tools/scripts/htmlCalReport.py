#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

## Functions
def getErrs(fname,waivers,ignoreReg=None):#in a list error space count
  import subprocess as sb, tempfile
  if re.search(r'lvs',fname): # LVS
    test = sb.run(f'grep \'CORRECT\' {fname}',shell=True,capture_output=True,text=True)
    errors = [] if test.stdout.strip() != '' else ['FF']
  else: 
    errors=[]; tmp = tempfile.TemporaryFile()
    cmd = "grep '^ *RULECHECK' "+fname+" | grep -v 'Count *= *0' "
    cmd = sb.run(cmd, shell = True, stdout = tmp);  tmp.seek(0)
    for line in tmp:
      test = re.search(r'RULECHECK\s+(.*?)\s*\.\..*Count *= *(\d+)', line.decode())
      if test: 
        errName,count = test.group(1),test.group(2)
        if ignoreReg and re.search(r''+ignoreReg,errName,flags=re.I): continue
        if waivers and errName in waivers.keys():
          if waivers[errName] == count: continue
          else: count = count+'!='+waivers[errName]
        errors.append([errName,count]);
  return errors
      
def createHtml(results,flowList,dirtyOnly=False):
  flowLine = ''.join(['<td><h3><center>'+flow+'</center></h3></td>' for flow in flowList]); 
  tcLines = []
  for cellName in results.keys():
    cFlowInfo = results[cellName]    
    entry = '<tr><td>'+(cellName)+'</td>';
    for flow in flowList:
      if flow not in cFlowInfo.keys(): entry += '<td></td>'; continue
      if len(cFlowInfo[flow]) == 0: entry += '<td><center style="color:green">PASS</center></td>'; continue
      entry += '<td><table><tr><center style="color:red">ERRORS</center></tr>'
      for error in cFlowInfo[flow]: entry += '<tr><td>'+error[0]+'</td><td>..</td><td>'+error[1]+'</td></tr>'
      entry += '</table></td>'
    if dirtyOnly and not re.search('ERRORS',entry): continue ## its clean 
    tcLines.append('\n'+entry+'</tr>\n')
  htmlStr = '<table cellspacing="1" border="1"><tr><td><center><h3>CellName \\ Flow</center></h3></td>'+flowLine+'</tr>\n'
  htmlStr += ''.join(tcLines)+'\n</table>\n'
  fHtml = 'errorDisplay.html'
  with open(fHtml,'w') as fOut: fOut.write(htmlStr); return fHtml

def decipher(fname):
  import re,os
  test = re.search(r'^cal.*?-(\w+)-(.*?)\.(?:gds|stm|oas)', fname)
  if test: return test.group(1),test.group(2)
  test = re.search(r'(\w+)\.(\w+(?:.ext)?)', os.path.basename(os.path.dirname(fname)))
  if test: return test.group(1),test.group(2)
  else: return False,False

def getLogs(path):
  if os.path.isdir(path):
    for ff in os.listdir(path):
      if re.search('(drc.sum|lvs.report(?!.ext))$',ff): return (path+'/'+ff)
  else: return False

      
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, itertools, re, subprocess, math, sys, itertools, qa
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import numtools, csvUtils
argparser = argparse.ArgumentParser(description='Create an html report for the Runset Runs Calibre',formatter_class=argparse.ArgumentDefaultsHelpFormatter)
argparser.add_argument(dest='logs', nargs='+', type=getLogs, help='log dir(s) to compute')
argparser.add_argument('-waiverfile', dest='waiverfile', type=qa.convertWaivers, help=argparse.SUPPRESS)
argparser.add_argument('-logonly',dest='logOnly',action='store_true',help=argparse.SUPPRESS)
argparser.add_argument('-ignore', dest='ignore', type=str, help=argparse.SUPPRESS) # regex to ignore in the html report
argparser.add_argument('-dirty', dest='dirty', action='store_true', help=argparse.SUPPRESS) # only dirty ones
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## Organize input
args.logs = [log for log in args.logs if log]
errors = {}; flowLst=set([]); cleanCc = True
for log in args.logs:
  cell,flow = decipher(log)
  if cell not in errors.keys(): errors[cell] = {}
  try: effWaivers = args.waiverfile['cal'][cell][flow]
  except: effWaivers = None
  errors[cell][flow] = getErrs(log,effWaivers,args.ignore)
  if len(errors[cell][flow]) > 0: cleanCc = False
  flowLst.update([flow]); 
##print the html
fHtml = createHtml(errors, flowLst,args.dirty)
if args.logOnly: print(os.path.realpath(fHtml)+' '+('PASS' if cleanCc else 'FAIL'))
else: subprocess.call('firefox '+fHtml+'&',shell=True,stdout=subprocess.PIPE, stderr=subprocess.PIPE)
exit()
