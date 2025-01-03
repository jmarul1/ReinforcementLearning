#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
#   Type >> getErrors.py -h
##############################################################################

## Functions
def getErrs(fname,waivers={}):#in a list error space count
  errors=[];
  with open(fname,'r') as fin:
    for line in fin:
      if re.search(r'^\s*Total\s+Errors',line,flags=re.I): break
      test = re.search(r'^\s*(\d+)\s+(\S+)\s*:\s*(.*)',line)
      if test:
        count,errName,errDes = test.groups()
        if waivers and errName in list(waivers.keys()):
          if waivers[errName] == count: continue
          else: count = count+'!='+waivers[errName]
        if args.ignore and re.search(r''+args.ignore,errName,flags=re.I): continue
        errors.append(tuple([errName,count,fname]));#you can add the description here
  return list(set(errors)) #list of tuples, each tuple has error - count

def getLvs(fname,waive):
  if waive: return ['PASS','dummy',fname]
  with open(fname,'r') as fin:
    for line in fin:
      test = re.search(r'^\s*Total\s+Errors\s+=\s+(\d+)',line,flags=re.I);
      if test and int(test.group(1)) > 0:
        test = re.sub(r'.stats$','.cmpall',fname)
        if os.path.exists(test): fname=test
        return ['LVSFAIL','dummy',fname]
    return ['PASS','dummy',fname]

def createHtml(results,flowList,stats,effCellLst=None):
  flowLine = ''.join(['<td><h3><center>'+flow+'</center></h3></td>' for flow in flowList]);
  tcLines = []
  for cellName in (effCellLst or list(results.keys())):
    cFlowInfo = results[cellName]
    entry = '<tr><td>'+os.path.basename(cellName)+'</td>';
    for flow in flowList:
      if flow not in list(cFlowInfo.keys()): entry += '<td></td>'; continue
      if cFlowInfo[flow][0] in ['CLEAN','PASS']:
        entry += '<td><center " style="color:green">'+cFlowInfo[flow][0]+'</center></td>'; continue
      if cFlowInfo[flow][0] in ['LVSFAIL']: entry += '<td><center><a href="'+cFlowInfo[flow][2]+'" style="color:red">FAIL</a></center></td>'; continue
      entry += '<td><table><tr><center><a href="'+cFlowInfo[flow][0][2]+'" style="color:red">ERRORS</a></center></tr>'
      for error in cFlowInfo[flow]: entry += '<tr><td>'+error[0]+'</td><td>..</td><td>'+error[1]+'</td></tr>'
      entry += '</table></td>'
    tcLines.append('\n'+entry+'</tr>\n')
  ##MAIN TABLE
  htmlStr = '<table cellspacing="1" border="1"><tr><td colspan="2" ><h1>SUMMARY</h1></td></tr>'
  htmlStr += '<tr><td>PASS</td><td><font color=green>'+str(stats[0])+' ('+numtools.numToStr(stats[0]*100.0/stats[1],1)+'%)</font></td></tr>'
  htmlStr += '<tr><td>FAIL</td><td><font color=red>'+str(stats[1]-stats[0])+' ('+numtools.numToStr((stats[1]-stats[0])*100.0/stats[1],1)+'%)</font></td></tr>'
  htmlStr += '<tr><td>Total</td><td>'+str(stats[1])+'</td></tr></table><br>\n'
  #if flow list is < 3 split in 3, < 7 split in 2
  headTbl = '<table cellspacing="1" border="1"><tr><td><center><h3>CellName \\ Flow</center></h3></td>'+flowLine+'</tr>\n'
  if args.split and len(flowList) < 3:
    s1 = int(math.ceil(len(tcLines)/3.0)); s2 = 2*s1
    htmlStr += '<div style="float: left;">\n'+headTbl+''.join(tcLines[:s1])+'\n</table>\n</div>\n'
    htmlStr += '<div style="float: left;">\n'+headTbl+''.join(tcLines[s1:s2])+'\n</table>\n</div>\n'
    htmlStr += '<div style="float: left;">\n'+headTbl+''.join(tcLines[s2:])+'\n</body></table>\n</div>\n'
  elif args.split and len(flowList) < 7:
    s1 = int(math.ceil(len(tcLines)/3.0));
    htmlStr += '<div style="float: left;">\n'+headTbl+''.join(tcLines[:s1])+'\n</table>\n</div>\n'
    htmlStr += '<div style="float: left;">\n'+headTbl+''.join(tcLines[s1:])+'\n</table>\n</div>\n'
  else:
    htmlStr += headTbl+''.join(tcLines)+'\n</table>\n'
  ## end of file
#  htmlStr += '<p><i><small>Contact Mauricio HTML Productions for support<small><i><p>'
  fHtml = 'errorDisplay.html'
  with open(fHtml,'w') as fOut: fOut.write(htmlStr); return fHtml

