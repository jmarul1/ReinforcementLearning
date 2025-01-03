#!/usr/bin/env python2.7
###################################
## CREATED BY Mauricio Marulanda ##
###################################

## Functions    
def createHtml(lines):
  htmlStr = '<h1 style="color:green">LATEST EM STACK RELEASES</h1>\n'
  fLine = ''.join(['<th><middle><h2><center>'+hh+'</center></h2></middle></th>' for hh in lines[0].split(',')[:-2]])
  htmlStr += '<table cellspacing="2" border="1"><tr>'+fLine+'</tr>\n';  oldTech = ''; bgClrs = ['#FFE9E9','lightcyan','#FFFFCC','#CCFFE5']; count=0
  for ii,line in enumerate(lines[1:]):
    args = line.split(',')[:-2]; dlPath = line.split(',')[-2]; emPath = line.split(',')[-1]; effLine = ''
    newTech = re.search(r'(p\d+)',args[0]).group(1); count+=newTech!=oldTech; bgColor=bgClrs[count%len(bgClrs)]; oldTech=newTech
    for col,hh in enumerate(args):
      if col == 2: effLine+='<td bgcolor="'+bgColor+'"><middle><center><a href="'+emPath+'" style="color:blue">'+hh+'</center></middle></td>'
      elif col in [5,6]: effLine+='<td bgcolor="'+bgColor+'"><middle><center><a href="'+dlPath+'" style="color:blue">'+hh+'</center></middle></td>'
      else: effLine+='<td bgcolor="'+bgColor+'"><middle><center>'+hh+'</center></middle></td>'
    htmlStr += '<tr>'+effLine+'</tr>\n'
  htmlStr += '</table>\n'    
  fHtml = 'emStkReport.html'
  with open(fHtml,'wb') as fOut: fOut.write(htmlStr); return fHtml

def getDirDump():
  import os
  dirDump = '/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/.htmlStkDump'
  lst = os.listdir(dirDump); map(lambda ff: os.remove(dirDump+'/'+ff), lst)
  return dirDump
  
def getVersion(path):
  import os
  base = os.path.basename(path)
  test = re.search(r'^p.+?(x.*)_',base,flags=re.I)
  if test: return test.group(1)
  else: return 'unknown'

def getDumLt(tech,dot,dt,dirDump):
  import ltdstack, math, numtools
  cFactor,lt,path = 'WIP','WIP','invalid'; substrate,epi = 'unknown','unknown'
  if all(ii in dt.keys() for ii in ['compEM','unCompEM']):
    comp,unComp = filter(lambda ff: re.search(r'tttt.*.ltd$',ff), dt['compEM']), filter(lambda ff: re.search(r'tttt.*.ltd$',ff), dt['unCompEM'])
    if comp and unComp:
      ltdCo,ltdUn = ltdstack.read(comp[0]), ltdstack.read(unComp[0]); oxides = []; 
      for ss, val in ltdCo.stacks:
        if ss == 'LAYER' and 'MATERIAL' in val.keys() and val['MATERIAL'] in ltdCo.materials.keys():
          if not re.search(r'(substrate|epi)',val['MATERIAL'],flags=re.I):
            material = val['MATERIAL']
            epsrCo,epsrUn = float(ltdCo.materials[material]['PERMITTIVITY']),float(ltdUn.materials[material]['PERMITTIVITY'])
            factor,losst = epsrCo/epsrUn,float(ltdCo.materials[material]['LOSSTANGENT']) if 'LOSSTANGENT' in ltdCo.materials[material].keys() else 0.0
            oxides.append([val['MATERIAL'],epsrUn, factor, losst])
          elif re.search(r'substrate',val['MATERIAL'],flags=re.I): substrate = float(numtools.numToStr(ltdCo.materials[val['MATERIAL']]['RESISTIVITY'],2))
          else: epi = float(numtools.numToStr(ltdCo.materials[val['MATERIAL']]['RESISTIVITY'],2))
      cFactor,lt,path = createOxideTbl(oxides,ltdUn,epi,substrate,tech,dot,dirDump)
  return cFactor,lt,path

