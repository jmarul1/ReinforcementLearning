#### GM BODY ###
def transistor(tech,tipo,W,L,NF):
  if tech == '1222':   return ''
  elif tech == '1231': return f'ndsxtor_rf w={W}*{NF} l={L} lovd=25n lovs=35n lgd=160n lgs=160n lnpluss=55n lnplusd=55n pos=2 tcnws=700n tcnwd=700n nf={NF} m=1 sgc=0'
  else:                return ''

def resistor(tech,W,L):
  if tech == '1222':   return ''
  elif tech == '1231': return f'tfr_res config=0 w={W} l={L} rlegs=1'
  else:                return ''

def capacitor(tech,NX,NY):  
  if tech == '1222':   return ''
  elif tech == '1231': return f'mim_cap nx={NX} ny={NY}'
  else:                return ''
