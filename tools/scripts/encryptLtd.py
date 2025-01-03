#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess
argparser = argparse.ArgumentParser(description='Encrypt the ltd files')
argparser.add_argument(dest='ltd', nargs='+', help='.ltd file(s)')
argparser.add_argument('-psw', dest='psw', required=True, help='password to encrypt')
argparser.add_argument('-decrypt', dest='dcr', action='store_true', help='password to decrypt')
argparser.add_argument('-nosuffix', dest='nsuf', action='store_true', help='do not rename file')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))

## Setup environment
os.environ['HPEESOF_DIR'] = '/nfs/pdx/disks/wict_tools/eda/keysight/ads/2019R1P0/unix'
os.environ['PATH'] = os.environ['HPEESOF_DIR']+'/bin'+':'+os.environ['PATH']

for ff in set(args.ltd):
  name,ext = os.path.splitext(ff)
  if args.dcr:
      out = os.path.basename(name)+'_dencrypted.ltd'
      cmd = '$HPEESOF_DIR/bin/rfdeMomWrapper -T --decrypt='+args.psw+' --out='+out+' '+ff
  else:
    out = (os.path.basename(name)+'.ltd') if args.nsuf else (os.path.basename(name)+'_encrypted.ltd')
    cmd = '$HPEESOF_DIR/bin/rfdeMomWrapper -T --encrypt='+args.psw+' --out='+out+' '+ff    
  test = subprocess.Popen(cmd,shell=True)
  test.communicate()
  #print cmd
