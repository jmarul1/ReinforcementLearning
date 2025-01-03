def getPath(pathStr):
  '''Return the realpath supporting env variables'''
  import re, os, sys
  def repl(var): return os.getenv(var.group(1))
  truePath = re.sub('\${?(\w+)}?',repl,pathStr)
  #if not os.path.exists(truePath): sys.stderr.write('Path does not exist in cdsdef: '+pathStr+'\n')
  return truePath
