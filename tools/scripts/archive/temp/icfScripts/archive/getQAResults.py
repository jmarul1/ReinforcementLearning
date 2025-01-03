#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.               #
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
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> getQAResults.py -h 
##############################################################################

def prepareInput(path):
  import os, re, sys
  if not os.path.isdir(path): raise argparse.ArgumentTypeError('Path doesn\'t exist: '+path)
  test = re.search(r'(pcell|pycell)',path)
  if test: return test.group(1),path
  else: print >> sys.stderr,'Path does not specify pcell/pycell, "pcell" assumed'; return 'pcell',path
  
def format(wb,**kArgs):
  import xlsxwriter as xls
  link_f = wb.add_format({'color':'blue','underline':1})
  heading_f = wb.add_format({'color':'black','bg_color':'#FFCC99','bold':True,'align':'left','font_size':11})
  request = kArgs.get('tipo','default')
  semiDef = wb.add_format({'font_size':kArgs.get('size',10),'color':kArgs.get('color','black'),'bold':kArgs.get('bold',False),'align':kArgs.get('align','center')})
  return {'hyperlink':link_f,'heading':heading_f,'default':semiDef}.get(request)

def owner(category):
  import re
  ownDt = {'varactor':'Seo','decap':'Alex','mfc':'CT','tmdio':'Alex','cpr':'Alex','tcn':'Alex','pattern':'CT','hybrid':'Alex','gnac':'Alex','esd_wrappers':'Matt','bgdio':'Alex','ind':'Mauricio','scalable':'Mauricio','esd':'Anish','dnw_mvs':'CT'}
  test=re.search(r'(varactor|decap|mfc|tmdio|cpr|tcn|pattern|hybrid|gnac|esd_wrappers|bgdio|ind|scalable|esd|dnw_mvs)',category,flags=re.I)
  if test: return ownDt.get(test.group(1).lower(),'Mauricio')
  else: return 'Mauricio'

def getDispoDt(inCsv):
  import csvUtils
  newDict={'template':[],'dispo':[],'ar':[]}; dt = csvUtils.dFrame(inCsv);
  for ii,oatype in enumerate(dt['OATYPE']):
    newDict['template'].append('#'.join([oatype,dt['FLOW'][ii],dt['CATEGORY'][ii]]))
    newDict['dispo'].append(decodeMe(dt['ERROR_COMMENTS'][ii]))
    newDict['ar'].append(decodeMe(dt['AR'][ii]))
  return newDict

def decodeMe(string):
  try: string.encode('ascii','ignore')
  except UnicodeDecodeError: return 'ASCII ISSUE'
  else: return string

##############################################################################
# Argument Parsing
##############################################################################
import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import argparse, os, re, csvUtils, xlsxwriter as xls, time, libUtils
argparser = argparse.ArgumentParser(description='Creates a CSV file with a summary of the LVQA runs')
argparser.add_argument(dest='runPath', nargs = '+', type=prepareInput, help='Path to the megatest runs')
argparser.add_argument('-unix', dest='unix', action='store_const', const='', default='file://pdxsmb', help='Unix links or windows(default)')
argparser.add_argument('-outdir', dest='outdir', default=os.getenv("transferDir"), help='Unix links or windows(default)')
argparser.add_argument('-src', dest='src', type=getDispoDt, help='SRC of previous DISPO')
argparser.add_argument('-nout', dest='out', action='store_false', help='Dont print locally')
args = argparser.parse_args()

##############################################################################
# Main Begins
##############################################################################

#flows
#flows = ['prepare_gds','prepare_cdl','icv_pds_drc','icv_pds_den','icv_pds_trclvs','icv_drc','icv_den','icv_lvs']
flows = ['prepare_gds','prepare_cdl','icv_drc','icv_den','icv_lvs','calibre_drc','calibre_den','calibre_lvs','starrc_xtract','starrc_cal_xtract','pvs_drc','pvs_den','pvs_lvs','pvs_xtract','qrc_calibre']
flowCol = ['#000099','#990000']