def createOxideTbl(oxides,ltdUn,epi,substrate,tech,dot,dirDump):
  import ltdstack, numtools, tempfile
  exclude,topMask = ltdstack.getExcludeNum(ltdUn); bgColor = 'white'; 
  compOx = []; lt = []; fetch = False
  htmlStr = '<h1 style="color:red">'+tech+'.'+dot+'</h1><h3 style="color:green">Epi: '+numtools.numToStr(epi)+' (Ohms.cm)<br>Substrate: '+numtools.numToStr(substrate)+' (Ohms.cm)</h3>\n'
  fLine = ''.join(['<h1><th>'+ff+'</th></h1>' for ff in ['Oxide','EPSR','multiplier','lossTangent']])
  htmlStr += '<table cellspacing="2" border="1">'+fLine+'\n';
  for ii,oo in enumerate(oxides):
    if ii == int(exclude)-1: item = '<middle>'+oo[0]+('<h4>( '+topMask.upper()+' )</h4>')+'</middle>'; 
    elif ii == int(exclude): item = oo[0]; bgColor = 'lightcyan'; fetch = True
    else: item= oo[0]
    items = [item]+map(lambda ff: numtools.numToStr(ff,2), oo[1:])
    items = ''.join(['<td bgcolor="'+bgColor+'"><center>'+ff+'</td></center>' for ff in items])
    htmlStr += '<tr>'+items+'</tr>\n'
    if fetch: compOx.append(oo[2]); lt.append(oo[3])
  htmlStr += '</table>\n' 
  tmp = tempfile.mkstemp(dir=dirDump,suffix='.html')[1];
  with open(tmp,'wb') as fout: fout.write(htmlStr)
  compOx,lt = numtools.numToStr(reduce(lambda x,y: x+y, compOx)/len(compOx),2), numtools.numToStr(reduce(lambda x,y: x+y, lt)/len(lt),2)
  compOx,lt = map(lambda ff: str(float(ff)), [compOx,lt])
  return compOx,lt,tmp 

def getMetals(dt):
  import ltdstack, numtools
  metals = []; masks = []; maskVias = []; vias = []; semis = [];
  if 'unCompEM' in dt.keys():
    unComp = filter(lambda ff: re.search(r'tttt.*.ltd$',ff), dt['unCompEM'])
    if unComp: 
      ltdUn = ltdstack.read(unComp[0]); mult = ltdstack.getMult(ltdUn.units['DISTANCE'])
      for ff in ltdUn.stacks:
        if ff[0] == 'INTERFACE' and 'MASK' in ff[1].keys():
          masks.append(ff[1]['MASK'])
        elif ff[0] == 'LAYER' and 'MASK' in ff[1].keys() and 'HEIGHT' in ff[1].keys():
          via = ltdstack.getMaskVals(ff[1]['MASK'],ltdUn)
          if via[0] != 'unknown': vias.append([via[0],numtools.numToStr(float(ff[1]['HEIGHT'])*mult)])	  
        elif ff[0] == 'LAYER' and 'MATERIAL' in ff[1].keys() and re.search(r'substrate|epi',ff[1]['MATERIAL'],flags=re.I) and 'HEIGHT' in ff[1].keys():
          semis.append([ff[1]['MATERIAL'],ff[1]['HEIGHT']])
      metals = [(mm[0],mm[2]) for mm in [ltdstack.getMaskVals(mask,ltdUn) for mask in masks]]
      for ss,hh in semis:
        if ss in ltdUn.materials.keys() and 'RESISTIVITY' in ltdUn.materials[ss].keys():
          mult = ltdstack.getMult(ltdUn.units['DISTANCE'])
          hh = numtools.numToStr(float(hh)*mult); res = numtools.numToStr(numtools.numToStr(ltdUn.materials[ss]['RESISTIVITY'],2)); test = re.search(r'(substrate|epi)',ss,flags=re.I)
          if test: metals.append((test.group(1),hh+'@'+res))
  return metals,vias

