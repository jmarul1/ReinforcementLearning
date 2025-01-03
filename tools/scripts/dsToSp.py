#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
 
def checkDir(path):
  if not os.path.isdir(path): raise IOError('Out directory does not exist: '+path)
  else: return path

def checkIn(path):
  if not os.path.isfile(path): raise argparse.ArgumentTypeError('File does not exist: '+path)
  if os.path.splitext(path)[1] != '.ds': raise argparse.ArgumentTypeError('File is not a momentum data set: '+path) 
  if not re.search(r'_a.ds$',path,flags=re.I): print('Skipping non *_a.ds file: '+path); return False; 
  return os.path.relpath(path)

def getPorts(ffile):
  ports = 'n'
  with open(ffile) as fin:
    for line in fin:
      test = re.search(r'^\s*!\s*(\d+)\s*port',line,flags=re.I)
      if test: ports = test.group(1); break
  return ports

## Argument Parsing
import sys, re, argparse, os, subprocess
tempParser = argparse.ArgumentParser(add_help=False)
tempParser.add_argument('-type', dest='type', default='touchstone', choices = ['touchstone','citifile'], help='output file format')
tempArgs = tempParser.parse_known_args()[0]; reqPorts = True if tempArgs.type == 'touchstone' else False
argparser = argparse.ArgumentParser(parents=[tempParser],description='Converts dataset momentum files to sparameter')
argparser.add_argument(dest='inputFile', nargs='+', type=checkIn, help='file(s) ending with (_a).ds')
#argparser.add_argument('-ports', dest='ports', type=int, required=reqPorts, help='number of ports')
argparser.add_argument('-complex', dest='complex', default='RI', choices = ['RI','MA','DB'], help='complex data format')
argparser.add_argument('-outdir', dest='outdir', default='.', type=checkDir, help='Out dir, defaults to current')
args = argparser.parse_args()
## Setup environment
os.environ['HPEESOF_DIR'] = '/nfs/pdx/disks/x74.cad.1/cad_root/ads/2015_01'
#os.environ['HPEESOF_DIR'] = '/nfs/pdx/disks/wict_tools/eda/keysight/ads/2019R1P0/unix/'
os.environ['LD_LIBRARY_PATH'] = os.environ['HPEESOF_DIR']+'/lib/linux_x86_64'
os.environ['PATH'] = os.environ['HPEESOF_DIR']+'/bin'+':'+os.environ['PATH']
## Main Begins
for ff in [ii for ii in args.inputFile if ii]:
  outFile = args.outdir+'/'+re.sub(r'_a$','',os.path.splitext(os.path.basename(ff))[0],flags=re.I)
  ext = '.snp' if args.type == 'touchstone' else '.citi'
  cmd = 'ds_export '+outFile+ext+' -d '+ff+' -t '+args.type+' -f '+args.complex
  subprocess.call(cmd, shell=True)
  if args.type == 'touchstone': 
    os.rename(outFile+ext,outFile+'.s'+getPorts(outFile+ext)+'p')
