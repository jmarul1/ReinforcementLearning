
import sympy
extp,w,s,w,tan,n,oS,dx,dy,sTL,minDxDy,sq2 = sympy.symbols('extp w s w tn n oS dx dy sTL min(dxdy) 2**0.5')
x,y,den,spc = sympy.symbols('x y den spc')

# rectangular
dxR = dx - ( 2*extp+w-s+w*tan+2*n*w+2*n*s )
dyR = dy - ( sTL+2*n*w+2*n*s-2*s )

# octagonal
dxO = dx - ( 2*extp+2*w+s+w*tan+2*oS*minDxDy/(2+sq2)+2*(n-1)*(s+w)*tan )
dyO = dy - ( sTL+2*oS*minDxDy/(2+sq2)+w+2*(n-1)*(s+w)*tan )

# print
#nR = sympy.solve(dxR,n); #print(sympy.pretty(nE))
#nR = sympy.solve(dyR,n); #print(sympy.pretty(nE))
#wR = sympy.solve(dxR,w); print(wR); print(sympy.pretty(wR))
#sR = sympy.solve(dxR,s); print(sR); print(sympy.pretty(sR))
#xR = sympy.solve(dxR,dx); print(xR); print(sympy.pretty(xR))
#yR = sympy.solve(dyR,dy); print(yR); print(sympy.pretty(yR))

#nO = sympy.solve(dxO,n); print(nO); print(sympy.pretty(nO))
#nO = sympy.solve(dyO,n); print(nO); print(sympy.pretty(nO))
#wO = sympy.solve(dxO,w); print(wO); print(sympy.pretty(wO))
#sO = sympy.solve(dxO,s); print(sO); print(sympy.pretty(sO))
#xO = sympy.solve(dxO,dx); print(xO); print(sympy.pretty(xO))
#yO = sympy.solve(dyO,dy); print(yO); print(sympy.pretty(yO))
#oSO = sympy.solve(dxO,oS); print(oSO); print(sympy.pretty(oSO))
#oSO = sympy.solve(dyO,oS); print(oSO); print(sympy.pretty(oSO))

# density
#denO = den - x*y/((x+spc)*(y+spc))
#denO = sympy.solve(denO,spc); print(denO); print(sympy.pretty(denO))

# max density
maxDen, expN = sympy.symbols('maxDen'); # expN = e**(-c2/n)
c0 = 2 # min width
c1 = 34 # fudge factor
c2 = 1-maxDen
c3 = 3/5 #slope
w = c0 + c1*expN + c3*s
s = (w - c0 - c1*expN )/c3
n = -c2/math.log((w - c0 - c3*s)/c1)
