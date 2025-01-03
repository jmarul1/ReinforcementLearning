#!/usr/bin/env python

import python3; python3.move()
import sympy as sym
import numpy
CC=10*1e-15
LS=0.5*1e-9
RS=1.5
LSK=1.0*1e-9
RSK=1.0
COX=100*1e-15
COX3=100*1e-15
RSUB=1000
RSUB3=1000
K12=0.2

print('Freq(GHz),Qdiff,Ldiff(nH),Qse,Lse(nH)')
for ww in numpy.arange(1,50,1):
  w = 2*3.1416*ww*1e9
  zc = 1/(w*CC*1j)
  zs = w*LS*1j + RS#*(RSK+w*LSK*1j)/(RS+RSK+w*LSK*1j)
  zm = w*K12*LS*1j
  zox = -1j/(w*COX)+RSUB
  zox3 = -1j/(w*COX3)+RSUB3
  Im1 = 1/(zox*(zm+zs)/(zm+zs+zox3)+zs+zm)
  y11 = y22 = 1/zc + 1/zox     + Im1
  y12 = y21 =-1/zc - 1/(zm+zs) + Im1
  Zd = 4/(y11-y12-y21+y22)
  Zse = 2/(y11+y22)
  print(','.join(map(str,[ww,Zd.imag/Zd.real,1e9*Zd.imag/w,Zse.imag/Zse.real,1e9*Zse.imag/w])))

exit()