#prepare the output sheet
outWbk = xls.Workbook(args.outdir+'/qa.xlsx'); 
outLst = []; outLine=''; badStrLst=[]
sheetName = time.strftime('%y'+'ww'+str(int(time.strftime('%W'))+1)+'.%w')
sheet = outWbk.add_worksheet(name=sheetName);
foutName = os.path.join(os.getenv('FDK_WORK'),'myDocs','releaseWork',os.getenv('FDK_NAME').split('_')[-1],'LVQA',sheetName+'.csv')
foutBad  = os.path.join(os.getenv('FDK_WORK'),'myDocs','releaseWork',os.getenv('FDK_NAME').split('_')[-1],'LVQA/bad',sheetName+'.txt'); notRunFlow=''

#headings
for cc,item in enumerate(['OATYPE','FLOW','CATEGORY','STATUS','RESULT','OWNER','ERROR_COMMENTS','AR']): sheet.write_string(0,cc,item,format(outWbk,tipo='heading')); sheet.set_column(cc,cc,len(item)+5); outLine+= item+','
rr=1;colMax=0; outLst.append(outLine)

## run for each path and flow
for oaType,mainDir in args.runPath:
  for ff,flow in enumerate(flows):
    htmlFile = os.path.join(mainDir,flow,'megatest-rollup-'+flow+'.html')
    #open the file if exists
    if not os.path.isfile(htmlFile): notRunFlow+=oaType+' '+flow+'\n'; continue
    fin = open(htmlFile,'rb')
    rows = re.findall(r'<tr>.*?<a(.+?)</tr>',fin.read())
    for row in rows: # read each row of the table
      test = re.search(r'href\s*=\s*(.+?)\s*>',row)
      if not test: continue
      link = os.path.join(args.unix+mainDir,flow,test.group(1).strip('"')); link = re.sub(r'(.*)test-summary.html',r'\1custom.html',link)
      entries = re.findall(r'>\s*(\w+)\s*<',row)
      if not any(entries): continue
      if len(entries) != 3:
        badStrLst.append('%-6s %-17s %-12s %s' % (oaType,flow,entries[0],entries[1]))
	print badStrLst[-1]
	for dd in xrange(len(entries),3): entries.append('errFLOW') #if not finished set RESULT to NONE
      ## write the row
      cc = 0
      sheet.write_string(rr,cc,oaType,format(outWbk,color=flowCol[ff%2])); cc+=1; outLine=oaType+','
      sheet.write_string(rr,cc,flow,format(outWbk,color=flowCol[ff%2])); cc+=1; outLine+=flow+','
      sheet.write_url(rr,cc,link,format(outWbk,tipo='hyperlink'),entries[0]); cc+=1; outLine+=entries[0]+','
      for item in entries[1:]:
    	if re.search(r'pass',item,flags=re.I): sheet.write_string(rr,cc,item,format(outWbk,color='green'));  
    	elif re.search(r'fail',item,flags=re.I): sheet.write_string(rr,cc,item,format(outWbk,color='red',bold=True));
    	else: sheet.write_string(rr,cc,item,format(outWbk))
    	cc+=1;outLine+=item+','
      ## assign owners
#      sheet.write_string(rr,cc,owner(entries[0]),format(outWbk,color='#00666666')); cc+=1; outLine+=owner(entries[0])+','
      sheet.write_string(rr,cc,libUtils.getOwner(entries[0]),format(outWbk,color='#00666666')); cc+=1; outLine+=libUtils.getOwner(entries[0])+','
      test = '#'.join([oaType,flow,entries[0]])
      if args.src and test in args.src['template']: 
        item=args.src['dispo'][args.src['template'].index(test)]; sheet.write_string(rr,cc,item); cc+=1; outLine+= item+','
	item=args.src['ar'][args.src['template'].index(test)]; sheet.write_string(rr,cc,item); cc+=1; outLine+= item+','
      rr+=1;colMax=max(colMax,cc); 
      
      outLst.append(outLine)
sheet.autofilter(0,0,rr,colMax+1)      
outWbk.close()

print '---------------------------------'
print 'Excel: '+args.outdir+'/qa.xlsx'
if args.out:
  with open(foutName,'wb')as fout: fout.write('\n'.join(outLst))
  print 'CSV: '+foutName

## store bad flows if any
if not(notRunFlow==''): badStrLst.append('Flows not Run:\n'+notRunFlow)
if badStrLst and os.path.isdir(os.path.dirname(foutBad)) and not(os.path.isfile(foutBad)):
  with open(foutBad,'wb') as fout: fout.write('\n'.join(badStrLst))
