def listToSet(lst,case=True):
  import re
  if case: return list(set(lst))
  else:
    newLst = []
    for test in lst:
      if filter(lambda ff: re.search(r'^'+test+'$',ff,flags=re.I), newLst): pass
      else: newLst.append(test)
  return newLst     
