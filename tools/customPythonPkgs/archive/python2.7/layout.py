def sortMetalVia(lst,prefixExp=''):
  import re; 
  effPrExp = prefixExp if prefixExp!='' else '^'
  lst = filter(lambda ff: not(re.search(r'tfr?',ff,flags=re.I)),lst) # remove non needed layers
  bumpLst = sorted(filter(lambda ff: re.search(r''+effPrExp+'c4|sib|siv|mlb|mlv',ff,flags=re.I),lst),reverse=True); # separate the bumps
  substrates = sorted(filter(lambda ff: re.search(r''+effPrExp+'epi|substrate',ff,flags=re.I),lst));  # separate the substrates
  indMV = filter(lambda ff: re.search(r'^(g|t|vm|b)',ff,flags=re.I),lst); # extract the inductor top layers
  lst = filter(lambda ff: ff not in bumpLst and ff not in substrates and ff not in indMV, lst) # work with only metals for sorting
  newLst = sorted(lst,key=lambda ff: int(re.search(r''+prefixExp+'\D*?(\d+)',ff).group(1)))
  metalViaLst = filter(lambda ff: re.search(r''+effPrExp+'(m|v)',ff),newLst)
  # sort inductor metal/vias and move the gmz/vmz first if it exists
  topLst = sorted(indMV);
  for tt in ['gmz','vmz']: 
    if tt in indMV: topLst.remove(tt); topLst = [tt]+topLst
  return substrates+metalViaLst+topLst+bumpLst

def sortOxides(lst,prefixExp=''):
  import re
  effPrExp = prefixExp if prefixExp!='' else '^'  
  oxLst = []
  for var in ['g','su','ep']: oxLst += filter(lambda ff: re.search(r''+effPrExp+var,ff,flags=re.I),lst)
  tmpLst = filter(lambda ff: re.search(r''+effPrExp+'(o)',ff,flags=re.I),lst)
  oxLst += sorted(tmpLst,key=lambda ff: int(re.search(r''+prefixExp+'\D*?(\d+)',ff).group(1)))  
  oxLst += filter(lambda ff: re.search(r''+effPrExp+'c|si',ff,flags=re.I),lst)
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
    layermap = os.getenv('ISSRUNSETS')+'/PXL/'+os.getenv('PROCESS_NAME')+'/p'+os.getenv('PROCESS_NAME')+'.map'
    if os.getenv("PROCESS_NAME") == '1231': layermap = os.getenv('ISSRUNSETS')+'/Calibre/includes/p1231_map.txt'
    objectmap = ''
## test for the techfile instead
  test = re.search(r'(\d+)',os.getenv('PROJECT'))
  if test:
    techlib = 'intel'+test.group(1)[-2:]+'tech'
    cmd = '/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/getCells.py -p '+techlib
    test = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE)    
    path = test.communicate()[0]
    if path: 
      path = path.split()[0]
      layermap = path+'/'+techlib+'.layermap'
      objectmap = path+'/'+techlib+'.objectmap'
  return layermap,objectmap
