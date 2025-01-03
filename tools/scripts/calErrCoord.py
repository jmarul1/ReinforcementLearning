#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def getLogs(path):
  if os.path.isdir(path):
    for ff in os.listdir(path):
      if re.search('^out.rve$',ff): return (path+'/'+ff)
  else: return False

def decipher(fname):
  test = re.search(r'^cal.*?-(\w+)-(.*?)\.(?:gds|stm|oas)', fname)
  if test: return test.group(1),test.group(2)
  test = re.search(r'(\w+)\.(\w+(?:.ext)?)', os.path.basename(os.path.dirname(fname)))
  if test: return test.group(1),test.group(2)
  else: return False,False

def getErr(cell,log,focus):
  with open(log) as fin:
    fetchE = fetchP = units = False; dt = {}
    for line in fin:
      if not units:
        test = re.search(f'^\s*{cell}\s+(\d+)',line)
        if test: units = int(test.group(1))
        continue
      if not fetchP:
        if not fetchE:
          test = re.search(r'^(\d+) \d+ \d+',line)
          if test: # store from previous line and get number of errors
            maxErr = int(test.group(1)); 
            if maxErr > 0: 
              errName = re.search(r'^(\S+)',prev).group(1);
              if not focus: dt[errName] = []; fetchE = True;
              elif any(list(map(lambda ff: re.search(f'^{ff}$',errName),focus))): dt[errName] = []; fetchE = True;
          else: prev = line # continues after this
        else: # fetch errr count    
          test = re.search(r'^p (\d+) (\d+)',line) # save the box under the errName and compare the number to see if you reach the limit
          if test: nowErr = int(test.group(1)); vertices=int(test.group(2)); points = []; fetchP = True
      else: # fetch points
        test = re.search(r'^(\d+) (\d+)',line)
        if test: points.append([int(test.group(1)),int(test.group(2))])
        if len(points) == vertices: dt[errName].append(getBox(points,units)); fetchP = False
        if maxErr == nowErr: fetchE = False # reset
  return dt      

def getBox(points,units): 
  p1 = points[0]; p2 = points[np.argmax(list(map(lambda pp: scipy.spatial.distance.euclidean(p1,pp),points)))]; 
  box = f'{p1[0]/units}:{p1[1]/units} {p2[0]/units}:{p2[1]/units}'
  return box

def convertDtToLst(cell,dt):
  lines = []
  for errName,boxes in dt.items(): 
    lines.append(f'{cell},{errName},'+(';'.join(boxes)))
  return lines
      
## Argument Parsing ##########################################################
import argparse, os, sys, re, csv, numpy as np, csvUtils, scipy.spatial
argparser = argparse.ArgumentParser(description='Output in CSV coord with errors from Runs in Calibre')
argparser.add_argument(dest='logs', nargs='+', type=getLogs, help='log dir(s) to compute')
argparser.add_argument('-errors', dest='errors', nargs='+', help='only errors to get')
args = argparser.parse_args()
## Main Begins ###############################################################
args.logs = [log for log in args.logs if log]
print('cellName,drc,box')
errLst = []
for log in args.logs:
  cell,flow = decipher(log)
  errDt = getErr(cell,log,args.errors)
  errLst = convertDtToLst(cell,errDt)
  ##print csv
  if errLst: print('\n'.join(errLst))
