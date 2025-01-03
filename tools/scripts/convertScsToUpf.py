#!/usr/intel/bin/python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def readCktFile(ff):
  import ride, ckt
  cktObj = ckt.read(ff,full=True)
  cktObj.rlck = ride.readSubCkt(ff)
  return cktObj

def convertUpfLines(lines,ports):
  import collections, numtools
  rrs = collections.OrderedDict(); lls = collections.OrderedDict(); ccs = collections.OrderedDict(); kks = collections.OrderedDict(); output=[]; maxNumber=0
  # get the lines

  for line in lines:
    test = re.findall(r'\S+',line)
    if len(test) != 4: continue
    name,node1,node2,value = test
    if   re.search(r'^\s*r',name,flags=re.I): rrs[name] = 'Rinstance#'+str(len(rrs)+1)+' type="linR" node1='+node1+' node2='+node2+' value='+value
    elif re.search(r'^\s*l',name,flags=re.I): lls[name] = 'Linstance#'+str(len(lls)+1)+' type="linL" node1='+node1+' node2='+node2+' value='+value
    elif re.search(r'^\s*c',name,flags=re.I): ccs[name] = 'Cinstance#'+str(len(ccs)+1)+' type="linC" node1='+node1+' node2='+node2+' value='+value
    elif re.search(r'^\s*k',name,flags=re.I): kks[name] = ['Kinstance#'+str(len(kks)+1),node1,node2,value]
    maxNumber = max(map(lambda ff: int(ff) if numtools.isNumber(ff) else -1,[node1,node2,maxNumber]))
  # put the upf together
  for dt in [rrs,lls,ccs]: output += [line for name,line in dt.items()]
  for kk,value in kks.items():
    ind1 = '"Linstance#%d"'% (list(lls.keys()).index(kks[kk][1])+1); ind2 = '"Linstance#%d"'% (list(lls.keys()).index(kks[kk][2])+1);
    output.append(value[0]+' inductor1='+ind1+' inductor2='+ind2+' value='+value[3])
  # correct the numbers
  output,maxNumber = correctNumbers(output,maxNumber,ports)
  return output,maxNumber    

def correctNumbers(lines,maxNode,ports):
  import re
  newNode = maxNode
  for nn in range(1,len(ports)+1): 
    match = r'(node\d+=)'+str(nn)+r'\b'; flag=0
    for ll in lines: flag += (1 if re.search(match,ll) else 0)
    if flag > 0: newNode+=1
    lines = [re.sub(match,r'\g<1>'+str(newNode),ll) for ll in lines[:]] # replace all nodes with the highest number
    lines = [re.sub(r'(node\d+=)'+ports[nn-1]+r'\b',r'\g<1>'+str(nn),ll) for ll in lines[:]]
  return lines, newNode
       
##############################################################################
# Argument Parsing
##############################################################################
import sys, os, tempfile, subprocess, re,shutil
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import argparse, ride, ckt
argparser = argparse.ArgumentParser(description='Converts a subckt in scs/hsp into upf format')
argparser.add_argument(dest='cktFiles', nargs='+', help='Spice file(s)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

for ff in args.cktFiles:
  if not os.path.isfile(ff): raiseIOError('Given circuit file does not exists:'+ff)   ## Check files exist
  cktObj = readCktFile(ff)
  lines,maxNodes = convertUpfLines(cktObj.rlck, cktObj.ports)
  print ('model="'+cktObj.modelName+'" numPorts='+str(len(cktObj.ports))+' numIntNodes='+str(maxNodes-len(cktObj.ports))+' version=1.0')
  print ('** INDUCTOR '+cktObj.modelName+' '+(' '.join(cktObj.ports)))
  print ('\n'.join(lines))
  print ('end')
