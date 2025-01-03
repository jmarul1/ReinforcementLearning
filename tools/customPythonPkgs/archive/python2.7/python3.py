def move():
  import sys, os
  ## all we need to do is remove the directory with mine
  test = os.path.normpath('/nfs/pdx/home/jmarulan/work_area/utils/environment/myPython/lib/python')
  for ii,path in enumerate(sys.path):
    if os.path.normpath(path) == test: sys.path.pop(ii)
  sys.path.append('/nfs/pdx/disks/wict_tools/eda/opensource/python/customPkgs')
  sys.path.append('/nfs/pdx/disks/wict_tools/eda/opensource/python/venv/lib/python3.7/site-packages')

  