def addMtlToHtml(htmlF,metals,title='METALS'):
  import layout, listUtils, numtools
  layers = []; substrates = []; oldTech = ''; bgClrs = ['#FFE9E9','lightcyan','#FFFFCC','#CCFFE5']; count=0
  for hh,val in metals.items(): 
    for metal,th in val: 
      layers += [metal];
      if re.search(r'substrate|epi',metal,flags=re.I) and metal not in substrates: substrates+=[metal]
  layers = layout.sortMetalVia(sorted(listUtils.listToSet(layers,case=False))); headings = ['technology','dot']; 
  substrates = listUtils.listToSet(substrates,False)
  fLine = ''.join(['<th><middle><h3><center>'+hh+'</center></h3></middle></th>' for hh in headings])
  fLine += '<th colspan="'+str(len(layers)-len(substrates))+'"><middle><h3><center>layers (um)</center></h3></middle></th>'
  if substrates: fLine += '<th colspan="'+str(len(substrates))+'"><middle><h3><center>Substrate<br>(um@Ohm.cm)</center></h3></middle></th>'
  htmlStr = '<h1 style="color:green">TABLE OF '+title.upper()+'</h1>\n'; 
  htmlStr += '<table cellspacing="2" border="1"><tr>'+fLine+'</tr>\n';   
  for hh,val in metals.items():
    hh = hh.split('.')
    newTech = re.search(r'(p\d+)',hh[0]).group(1); count+=newTech!=oldTech; bgColor=bgClrs[count%len(bgClrs)]; oldTech=newTech
    effLine = ''.join([('<td bgcolor="'+bgColor+'"><middle><center>'+vv+'</center></middle></td>') for vv in hh])
    for ll in layers[::-1]:
      test = filter(lambda ff: re.search(r'^'+ff[0]+'$',ll,flags=re.I), val) ## find the metal 
      effLine+='<td bgcolor="'+bgColor+'"><middle><center>'+((ll+'<br>'+numtools.numToStr(test[0][1])) if test else '-')+'</center></middle></td>'
    htmlStr += '<tr>'+effLine+'</tr>\n'
  htmlStr += '</table>\n'      
  with open(htmlF,'a') as fout: fout.write('\n'+htmlStr)

def getFillers(dt):
  import os, re
  fillers = []
  if 'fillers' in dt.keys():
    fillers = filter(lambda ff: os.path.splitext(ff)[1] == '.gds', dt['fillers'])
    fillers = map(lambda ff: os.path.splitext(os.path.basename(ff))[0], fillers);
    fillers = list(filter(lambda ff: not re.search(r'sample',ff,flags=re.I), set(fillers)))
    if fillers: fillers = sorted(fillers)
    topFillers = filter(lambda ff: re.search(r'gm0|bun',ff,flags=re.I), fillers)   
    if topFillers:
      botFillers = filter(lambda ff: not re.search(r'gm0|bun',ff,flags=re.I), fillers)
      topFillers = sorted(topFillers); botFillers = sorted(botFillers)
      fillers= botFillers+topFillers
  return fillers

def addFillToHtml(htmlF,fillers):
  import layout
  layers = [];
  for hh,val in fillers.items(): layers+=val;  
  oldTech = ''; bgClrs = ['#FFE9E9','lightcyan','#FFFFCC','#CCFFE5']; count=0
  fLine = ''.join(['<th><middle><h3><center>'+hh+'</center></h3></middle></th>' for hh in ['technology','dot']])
  fLine += '<th colspan="'+str(len(layers))+'"><middle><h3><center>cells</center></h3></middle></th>'
  htmlStr = '<h1 style="color:green">TABLE OF FILLERS</h1>\n'; 
  htmlStr += '<table cellspacing="2" border="1"><tr>'+fLine+'</tr>\n'; 
  for hh,val in fillers.items():
    hh = hh.split('.')
    newTech = re.search(r'(p\d+)',hh[0]).group(1); count+=newTech!=oldTech; bgColor=bgClrs[count%len(bgClrs)]; oldTech=newTech
    effLine = ''.join([('<td bgcolor="'+bgColor+'"><middle><center>'+vv+'</center></middle></td>') for vv in hh]); 
    effLine += ''.join([('<td bgcolor="'+bgColor+'"><middle>'+cell+'</middle></td>') for cell in val])+'\n'
    htmlStr += '<tr>'+effLine+'</tr>\n'
  htmlStr += '</table>\n'      
  with open(htmlF,'a') as fout: fout.write('\n'+htmlStr)

