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
#   Type >> htmlReport.py -h 
##############################################################################
## Functions
def getResult(entry,cellName,flow,tool):
  result = 'UNKNOWN'; decision = {'CORRECT':'PASS','INCORRECT':'FAIL'}
  if tool == 'icv': checkStr = r'Final comparison result\s*:\s*(\w+)' if flow == 'icv_lvs' else r'TOP LAYOUT ERRORS RESULTS\s*:\s*(\w+)' 
  else: checkStr = r'((?:IN)?CORRECT)\s+'+cellName if flow == 'calibre_lvs' else r'##XX##XX##NOTHING'
  with open(entry) as fIn: 
    for line in fIn:  
      test = re.search(checkStr,line)
      if test: result = decision.get(test.group(1),test.group(1)); break
  return result

def createHtmlFile(entry):
  if os.path.isfile('html'): os.remove('html')
  elif not os.path.isdir('html'): os.mkdir('html') ## create the folder  
  with open(entry) as fId:
    htmlText = '<pre>'+''.join(fId.readlines())+"</pre>"
  link = os.path.basename(entry)+'.html'
  with open('html/'+link,'wb') as fOut: fOut.write(htmlText); return link

def createMainHtml(results,flowList,stats):
  flowLine = ''.join(['<td><h3>'+flow+'</h3></td>' for flow in flowList]); 
  total=sum([ii[1] for ii in stats.items()]); color = {'PASS':'green','FAIL':'red','CLEAN':'green','ERRORS':'red','UNKNOWN':'#666600'}
  testCaseLines = ''
  for cellName,cFlowInfo in results.items():
    testCaseLines += '<tr><td>'+cellName+'</td>' + ''.join(['<td><a href="'+os.path.basename(cFlowInfo[flow][1])+'" style="color:'+color.get(cFlowInfo[flow][0])+'">'+cFlowInfo[flow][0]+'</a></td>' if flow in cFlowInfo.keys() else '<td></td>' for flow in flowList])+'</tr>'
  htmlStr = '<table cellspacing="1" border="1"><tr><td colspan="2" ><h1>SUMMARY</h1></td></tr>'
  htmlStr += ''.join(['<tr><td>'+key+'</td><td><font color='+color.get(key,'black')+'>'+str(keyVal)+' ('+numtools.numToStr(keyVal*100.0/total,1)+'%)</font></td></tr>' for key,keyVal in stats.items() if keyVal != 0])
  htmlStr += '<tr><td>Total</td><td>'+str(total)+'</td></tr></table><br>'
  htmlStr += '''<table cellspacing="1" border="1"><tr><td><center><h3>CellName\\Flow</center></h3></td>'''+flowLine+'''</tr>
<body>
'''+testCaseLines+'''
</body></table><p><i><small>Contact Mauricio HTML Productions for support<small><i><p>''' 
  fHtml = 'html/fullLog.html'
  with open(fHtml,'wb') as fOut: fOut.write(htmlStr); return fHtml
  
def createCsv(results,flowList):
  resultStr = ','.join(['CELLNAME\FLOW']+flowList)+'\n'
  for cellName,cFlowInfo in results.items():
    effFlowRes=''
    for flow in flowList: effFlowRes += ','+cFlowInfo[flow][0] if flow in cFlowInfo.keys() else ','
    resultStr += cellName+effFlowRes+'\n'
    with open('fullLogs.csv','wb') as fout: fout.write(resultStr)

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, itertools, re, subprocess
import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python'); import numtools, lvqaUtils
argparser = argparse.ArgumentParser(description='Create an html report for Runset Runs')
argparser.add_argument('-input', dest='input', nargs='+', type=lvqaUtils.targetFiles, default=[lvqaUtils.targetFiles('.')], help='Dir(s) or file(s) to compute')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: logs.csv')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## Check for the input
lstFiles = list(set(itertools.chain(*args.input))); lstFiles.sort();
if not any(lstFiles): raise argparse.ArgumentTypeError('File(s) or Dir(s) given aren\'t or don\'t contain ANY report files')
## Run for each file creating the table
results={}; flowList=set(); stats={'PASS':0,'FAIL':0,'UNKNOWN':0}
for entry in lstFiles:
  ## split and get entry info
  cellName,flow,tool = lvqaUtils.getEntryInfo(entry)
  link = createHtmlFile(entry)
  flowList.update([flow])
  ## find out the result and create the html file inside the folder
  if cellName not in results.keys(): results[cellName]={}
  cResult = getResult(entry,cellName,flow,tool); 
  results[cellName][flow] = tuple([cResult,link]);
  if cResult in ['PASS','CLEAN']: stats['PASS']+=1;
  elif cResult in ['FAIL','ERRORS']: stats['FAIL']+=1
  else: stats['UNKNOWN']+=1
## get flow list
flowList = sorted(list(flowList))
fHtml = createMainHtml(results,flowList,stats)
subprocess.call('/p/foundry/env/bin/arora '+fHtml+'&',shell=True)
## Create the html file and csv file if requested
if args.csvFile: createCsv(results,flowList)

exit()