def getLogs(path):
  if not type(path) == str: return False
  if not os.path.exists(path): raise IOError('path does not exist: '+path)
  if os.path.isfile(path) and os.path.splitext(path)[1]=='.stats':
    if re.search(r'icvlvs.stats$',path,flags=re.I): return False
    else: return os.path.relpath(path)
  else: return False

def convertWaivers(path):
  import csvUtils
  out = {}
  try: csv = csvUtils.dFrame(path);
  except IOError: return out
  for ii,cellName in enumerate(csv['cellName']):
    tool,flow,rule,count = csv['tool'][ii],csv['flow'][ii],csv['rule'][ii],csv['count'][ii]
    if tool     not in list(out.keys()): out[tool]={}
    if cellName not in list(out[tool].keys()): out[tool][cellName] = {}
    if flow     not in list(out[tool][cellName].keys()): out[tool][cellName][flow] = {}
    if rule     not in list(out[tool][cellName][flow].keys()): out[tool][cellName][flow][rule] = {}
    out[tool][cellName][flow][rule] = count
  return out

def getWaiverDt(wvDt,tool,cellName,flow):
  cellName = os.path.basename(cellName)
  if type(wvDt)==dict and tool in list(wvDt.keys()) and cellName in list(wvDt[tool].keys()) and flow in list(wvDt[tool][cellName].keys()):
    return wvDt[tool][cellName][flow]
  return {}

def printGoldenWaivers(resutls):  ##Data for qaWaiver
  import csv
  with open('qaWaiver.csv', 'w') as csvfile:
    writer = csv.writer(csvfile, delimiter = ',')
    for cell in list(results.keys()):
      for flow in list(results[cell].keys()):
        if flow == 'trclvs' or results[cell][flow][0] == 'CLEAN' : continue
        for drID in results[cell][flow]:
          writer.writerow([cell,flow,drID[0],drID[1]])

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, itertools, re, subprocess, math, sys
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import numtools, csvUtils
argparser = argparse.ArgumentParser(description='Create an html report for the Runset Runs')
argparser.add_argument('-logs', dest='logs', nargs='+', type=getLogs, default=[os.path.relpath(os.getenv('PDSLOGS')+'/'+ff) for ff in os.listdir(os.getenv('PDSLOGS')) if os.getenv('PDSLOGS') ], help='logfile(s) to compute')
argparser.add_argument('-ignore', dest='ignore', default='',type=str, help='Regular expression to ignore errors')
argparser.add_argument('-dirtyonly', dest='dirtyonly', action='store_true', help='Only show dirty ones (NOT IMPLEMENTED YET)') #Future
argparser.add_argument('-waiverfile', dest='waiverfile', type=convertWaivers, help='waiver file with specific csv')
argparser.add_argument('-split',dest='split',action='store_true',help=argparse.SUPPRESS)
argparser.add_argument('-logonly',dest='logOnly',action='store_true',help=argparse.SUPPRESS)
argparser.add_argument('-printwaivers',dest='printWaivers',action='store_true',help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## Organize input
args.logs = list(set(filter(getLogs,args.logs))); args.logs.sort()

## Run for each file creating the table
results = {}; flowList=set(); cleanCc=0; total=0
#print(args.logs)
for entry in args.logs:
  cell,flow = entry.split('.')[-3:-1]
  if cell not in list(results.keys()): results[cell]={};
  if flow == 'trclvs': flow='trclay'
  effWaivers = getWaiverDt(args.waiverfile,'icv',cell,flow) if args.waiverfile else {}
  errors = getErrs(entry,waivers=effWaivers); flowList.update([flow])
  if errors: results[cell][flow] = errors;
  else: results[cell][flow] = ['CLEAN','dummy',os.path.relpath(entry)]; cleanCc+=1;
  total+=1
  if flow == 'trclay':
    effName = '.'.join(entry.split('.')[:-2])+'.trclvs.icvlvs.stats';
    if os.path.isfile(effName):
      flow='trclvs'; 
      effWaivers = getWaiverDt(args.waiverfile,'icv',cell,flow)
      results[cell][flow] = getLvs(effName,effWaivers); flowList.update([flow]);
      if results[cell][flow][0] == 'PASS': cleanCc+=1
      total+=1

## print the waivers for golden if needed
if args.printWaivers: printGoldenWaivers(results)

##print the html
fHtml = createHtml(results,sorted(flowList),[cleanCc,total],effCellLst=sorted(results.keys()))
if args.logOnly: print((os.path.realpath(fHtml)+' '+('PASS' if cleanCc==total else 'FAIL')))
else: subprocess.call('firefox '+fHtml+'&',shell=True)
#exit()
