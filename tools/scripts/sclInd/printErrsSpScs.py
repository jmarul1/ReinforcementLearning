#!/usr/bin/env python2.7

def getPairs(dir1,dir2):
  import os
  refs = filter(lambda ff: os.path.splitext(ff)[1] == '.csv', os.listdir(dir1))
  tests = filter(lambda ff: os.path.splitext(ff)[1] == '.csv', os.listdir(dir2))
  out = []
  for rr in refs: 
    if rr in tests: out.append([dir1+'/'+rr,dir2+'/'+rr])    
  return out
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, subprocess
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/scripts'))
import csvUtils, numtools, getIndParamCsv
argparser = argparse.ArgumentParser(description='Get the full errors for the two dirs')
argparser.add_argument(dest='ff', nargs=2, help='Two dirs: reference test')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
## find the pair in the two directories
inputs = getPairs(args.ff[0],args.ff[1])
## run for each
out = []; ave = []
for ii,line in enumerate(inputs):
#  if ii > 60 or ii < 50: continue
  print 'Executing '+line[0]+'---- '+str(ii);
## get the dimensions
  effName = os.path.basename(os.path.splitext(line[0])[0]).rstrip('_QL')
  dims,dimVals = getIndParamCsv.getParamDims(effName)
## get the errs
  cmd = ' '.join(['/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/cmpIndCsv.py -range 20 -- ',line[0],line[1]])
  test = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE)
  results = test.communicate()[0]
  results = filter(lambda ff: ff.strip(), results.split('\n'));  
  labels = results[0]; mean = results[-2]; status = results[-1].split(','); status = status[1:3]
  addons = ','.join(mean.split(',')[1:3]+status+[effName])
  outTmp = map(lambda ff: ','.join(dimVals+ff.split(','))+','+addons, results[1:])
  out += outTmp[:-2];
  ave.append(outTmp[-2].split('#')[0].strip()+','+status[0]+','+status[1]+','+effName)
## compile the erros for all freqs and average
mainOut = '\n'.join([dims+','+labels+',maxQdErr,maxLdErr,statusQd,statusLd,fName']+out)
averOut = '\n'.join([dims+','+labels+',statusQd,statusLd,fName']+ave)
## create all the lines for all frequencies in one file
with open('fullSpectrumErr.csv','wb') as fout: fout.write(mainOut)
## create the average
with open('AverageErr.csv','wb') as fout: fout.write(averOut)
exit(0)
