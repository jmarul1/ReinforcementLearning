#!/usr/bin/env python3.7.4

def getItp(xL,xU,yL,yU,xvalue): 
  if abs(xU - xL) < 1e-15: return (yU + yL)/2
  return yL + (xvalue-xL)*(yU - yL)/(xU - xL)

def getRange(freqR):
  if len(freqR) == 1: return -1.0,freqR[0]
  elif len(freqR) == 2 and freqR[0] < freqR[1]: return freqR
  else: raise IOError('Bad Range for frequency\n')
  
def mainExe(argLst=None):
  ##############################################################################
  # Argument Parsing
  ##############################################################################
  import argparse, os, sys, re, csv
  sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
  import csvUtils, numtools, numpy, sparameter
  argparser = argparse.ArgumentParser(description='Compare two IND csvs for Qdiff/Ldiff as ref.csv,test.csv')
  argparser.add_argument(dest='ff', nargs=2, help='Two csv files; Arg1 is the Reference')
  argparser.add_argument('-ftol',dest='ftol',default=0.5,type=float,help='Tolerance to match points between csvs')
  argparser.add_argument('-range',dest='range',nargs='+',type=float,help='Lower/Upper Limit or Upper Limit')
  argparser.add_argument('-qtol',dest='qtol',type=float,default=0.1,help='qtol as %%value (0.1 means 10%%) DefValue=10%%')
  argparser.add_argument('-ltol',dest='ltol',type=float,default=0.05,help='ltol as %%value (0.05 means 5%%) DefValue=5%%')
  args = argparser.parse_args(argLst)
  ##############################################################################
  # Main Begins
  ##############################################################################
  ## get values
  ref,test = csvUtils.dFrame(args.ff[0],text=False), csvUtils.dFrame(args.ff[1],text=False);
  fk,qk,lk = ('Freq(GHz)','Qdiff','Ldiff(nH)')
  ## get Qpeak, Lpeak, SRF, Fpeak
  srf,iiSrf = sparameter.getIndSRF(ref[fk],ref[qk])
  Qpeak,srf = (max(ref[qk][:iiSrf]),srf) if srf else (max(ref[qk]),ref[fk][-1])
  iiQpeak = ref[qk].index(Qpeak); Lpeak = ref[lk][iiQpeak]; Fpeak = ref[fk][iiQpeak]
  indChars = [Qpeak,Lpeak,srf]
  ## Get range if needed
  if args.range: args.range = getRange(args.range)
  lst = []; idxLst = []; errQsta = []; errLsta = []
  for ll,(ftest,qtest,ltest) in enumerate(zip(test[fk],test[qk],test[lk])):
    ## find frequency in the reference
    index = numtools.closestNum(ref[fk],ftest,args.ftol);
    if type(index) != int: continue
    fref,qref,lref = ref[fk][index],ref[qk][index],ref[lk][index];
    if   ftest > fref: lIndx,uIndx = index,index+1
    elif ftest < fref: lIndx,uIndx = index-1,index
    else: lIndx,uIndx = index,index
    if lIndx < 0 or uIndx > len(ref[fk])-1: continue
    qref,lref = getItp(ref[fk][lIndx],ref[fk][uIndx],ref[qk][lIndx],ref[qk][uIndx],ftest),getItp(ref[fk][lIndx],ref[fk][uIndx],ref[lk][lIndx],ref[lk][uIndx],ftest)
    if (args.range and ftest > args.range[1]) or qref < 0: break
    if (args.range and ftest < args.range[0]): continue
    errQ = abs(qref - qtest); errL = abs(1*(lref - ltest)/lref);  errQperc = abs(1*(qref - qtest)/qref) ## absolute value for Q and % for Q,L
    errQsta.append(True if errQ < Qpeak*args.qtol else False)
    errLsta.append(True if (errL < args.ltol or ftest > srf*0.7) else False)
    lst.append([ftest,errQ,errQperc,errL,qref,lref,qtest,ltest]); idxLst.append(index)

  ## labels
  output = [fk+',QdErrAbs,QdErr(%),LdErr(%),emQd,emLd(nH),cktQd,cktLd(nH),emQdPeak,emLdPeak(nH),emSrf(GHz)']

  ## pass or fail
  if lst:
    ## attach average or max
    average = (numpy.mean(numpy.array(lst),axis=0)).tolist()
    lst.append(average)
    finalQ = 'PASS' if (average[1] < Qpeak*args.qtol/2 and all(errQsta) ) else 'FAIL'
    finalL = 'PASS' if (all(errLsta)) else 'FAIL'
    ## get output
    for ii,line in enumerate(lst):
      line = list(map(lambda ff: numtools.numToStr(ff,3),line+indChars))
      if ii==len(lst)-1: line[-1] += ' ## MEAN\n'+(','.join(['outcome',finalQ,finalL]))
      output.append(','.join(line))
  else: output.append('NA,NA,NA,NA,NA,NA,NA,NA,NA,NA ## BAD DATA\noutcome,FAIL,FAIL')
  
  if __name__ == '__main__': print ('\n'.join(output)) ## print everything
  else: return all([finalQ=='PASS',finalL=='PASS']),output
  
if __name__ == '__main__':
  mainExe()

