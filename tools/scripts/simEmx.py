#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> simMomFiles.py -h
##############################################################################

def getPorts(ffile):
  ports = 'n'
  with open(ffile) as fin:
    for line in fin:
      test = re.search(r'^Ports:(.*)',line,flags=re.I)
      if test: ports = len(re.findall(r'\S+', test.group(1))); break
  return str(ports)

def runSimulation(cmd,cell,outF,logF,skew,batch=False):
  start = time.time()
  test = nb.submitV2(cmd,interactive=True) if batch else subprocess.run(cmd, shell=True) 
  duration = (time.time() - start)/60.0
  if test.returncode == 0: snp = f'{cell}.s{getPorts(logF)}p'; os.remove(logF); os.rename(outF,snp); print(f'#FINISHED: ({duration:>6.2f} minutes), SUCCESS, {skew},\t{snp}')
  else: print(f'#FINISHED: ({duration:>6.2f} minutes),   FAIL, {skew},\t{cell}')
  return test
    
## Argument Parsing ##########################################################################
import shutil, re, subprocess, argparse, time, numtools, os , sys, sparameter, netbatch as nb, os, multiprocessing; from colors import paint
procFile = subprocess.run('find $INTEL_PDK/models/integrand/emstack/uncomp -name \'*tttt.proc\'',shell=True,capture_output=True,text=True).stdout.split()[0]
argparser = argparse.ArgumentParser(description='Simulates a GDS using ports on the labels, ports go to the closest edge',formatter_class=argparse.ArgumentDefaultsHelpFormatter)
argparser.add_argument(dest='gds', nargs='+', help='GDS file(s)')
argparser.add_argument('-freq', dest='freq', default=["0.5M","50G"], nargs=2, help='Specify Frequency Range as: minimum maximum')
argparser.add_argument('-process', dest='process', default=[procFile], nargs='+', help='Process file(s)')
argparser.add_argument('-temperature, -t', dest='temp', type = float, default = '25', help='Temperature')
argparser.add_argument('-batch', dest='batch', nargs='?', const=1, type = int, help='Uses the batch to run jobs in parallel by value given, value defaults to 1 if nothing given')
argparser.add_argument('-key', dest='key', default='Intel', help=argparse.SUPPRESS)
argparser.add_argument('-accuracy', dest='acc', default='0.2', type=float, help=argparse.SUPPRESS)
args = argparser.parse_args()
## Main Begins ##############################################################################
pool = multiprocessing.Pool(args.batch) if args.batch else False
args.freq = list(map(lambda ff: numtools.getScaleNum(ff), args.freq)); jobs = {} #capProc = ' --definitions-file=/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/research/emxVsMom/cap.proc'
## submit the jobs either locally or to the batch
for gds in args.gds:
  for process in args.process:
    ## Get the name and skew
    cell=os.path.basename(os.path.splitext(gds)[0]); outF = f'{cell}.snp'; logF = f'{cell}.log'; skew = os.path.basename(os.path.splitext(process)[0])
    ## prepare the comand
    cmd = f'emx {gds} {cell} {process} --sweep {args.freq[0]:.3e} {args.freq[1]:.3e} --key {args.key} -f touchstone -s {outF} --temperature={args.temp} --log-file={logF} --3d=* -e {args.acc} -t {args.acc}'
    ## run simulations  
    if pool: print(f'Netbatch run: {gds}\n{paint.lightgrey}{cmd}{paint.reset}'); jobs[f'{cell} {skew}'] = pool.apply_async(runSimulation,(cmd,cell,outF,logF,skew),{'batch':args.batch}); #remember that apply_async returns a result object and not the output of the function
    else:    print(f'Local run {gds}\n{paint.lightgrey}{cmd}{paint.reset}');     jobs[f'{cell} {skew}'] = runSimulation(cmd,cell,outF,logF,skew) 
## wait for the jobs to complete
if pool:
  for jobName,jobP in jobs.items(): jobP.get(); ## wait for the jobs
  pool.terminate()