def readSchedule(path):
  import csvUtils, re
  csv = csvUtils.dFrame(path); newDt = {}
  for ii,tech in enumerate(csv['technology']):
    dot = '/'.join(re.findall(r'\d+',csv['dot'][ii])); label = tech+'.'+dot
    newDt[label] = csv['scheduled'][ii]
  return newDt

def compRelease(old,new):
  import re
  ww = r'(\d+)ww(\d+)'
  testOld,testNew = re.search(ww,old.lower()),re.search(ww,new.lower())
  if all([testOld,testNew]):
    yyOld,wwOld,yyNew,wwNew = testOld.group(1),testOld.group(2),testNew.group(1),testNew.group(2)
    if yyNew > yyOld: return False
    elif yyNew == yyOld and wwNew > wwOld: return False
  elif testNew: return False
  return True

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, collections, time, subprocess
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'));
argparser = argparse.ArgumentParser(description='Create an html report for emStack releases and print it as CSV')
args = argparser.parse_args()
###############
## Main Begins
###############
stacks = {}; metals = collections.OrderedDict(); vias = collections.OrderedDict(); substrates = collections.OrderedDict(); dirDump = getDirDump()
#schedule = readSchedule('/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/.documentation/schedule.csv')
for tech in filter(lambda ff: os.path.isdir(ff) and re.search(r'^[pP]\d+',ff), os.listdir('.')): 
  stacks[tech]={}
  for dot in filter(lambda dd: re.search(r'^dot',dd), os.listdir(tech)): 
    dots = r'/'.join(filter(lambda ii: ii, re.split(r'\D+',dot)))
    if dots: 
      stacks[tech][dots]={}; releases = tech+'/'+dot; emStack = tech+'/'+dot+'/latest/emStackFiles'; fillers = tech+'/'+dot+'/latest/fillers'      
      compEM = emStack+'/momentumComp'; unCompEM = emStack+'/momentumUnComp';
      for pathK in ['releases','compEM','unCompEM','emStack','fillers']:
        path = eval(pathK);
        if pathK == 'emStack': stacks[tech][dots][pathK] = os.path.realpath(path)
        elif os.path.isdir(path): stacks[tech][dots][pathK] = map(lambda ii: path+'/'+ii,os.listdir(path))

outResults = ['technology,dot,version,released,scheduled,dummyFactor,losstangent,dumLtLoc,emStackLoc'];  
fillers = collections.OrderedDict()
for tech,val1 in stacks.items():
  for dot,val2 in val1.items():
    version,releaseTime = 'unknown','notRelease'
    if 'releases' in val2.keys():
      shelf = filter(lambda ff: re.search(r'/shelfRelease_(\w+)',ff),val2['releases'])
      if shelf: 
        test = re.search(r'/shelfRelease_(\w+)',shelf[0])
        version = val2['releases'] = test.group(1); 
        releaseTime = time.strftime('%yww%V',time.gmtime(os.path.getmtime(shelf[0]))); emStack = val2['emStack']
    nextRelease = 'TBD'#schedule[tech+'.'+dot] if tech+'.'+dot in schedule.keys() else 'TBD'
    if compRelease(releaseTime,nextRelease): nextRelease = 'TBD'
    ## get the metals
    metals[tech+'.'+dot],vias[tech+'.'+dot] = getMetals(val2)
    ## get the dummy/lt
    dummy,lt,dPath = getDumLt(tech,dot,val2,dirDump)
    outResults.append(','.join([tech,dot,version,releaseTime,nextRelease,dummy,lt,dPath,emStack]))
    ## get the fillers
    fillers[tech+'.'+dot] = getFillers(val2)  

htmlFile = createHtml(outResults)
## add metal table
addMtlToHtml(htmlFile,metals,title='METALS')
## add via table
addMtlToHtml(htmlFile,vias,title='VIAS')
## add filler table
addFillToHtml(htmlFile,fillers)
## display
subprocess.call('firefox '+htmlFile+'&',shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
## print
#print '\n'.join(outResults)
