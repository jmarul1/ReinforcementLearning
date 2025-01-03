def readQaConfig(libPath,dot='all'):
  import subprocess,re        
  cmd = 'ls '+libPath+'/*/qaConfig/text.txt'   ## get all the cell/qaConfig/text.txt
  test = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
  data = test.communicate()[0].decode(); 
  if data.strip() == '': return False
  out = [];
  for ff in data.split():  ## read each file and extract cell,tool,flow
    cellName = list(filter(str.strip,ff.split('/')))[-3]; toolFlow = {}
    with open(ff) as fin:
      for line in fin:
        line = line.strip().split('#')[0]
        if line == '': continue 
        line = re.split(r'\W+',line);  ## by definition we have tool:flow1,flow2 or dot:dot#
        if len(line) <= 1: continue
        tool = line[0]; flows = list(filter(str.strip,line[1:]));
        if not flows: continue
        if re.search(r'^dot',tool,flags=re.I): # if there is no dot in the file continue for all
          if dot in ['all',None]: continue # continue for all
          if str(dot) not in flows: break#break out if dot doesnt match
          else: continue # continue for all
        if tool not in list(toolFlow.keys()): toolFlow[tool] = set()
        toolFlow[tool].update(flows)
      for tool,flows in list(toolFlow.items()): out.append([cellName,tool,list(flows)])
  return out

def getQaArea(process):
  if process in ['1222','1274','1275','1276']: return '/nfs/pdx/disks/dcti_disk0036/work_x22a/template_de2/template_QA/runQaAreaScratch/p'+process
  elif process in ['1231']: return '/nfs/pdx/disks/wict_wd/p1231/runQaArea'
  else: raise IOError('Bad process: '+process)

def getQaLib(process):
  rfc = '/nfs/pdx/disks/wict_tools/releases/RF_COLLATERAL/qaLibs'
  process = process[-2:]
  if len(process) >= 2: return f'intel{process}qa',f'{rfc}/intel{process}qa'
  else: return False,False
  
def encode(string):
  return '<!logfile007!'+string+'>'

def decode(string):
  import re
  test = re.search(r'<!logfile007!(.*)>',string,flags=re.DOTALL)
  if test: return test.group(1).strip()
  else: return False

def readQaWaiver(libPath):
  import subprocess,re        
  cmd = 'ls '+libPath+'/*/qaWaiver/text.txt'   ## get all the cell/qaConfig/text.txt
  test = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
  data = test.communicate()[0].decode()
  if data.strip() == '': return ''
  key=False; out=['cellName,tool,flow,rule,count']
  for ff in data.split():  ## read each file and extract cell,tool,flow,waivers
    cellName = list(filter(str.strip,ff.split('/')))[-3]; toolFlow = {}; 
    with open(ff) as fin:
      for line in fin:
        line = line.strip().split('#')[0]
        if line == '': continue 
        line = re.split(r'[^\w/]+',line);  ## by definition we have tool:flow1,flow2
        line = list(filter(str.strip,line))
        if len(line) != 2: continue
        tool,flow = line
        if tool in ['icv','cal']: key = tool+'#'+flow; toolFlow[key] = []; continue
        if key: toolFlow[key].append(line)
      for tool,waivers in list(toolFlow.items()):
        for waiver in waivers: out.append(','.join([cellName]+tool.split('#')+waiver))  
  return '\n'.join(out)

def runStatus(dirQa,tool,cellName,flow):
  import os, subprocess
  logDir = os.getenv('PDSLOGS') or False
  if logDir: #PDS ICV
    logFiles = list(map(lambda suffix: [f'{logDir}/{cellName}.{flow}.{suffix}',os.path.exists(f'{logDir}/{cellName}.{flow}.{suffix}')], ['stats','iss.log.abort','iss.current','icvlvs.stats']))
    [subprocess.run(f'cp {logF} {dirQa}',shell=True) for logF,state in logFiles if state == True] # copy the available logs
    if logFiles[0][1] and [flow!='trclvs' or logFiles[3][1]]: status = 'SUCCESS\n' # for LVS we need stats$ and icvlvs.stats to exist
    else: status= '<font color="red">FAIL</font>\n'
  elif tool == 'icv': status = 'SUCCESS\n'
  else: #calibre so search for flow/drc.sum or flow/lvs.report
    logFiles = [os.path.exists(f'{dirQa}/{cellName}.{flow}/{ff}') for ff in ['drc.sum','lvs.report']]
    status = 'SUCCESS\n' if any(logFiles) else '<font color="red">FAIL</font>\n' 
  return status

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
