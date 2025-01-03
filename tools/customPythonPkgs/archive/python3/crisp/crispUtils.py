
## create the control crisp file
def createcntl(gdsObj,qcap,flFile,time,nb=''): return '''
CELL_NAME: '''+gdsObj[0]+'''
FORMAT_LAYOUT_INFILE: stream
LAYOUT: '''+gdsObj[0]+'''
SCALE_FACTOR: 1.0
ENGINE: CRISP5
PROCESS_FILE_QCAP: '''+qcap+'''
FLOATINGNET_FILE: '''+flFile+'''
EXTRACT_SIGNAL: '''+gdsObj[2]+'''\n;Window_signal: '''+gdsObj[2]+'''\n;SIZE_OF_WINDOW: 50
TIME_FOR_EXTRACTION: '''+str(time)+'''
TOTAL_CAP_ACCURACY: 0.05%@1fF
XCAP_ACCURACY: 0.05%@1fF
RENAME_TEXT_OPEN: 0\n;RENAME_TEXT_OPEN: 0 -> allows netlisting short and gets rid of "INTEL_*" float nets.
MIN_XCAP_PERCENT: 0\n'''+nb

#read the allNets.summary and return a list of tuples with netName,capVal
def readFile(netsFile,mfactor=1):
  import re, numtools, operator, numpy, os
  if not os.path.isfile(netsFile): return False 
  fid = open(netsFile); nets = {}; cNet = False;
  for line in fid: #read the nets & caps
    test = re.search(r'Report\s+for\s+Net\s+(\S+)',line,flags=re.I)
    if test: cNet = test.group(1); nets[cNet] = {}
    if cNet:
      test = re.search(r'(\S+)\s+\S+\s+(\S+?)\(',line.strip())
      if test and test.group(1)!=cNet and numtools.isNumber(test.group(2)): nets[cNet][test.group(1)] = float(test.group(2))/mfactor
  ## combine all of them
  avgNets = {}; fid.close()
  for net1,components in sorted(nets.items(),key=operator.itemgetter(0)):
    for net2,cap in components.items():
      if net1+'_to_'+net2 in avgNets.keys(): avgNets[net1+'_to_'+net2].append(cap) #append same order cap values
      elif net2+'_to_'+net1 in avgNets.keys(): avgNets[net2+'_to_'+net1].append(cap) #append same order cap values
      else: avgNets[net1+'_to_'+net2] = [cap] #initialize
  ## average
  netsCapsDt = {}
  for net,caps in sorted(avgNets.items(),key=operator.itemgetter(0)): netsCapsDt[net] = str(numpy.median(caps))
  return netsCapsDt

