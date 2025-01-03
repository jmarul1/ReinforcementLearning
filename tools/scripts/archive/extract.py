#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2014, Intel Corporation.  All rights reserved.               #
#                                                                            #
# This is the property of Intel Corporation and may only be utilized         #
# pursuant to a written Restricted Use Nondisclosure Agreement               #
# with Intel Corporation.  It may not be used, reproduced, or                #
# disclosed to others except in accordance with the terms and                #
# conditions of such agreement.                                              #
#                                                                            #
# All products, processes, computer systems, dates, and figures              #
# specified are preliminary based on current expectations, and are           #
# subject to change without notice.                                          #
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> extract.py -h 
##############################################################################
import sys, argparse, os, re, subprocess as sb, datetime
#xtractOverride = '/nfs/site/disks/icf_fdk_scalablerf001/jmarulan/fdk73/dot'+os.getenv('FDK_DOTPROC')+'/MFC/runsetAndExt/extOverrides'
skews = ['tttt','prcf','prcs','pcff','pcss'] if os.getenv('FDK_DOTPROC') == '3' else ['tttt','pifs','pisf','rifs','risf']
##############################################################################
# Argument Parsing
##############################################################################
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
argparser = argparse.ArgumentParser(description='Uses xtract to run extraction')
argparser.add_argument(dest='gdsFiles', nargs='+', help='GDS file(s)')
argparser.add_argument('-cdl', dest='cdl', nargs='+', help='CDL file(s) in the same order as GDS file(s)')
argparser.add_argument('-flow', dest='flow', choices = ['icv_starrcxt','calibre_starrcxt','calibre_qrcxt','pvs_qrcxt'], help='flow to use')
argparser.add_argument('-temp', dest='temp', default = 25, type=int, help='Temperature')
argparser.add_argument('-skew', dest='skew', default = 'tttt', choices = skews, help='Skew')
argparser.add_argument('-cleanup', dest='clean',action='store_true',help='Just get the spf and erase the working dir')
argparser.add_argument('-dirty', dest='dirty',default='',action='store_const',const=' -dirtylayout -annotate',help=argparse.SUPPRESS)
argparser.add_argument('-mimcap', dest='mimcap',default='',action='store_const',const=' -noredn_pg -noredn -extract_pg',help=argparse.SUPPRESS)
args = argparser.parse_args()
## Check Arguments
if args.cdl and (len(args.cdl) != len(args.gdsFiles)): raise argparse.ArgumentTypeError('CDF files count is not equal to GDS files count: GDS='+str(len(args.gdsFiles))+' != CDL='+str(len(args.cdl)))

##############################################################################
# Main Begins
##############################################################################
for cc,ff in enumerate(args.gdsFiles):
  if args.cdl:
    cdl = ' -cdl '+args.cdl[cc]#+' -nostdlvs'
#    if os.getenv('FDK_DOTPROC') == '6' and os.getenv('PROJECT')=='fdk73': os.environ['FDK_XTRACT_OVRRD']=xtractOverride 
  else:
    cdl = ' -layoutonly'; #os.environ['FDK_XTRACT_OVRRD']=xtractOverride   
  cellName = os.path.basename(os.path.splitext(ff)[0])
  flow = ' -flow '+args.flow if args.flow else '' 
  cmd = 'xtract '+cellName+' -gds '+ff+cdl+' -verbose -outdir . -skew '+args.skew+' -temp '+str(args.temp)+flow+args.dirty+args.mimcap
  print 'Running ',cmd
  job = sb.Popen(cmd,stdout=sb.PIPE,stderr=sb.PIPE,shell=True); 
  log = job.communicate()
  with open('last.log','wb') as fout:
    fout.write('STDOUT\n'+log[0]+'\nSTDERR\n'+log[1])
  if args.clean: sb.call("find "+cellName+" -name '*spf' | grep /"+str(args.temp)+"/ | xargs -i cp '{}' .",shell = True); sb.call('sleep 5 && rm -rf '+cellName+' &',shell=True)      
