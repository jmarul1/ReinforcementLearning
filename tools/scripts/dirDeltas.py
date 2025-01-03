#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def sepFiles(root,files):
  import re
  newFiles = []
  for ff in files: 
    test = re.search(r'^'+root+'(.*)',ff)
    if test: newFiles.append(test.group(1).lstrip('/'))
  return root,newFiles
  
def getFiles(dirPath):
  import os
  if os.path.isdir(dirPath): root = os.path.realpath(dirPath)
  else: raise IOError('Bad dir: '+dirPath)
  files = []
  for ff in os.walk(root):
    files += map(lambda ii: ff[0]+'/'+ii, ff[2])
  files = list(set(files))
  return sepFiles(root, files)

def diffFile(path1,path2):
  import subprocess
  test = subprocess.Popen('diff '+path1+' '+path2,shell=True,stdout=subprocess.PIPE)
  result = test.communicate()
  if result[0].strip() != '': return result[0]
  else: return False
    
##############################################################################
# Argument Parsing
##############################################################################
import argparse,sys,os
argparser = argparse.ArgumentParser(description='Compares files and subfiles in two directories, SRC "New Files" is compared to New Production.\nReports:\n\tLinks in MAIN\n\tDifferences of SRC to NEW PRODUCTION\n\tMissing in NEW PRODUCTION', formatter_class=argparse.RawDescriptionHelpFormatter)
argparser.add_argument(dest='dirs', nargs=2, type=getFiles, help='directories SRC and PRODUCTION')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
#sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))

mainDir,testDir = args.dirs
missing = []; links = []; differs = []
for ff in mainDir[1]:
  mainFile = mainDir[0]+'/'+ff; testFile = testDir[0]+'/'+ff
  if os.path.islink(mainFile): links.append(ff); continue ## links in source ERROR
  if ff not in testDir[1]: missing.append(ff); continue   ## missing files in release ERROR
  if diffFile(mainFile,testFile): differs.append(ff);     ## difference in release ERROR
  
if missing: print '#### MISSING in PRODUCTION\n\t'+('\n\t'.join(missing))+'\n'
if links:   print '#### LINKS in MAIN LIB\n\t'+('\n\t'.join(links))+'\n'
if differs: print '#### Files that DIFFER in content\n\t'+('\n\t'.join(differs))+'\n'
