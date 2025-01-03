#!/usr/bin/env python

import nport,math
#import pylab
thruFile = 'C:\Users\jmarulan\Downloads\\thru.s2p'
openFile = 'C:\Users\jmarulan\Downloads\open.s2p'
shortFile = 'C:\Users\jmarulan\Downloads\short.s2p'
loadFile = 'C:\Users\jmarulan\Downloads\load.s2p'

thruSp,openSp,shortSp,loadSp = map(lambda ff: nport.touchstone.read(ff),[thruFile,openFile,shortFile,loadFile])
thruZ,openY,shortZ,loadZ = (thruSp.convert('Z'),openSp.convert('Y'),shortSp.convert('Z'),loadSp.convert('Z'))
#import pdb; test = r'C:\Users\jmarulan\Downloads\b89indm10l0p28n_lowQ.s2p'; test = nport.touchstone.read(test); 
#pdb.set_trace()

def strList(nportM):
	result=[]
	for ff,entry in enumerate(nportM):
		line1 = line2 = ''
		for row in entry: 
			line1 += ','.join([str(jj.imag)+','+str(jj.real) for jj in row])+','
			line2+= ','.join([str(jj.imag/(2*math.pi*nportM.freqs[ff]))+','+str(jj.real) for jj in row])+','
		fLine = line1+line2
		result.append(fLine)
	return result  	

for fName,paramM in zip(('\\thruZ','\openY','\shortZ','\loadZ'),(thruZ,openY,shortZ,loadZ)): 
	paramResult = strList(paramM)	
	results='FREQ,im11,re11,im12,re12,im21,re21,im22,re22,C11,R11,C12,R12,C21,R21,C22,R22\n' if fName == '\openY' else 'FREQ,im11,re11,im12,re12,im21,re21,im22,re22,L11,R11,L12,R12,L21,R21,L22,R22\n'
	for ff,freq in enumerate(paramM.freqs):	results += ','.join([str(freq),paramResult[ff]]) + '\n'
	with open('C:\Users\jmarulan\Downloads'+fName+'.csv','wb') as fout: fout.write(results)
	
	
