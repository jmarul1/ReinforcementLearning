def getOwner(cellName):
	"""Returns owner's name for the cellName or category name input"""
	import os
	intelTech = {'fdk73':'1273', 'fdk71':'1271','f1275':'1275'}.get(os.getenv('PROJECT'))
	if not isinstance(cellName, str):
		raise argparse.ArgumentTypeError('cellName/Category input is not a string.')
	if intelTech == '1275':
		if 'fdk75f8xlto' in cellName or 'FDK75F8XLTO' in cellName or 'Wrappers' in cellName:
			ownerName = 'Krishna'
		elif 'esd' in cellName or 'ESD' in cellName:
			ownerName = 'Jewel'
		elif '8xldcp' in cellName or '8XLDCP' in cellName or 'vargbn' in cellName or 'VARGBN' in cellName or 'varactor' in cellName	or 'VARACTOR' in cellName or 'decap' in cellName or 'DECAP' in cellName:
			ownerName = 'Sanghyun'
		elif 'mfc' in cellName or 'MFC' in cellName:
			ownerName = 'Mauricio'
		elif 'lgnc' in cellName or 'LGNC' in cellName or 'GNAC' in cellName:
			ownerName = 'Alex'
		elif 'ltmd' in cellName or 'LTMD' in cellName or 'lthm' in cellName or 'LTHM' in cellName or 'lbgd' in cellName or 'LBGD' in cellName or 'TM_Bg' in cellName:
			ownerName = 'Alex'
		elif 'lres' in cellName or 'LRES' in cellName or 'Resistor' in cellName:
			ownerName = 'Julien'
		elif 'lindtm' in cellName or 'LINDTM' in cellName or 'INDUCTOR' in cellName:
			ownerName = 'Mauricio'
		else:
			ownerName = 'Sanghyun'
	elif intelTech == '1271':
		ownerName = 'Jewel'
	elif intelTech == '1273':
		if 'fdk73d8' in cellName or 'FDK73D8' in cellName or 'esd_wrappers' in cellName or 'Wrappers' in cellName:
			ownerName = 'Krishna'
		elif 'esd' in cellName or 'ESD' in cellName:
			ownerName = 'Jewel'
		elif 'dcp' in cellName or 'DCP' in cellName or 'decap' in cellName or 'DECAP' in cellName or 'HYBRID' in cellName or 'decap' in cellName:
			ownerName = 'Alex'
		elif 'vargbn' in cellName or 'VARGBN' in cellName or 'varactor' in cellName	or 'VARACTOR' in cellName:
			ownerName = 'Sanghyun'
		elif 'mfc' in cellName or 'MFC' in cellName or 'pattern' in cellName or 'dnw_mvs' in cellName:
			ownerName = 'Ozgen'
		elif 'sgnc' in cellName or 'SGNC' in cellName or 'sdpd' in cellName or 'SDPD' in cellName or 'gnac' in cellName	or 'GNAC' in cellName:
			ownerName = 'Alex'
		elif 'tmdio' in cellName or 'TMDIO' in cellName or 'thmdio' in cellName or 'THMDIO' in cellName or 'bgdio' in cellName or 'BGDIO' in cellName:
			ownerName = 'Alex'
		elif 'cpr' in cellName or 'CPR' in cellName or 'tcn' in cellName or 'TCN' in cellName:
			ownerName = 'Alex'
		elif 'sind' in cellName or 'SIND' in cellName or '_scl' in cellName or 'rfmfc' in cellName or 'RFMFC' in cellName or 'scalable' in cellName:
			ownerName = 'Mauricio'
		else:
			ownerName = 'Mauricio'
	else:
		print "Not in fdk environment. use dbmenu"
	
	return ownerName

def getCat(cellName):
  import re
  if re.search(r'_scl|rfmfc',cellName): cat='SCALABLE'  
  elif re.search(r'^fdk',cellName): cat='ESDWRAPPERS'
  elif re.search(r'esd',cellName): cat='ESD'  
  elif re.search(r'dcp|decap',cellName): cat='DECAP'  
  elif re.search(r'var',cellName): cat='VARACTOR'
  elif re.search(r'mfc',cellName): cat='MFC'
  elif re.search(r'gnc|dpd',cellName): cat='GNAC'
  elif re.search(r'tmdio|tmda',cellName): cat='TMDIODE'
  elif re.search(r'bgdio',cellName): cat='BGDIODE'
  elif re.search(r'cpr',cellName): cat='CPR'
  elif re.search(r'ind',cellName): cat='INDUCTOR'
  elif re.search(r'tcn',cellName): cat='TCN'
  else: cat='UNKNOWN'
  return cat
