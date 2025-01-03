############## Created by MM

class fit:
  def __init__(self,spFile,ward,optimizer,silent=False):
    import os,sys; from colors import paint
    self.cktElems = ['CC','LS','RS','LSK','RSK', 'COX', 'COX3', 'RSUB', 'RSUB3', 'K12']    
    self.initVals = [10  ,1   , 1  ,  1  ,  1  ,  100 ,  100  ,  1000 ,  1000  , 0.5]    
    self.study = os.path.basename(os.path.splitext(spFile)[0]); self.opt = optimizer
    ## Boundaries
    self.bounds = self.setBounds()
    ## Weigths and mode
    self.qw,self.lw,self.srfw = 0.334,0.333,0.333; 
    ## objective function
    def fun(cktVals):
      from . import computeAccuracy; import textutils
      self.writeCsvCkt(f'{ward}/{self.study}_cktplan.csv',cktVals)
      label = textutils.shorten(' '.join(f'{kk}={vv:.3f}' for kk,vv in zip(self.cktElems,cktVals)),100)
      scores = computeAccuracy(spFile,f'{ward}/{self.study}_cktplan.csv',sim='pymm') ##
      scores = scores[0]*self.qw+scores[1]*self.lw+scores[2]*self.srfw
      if not silent: print(f'{paint.red}Error at: {scores:.3f} - Iteration: {label}{paint.end}',end='\r',flush=True)
      else: print(f'{paint.darkgrey}{self.opt} Err {scores:.3f}{paint.end}',end='\r',file=sys.stderr, flush=True)
      return scores #Qd,Ld,srf
    self.fun = fun
    
  ## Boundaries
  def setBounds(self):
    capRng,indRng,resRng,k12Rng = [(0,5000),(0,10),(0,1e6),(0.01,0.99)]; bounds = []
    for ckt in self.cktElems:
      if   ckt.startswith('C'): bounds.append(capRng)
      elif ckt.startswith('R'): bounds.append(resRng)
      elif ckt.startswith('L'): bounds.append(indRng)
      elif ckt.startswith('K'): bounds.append(k12Rng)        
    return bounds

  ## Write csv with cktVals
  def writeCsvCkt(self,outPath,cktVals,label=None):
    with open(outPath ,'wb') as fout: # write csv file to send to cost function
      if label:
        label = f'#{label}\n'.encode()
        fout.write(label)
      for key,value in zip(self.cktElems,cktVals): fout.write('{},{}\n'.format(key,value).encode())
    
