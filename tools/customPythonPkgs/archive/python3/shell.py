def rmFile(path,isDir=''): #takes wild cards
  import re, os, subprocess
  if re.search(r'\*',path): path = path.replace('*','.*?') 
  dirName = os.path.dirname(os.path.realpath(path))
  files = os.listdir(dirName)
  files = filter(lambda ff: re.search(r'^'+path+'$',ff), files)
  for ff in files: 
    ff = dirName+'/'+ff
    if os.path.exists(ff): subprocess.call('rm -f'+isDir+' '+ff,shell=True)
