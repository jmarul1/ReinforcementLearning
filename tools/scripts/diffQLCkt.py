#!/usr/bin/env python
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

import sympy as sym
i1,i2,v1,v2 = sym.symbols('i1,i2,v1,v2')
zc,zs,zm,zox,zox3 = sym.symbols('zc,zs,zm,zox,zox3')
isc = sym.symbols('isc')
i1 = v1/zox-isc-(v1-v2)/zc
i2 = -v2/zox+isc+(v1-v2)/zc
eq1 = sym.Eq(v1,i1*zs + i2*zm) 
eq2 = sym.Eq(v2,i2*zs + i1*zm)
v1 = sym.solveset(eq1,v1).args[0]
eq2 = sym.Eq(v2,eval(sym.sstr(i2*zs + i1*zm)))
v2 = sym.solveset(eq2,v2).args[0]
v1 = eval(sym.sstr(v1))
v0 = v1 - v2
Zdiff = v0.subs(isc,1)

CC,LS,RS,LSK,RSK,COX,COX3,RSUB,RSUB3,K12 = [1e-15,1e-9,1,1e-9,1,100e-15,100e-15,10,10,0.5]
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

import numpy
print('Freq(GHz),Qdiff,Ldiff(nH)')
for ww in numpy.arange(0.5,30,0.5):
  w = 2*3.1416*ww*1e9
  zc = -1j/(w*CC)
  zs = w*LS*1j + RS*(RSK+w*LSK*1j)/(RS+RSK+w*LSK*1j)
  zm = w*K12*LS*1j
  zox = -1j/(w*COX)+RSUB
  zox3 = -1j/(w*COX3)+RSUB3
  Zd = (eval(sym.sstr(Zdiff)))
  print(','.join(map(str,[ww,Zd.imag/Zd.real,1e9*Zd.imag/w])))

exit()

ia,ib,ic,zc,zs,zm,zox,zox3 = sym.symbols('ia,ib,ic,zc,zs,zm,zox,zox3')
i1 = ia-ic; i2 = ib-ic; v0 = ic*zc
# loop equations
loop1E = ia*zox+(ia-ic)*zs+i2*zm+(ia-ib)*zox3 #1
loop2E = (ib-ia)*zox3+i1*zm+(ib-ic)*zs+ib*zox #2
loop3E = ic*zc+(ic-ib)*zs-i1*zm-i2*zm+(ic-ia)*zs #3
# solve for ia in terms of ib/ic using loop1
ia = sym.solveset(sym.Eq(loop1E,0),ia).args[0]
# subs in #2 and #4 to eliminate ia
loop2E = eval(sym.sstr(loop2E))
loop3E = eval(sym.sstr(loop3E))
## solve for ib in terms of ic using loop2
ib = sym.solveset(sym.Eq(loop2E,0),ib).args[0]
## subs ib in loop3 and get ic
loop3E = eval(sym.sstr(loop3E))
ic = sym.solveset(sym.Eq(loop3E,0),ic).args[0]
ib = eval(sym.sstr(ib))
sym.pprint(ib)
