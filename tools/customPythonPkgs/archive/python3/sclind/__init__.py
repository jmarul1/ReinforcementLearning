from . import hr, lr, gan

class init():

  def __init__(self,csv=None,subs='hr'):
    import pandas as pd, re
    self.fk,self.qk,self.lk = 'Fd_full(GHz),Qd_full,Ld_full(nH)'.split(',')
    if csv: self.data = pd.read_csv(csv,comment='#')
    elif subs == 'hr': self.data = hr.data(); 
    elif subs == 'lr': self.data = lr.data()
    else: subs = self.data = gan.data()
    self.outKs = [list(filter(lambda ff: re.search(r'^'+test,ff), self.data.keys()))[0] for test in ['indType','n','w','s','x','y']]
    self.winner = pd.DataFrame()
#    self.data = self.data[self.data[self.lk]>0]; self.data=self.data[self.data[self.qk]>0]
    
  def closestNums(self,freq,ind,Q=None):
    import numpy, pandas as pd, numtools
    df = self.data[Q < self.data[self.qk]] if Q else self.data    
    lTol = fTol = 0; fA = 1; lA = 0.1
    while fTol <= fA and lTol <= lA:
      tempF = (df[self.fk]-freq).abs()<fTol
      if not any(tempF): fTol+=0.1; continue #if not one is found
      tempL = (df[self.lk]-ind).abs()<lTol
      if not any(tempL): lTol+=0.05; continue #if not one is found
      winner = df[tempF&tempL]
      if fTol >= fA: return ('Try a Frequency < '+str(fA)+'G: F='+numtools.numToStr(freq,2)+'GHz')
      if lTol >= lA: return ('Try an Inductance < '+str(lA)+'nH: L='+numtools.numToStr(ind,2)+'nH')
      if len(winner) >= 1: self.winner = winner; break
      fTol+=0.1; lTol+=0.05 #   print(fTol,lTol) # somebody has to increase no common ground
    # sort f,l,q closest to f, then to L, then max to min Q
    indeces = pd.concat([(self.winner[self.fk]-freq).abs(),(self.winner[self.lk]-ind).abs(),self.winner[self.qk]],axis=1)
    indeces = indeces.sort_values([self.fk,self.lk,self.qk],axis=0,ascending=(True,True,False))
    self.winner = self.winner.reindex(indeces.index)
    return 'SUCCESS'

  def getWinnerDims(self,length):
    import numtools, re
    if self.winner.empty: return ''
    outLst = []
    for index in range(length):
      if index >= len(self.winner): break
      outputs = [numtools.numToStr(self.winner[kk].values[index],0) for kk in self.outKs]
      outStr = outputs[0]+'_'+outputs[1]+'n_'+outputs[2]+'w_'+outputs[3]+'s_'+outputs[4]+'x_'+outputs[5]+'y'
      f,l,q = list(map(lambda kk: numtools.numToStr(self.winner[kk].values[index],3),[self.fk,self.lk,self.qk]))
      outLst.append('L='+l+'(nH) '+'Q='+q+' @ '+f+'GHz : ' + outStr)
    return outLst

  def plotBest(self,length):
    import plotUtils
    if self.winner.empty: return False
    outLst = self.getWinnerDims(length)
    [figs,layout] = plotUtils.layoutPlt(2,grW=7,grH=7); 
    for outStr,(ii,inductor) in zip(outLst,self.winner[self.outKs].iterrows()): 
      label = outStr.split(':')[1].strip(); test = self.data.copy();
      for jj in range(len(inductor)): test = test[test[inductor.index[jj]]==inductor.iloc[jj]];
      for pp,yKey in enumerate([self.qk,self.lk]): layout[pp].plot(test[self.fk],test[yKey],label=label)
    for ll in layout:
      ll.set_ylim(0,ll.get_ylim()[1]); ll.legend(loc='best'); ll.grid(True,which='both')
      ll.set_ylabel(plotUtils.getPltKeys(yKey)[1]);  ll.set_xlabel('Frequency(GHz)');   
    for iiFig in figs: iiFig.tight_layout()
    return figs,layout
