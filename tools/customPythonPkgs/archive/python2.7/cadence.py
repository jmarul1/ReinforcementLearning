def flattenCds(cdsFile,cds={}):
  import os, re, env
  cdsFile = env.getPath(cdsFile)
  if not os.path.isfile(cdsFile): return cds
  with open(cdsFile) as fin:
    for line in fin:
      line = line.split('#')[0].strip()
      if re.search(r'^$',line): continue
      line = re.findall(r'\S+',line); 
      if re.search(r'^include',line[0],flags=re.I): cds = flattenCds(line[1],cds);
      elif re.search(r'^define',line[0],flags=re.I): cds[line[1]] = env.getPath(line[2])
      elif re.search(r'^undefine',line[0],flags=re.I) and line[1] in cds.keys(): del cds[line[1]]
      else: continue
  return cds

class readCds():
  def __init__(self,cdsFile):
    self.cds = flattenCds(cdsFile)
    self.file = cdsFile
    
  def addLibToCds(self,libTuple,force=False):
    import subprocess,os
    if libTuple[0] in self.cds.keys():
      if force and os.path.realpath(libTuple[1])!=os.path.realpath(self.cds[libTuple[0]]): 
        subprocess.call("echo '\nUNDEFINE "+libTuple[0]+"\nDEFINE "+' '.join(libTuple)+"\n' >> "+self.file,shell=True)
    else: subprocess.call("echo '\nDEFINE "+' '.join(libTuple)+"\n' >> "+self.file,shell=True)
    self.cds = flattenCds(self.file)
    return True

  def getLibCells(self,lib,expr=None):
    import re, os, sys
    if lib not in self.cds.keys(): sys.stderr.write('Lib does not exist in cdsdef: '+lib+'\n'); return []
    cells = os.listdir(self.cds[lib])
    cells = filter(lambda ff: os.path.isdir(self.cds[lib]+'/'+ff), cells)
    if expr:
      expr = expr.strip()
      cells = filter(lambda ff: re.search(r''+expr,ff,flags=re.I),cells)
      if not cells: sys.stderr.write('Cell expression "'+expr+'" not found in "'+lib+'"\n')
    return cells
  
  def getLibPath(self,lib):
    if lib not in self.cds.keys(): sys.stderr.write('Lib does not exist in cdsdef: '+lib+'\n'); return []
    return self.cds[lib]
