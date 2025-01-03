
## Read the boundary limits
def readBndLimits(logFile,numExp):
  import re; fetch=False; bnds = {}
  with open(logFile) as fidIn:
    for line in fidIn:
      if re.search(r'^\s*$',line): continue # skip comments in ckt file or blank lines
      if re.search(r'^\s*trust_marquardt',line): bnds = {}; fetch=True
      test = re.search(r'^\s*(\w+)(.*range.*)boundary',line,flags=re.I)
      if fetch and test:
        test = re.search(r'^\s*(\w+)(.*range.*)boundary',line,flags=re.I)
        if test:
          temp = filter(lambda ff: ff.strip() != '', re.findall(numExp,test.group(2)))
          if len(temp) == 3 and not(re.search(r'^K',test.group(1).upper())): bnds[test.group(1).upper()] = temp
  return bnds

## Update the circuit file
def readSubCkt(subcktFile):
  import re, numtools
  result = []; params = {}
  with open(subcktFile) as fidIn:
    for line in fidIn:
      if re.search(r'^\s*\*|^\s*$|^\s*//',line): continue # skip comments in ckt file or blank lines
      line = line.strip(); line = line.split('//')[0]
      if re.search(r'^.subckt',line): continue
      test = re.search(r'^\s*.param\S*\s+(\S+?)\s*=\s*(\S+)',line)
      if test: params[test.group(1)] = test.group(2); continue
      args = line.split()
      if len(args) != 4: continue
      if not numtools.isNumber(args[-1]): args[-1] = params[args[-1]]
      if not re.search(r'^[kK]',args[0]): 
        args = [args[0]]+list(map(lambda ff: str.lstrip(ff,'n') if re.search(r'n\d',ff) else ff,args[1:3]))+[args[-1]]
      result.append('\t'.join(args))
  return result

## Get the new range
def computNewRange(bnds): #limitReach,lower,upper
  import numtools
  bnds = map(float,bnds) 
  test = numtools.closestNum(bnds[1:],bnds[0],1e-10)
  if test != 'NOT': 
    if test == 0: bnds[test+1] /= 10; #decrease by 10 (lower and upper) 
    else: bnds[test+1] *= 10 #increase by 10
  return map(lambda ff:numtools.numToStr(ff,precision=2,exp=True),bnds[1:])
