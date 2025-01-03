def getNegZeroInt(lst):
  import sys, numpy
  maxIndex = False;
  if len(lst) < 2: return maxFreq     
  for ii in range(1,len(lst)):
    if lst[ii-1] >= 0.0 and lst[ii] < 0.0: maxIndex = ii-1; break
  return maxIndex

def combElemInLst(lst): #[1,2] --> [[1,1],[1,2],[2,1],[2,2]]
  newLst = []
  for ii in lst:
    for jj in lst:
      newLst.append([ii,jj])
  return newLst   

def addPoints(lst1,lst2): return lst1[0]+lst2[0],lst1[1]+lst2[1]
