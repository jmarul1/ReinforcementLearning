def sortMetalVia(lst,prefixExp=''):
  import re; 
  effPrExp = prefixExp if prefixExp!='' else '^'
  lst = [ff for ff in lst if not(re.search(r'tfr?',ff,flags=re.I))] # remove non needed layers
  bumpLst = sorted([ff for ff in lst if re.search(r''+effPrExp+'c4|sib|siv|mlb|mlv',ff,flags=re.I)],reverse=True); # separate the bumps
  substrates = sorted([ff for ff in lst if re.search(r''+effPrExp+'epi|substrate',ff,flags=re.I)]);  # separate the substrates
  indMV = [ff for ff in lst if re.search(r'^(g|t|vm|b)',ff,flags=re.I)]; # extract the inductor top layers
  lst = [ff for ff in lst if ff not in bumpLst and ff not in substrates and ff not in indMV] # work with only metals for sorting
  lst = [ff for ff in lst if ff not in ['ctp']]
  newLst = sorted(lst,key=lambda ff: int(re.search(r''+prefixExp+'\D*?(\d+)',ff).group(1)))
  metalViaLst = [ff for ff in newLst if re.search(r''+effPrExp+'(m|v)',ff)]
  # sort inductor metal/vias and move the gmz/vmz first if it exists
  topLst = sorted(indMV);
  for tt in ['gmz','vmz']: 
    if tt in indMV: topLst.remove(tt); topLst = [tt]+topLst
#  print((substrates,metalViaLst,topLst,bumpLst))
  return substrates+metalViaLst+topLst+bumpLst

def sortOxides(lst,prefixExp=''):
  import re
  effPrExp = prefixExp if prefixExp!='' else '^'  
  oxLst = []
  for var in ['g','su','ep']: oxLst += [ff for ff in lst if re.search(r''+effPrExp+var,ff,flags=re.I)]
  tmpLst = [ff for ff in lst if re.search(r''+effPrExp+'(o)',ff,flags=re.I)]
  oxLst += sorted(tmpLst,key=lambda ff: int(re.search(r''+prefixExp+'\D*?(\d+)',ff).group(1)))  
  oxLst += [ff for ff in lst if re.search(r''+effPrExp+'c|si',ff,flags=re.I)]
  return oxLst

def getTechFile(path=False):
  import subprocess, re, os
# use path if given
  if path:
    cmd = subprocess.Popen("find "+path+" -name '*.layermap'", shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE); layermap = cmd.communicate()[0].strip();    
    cmd = subprocess.Popen("find "+path+" -name '*.objectmap'",shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE); objectmap = cmd.communicate()[0].strip();    
    return layermap,objectmap
# some default
  if os.getenv('ISSRUNSETS') and os.getenv('PROCESS_NAME'):
    try:
      layermap = os.getenv('ISSRUNSETS')+'/PXL/'+os.getenv('DR_PROCESSNAME')+'/p'+os.getenv('DR_PROCESSNAME')+'.map'
      if os.getenv("PROCESS_NAME") == '1231': layermap = os.getenv('ISSRUNSETS')+'/Calibre/includes/p1231_map.txt'
    except TypeError: layermap = ''
    objectmap = ''
## test for the techfile instead
  test = re.search(r'(\d+)',os.getenv('PROJECT')) or re.search(r'(\d+)',os.getenv('PROCESS_NAME'))
  if test:
    techlib = 'intel'+test.group(1)[-2:]+'tech'
    cmd = 'libs '+techlib
    path = subprocess.run(cmd,shell=True,capture_output=True,text=True)    
    path = path.stdout.split('\n')[0].split()
    if len(path) > 1 and os.path.isdir(path[1]): 
      path = path[1]
      layermap = path+'/'+techlib+'.layermap'
      objectmap = path+'/'+techlib+'.objectmap'
  return layermap,objectmap
