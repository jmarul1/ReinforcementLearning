#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

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
  finalLst = []
  for fk,qk,lk in [['Freq(GHz)','Q11','L11(nH)'],['Freq(GHz)','Q22','L22(nH)']]:
    ## get Qpeak, Lpeak, SRF, Fpeak
    srf,iiSrf = sparameter.getIndSRF(ref[fk],ref[qk])
    Qpeak,srf = (max(ref[qk][:iiSrf]),srf) if srf else (max(ref[qk]),ref[fk][-1])
    iiQpeak = ref[qk].index(Qpeak); Lpeak = ref[lk][iiQpeak]; Fpeak = ref[fk][iiQpeak]
    ## Get range if needed
    if args.range: args.range = getRange(args.range)
    lst = []; idxLst = []; 
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
      lst.append([ftest,errQ,errQperc,errL,qref,lref,qtest,ltest]); idxLst.append(index)
    finalLst.append(lst)
  lst1,lst2 = finalLst
  ## labels
  output = [fk+',Q11ErrAbs,Q11Err(%),L11Err(%),fQ11,fL11(nH),sQ11,sL11(nH),Q22ErrAbs,Q22Err(%),L22Err(%),fQ22,fL22(nH),sQ22,sL22(nH)']
  if all(finalLst):
    ## attach average or max
    average1 = (numpy.mean(numpy.array(lst1),axis=0)).tolist(); average2 = (numpy.mean(numpy.array(lst2),axis=0)).tolist()
    lst1.append(average1); lst2.append(average2)
    ## get output
    for ii,(line1,line2) in enumerate(zip(lst1,lst2)):
      line = map(lambda ff: numtools.numToStr(ff,3),line1+line2[1:])
      output.append(','.join(line))
  else: output.append('NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA ## BAD DATA')
  
  if __name__ == '__main__': print '\n'.join(output) ## print everything
  else: return output
  
if __name__ == '__main__':
  mainExe()

