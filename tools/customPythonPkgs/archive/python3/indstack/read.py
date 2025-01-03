##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2013, Intel Corporation.  All rights reserved.               #
#                                                                            #
# This is the property of Intel Corporation and may only be utilized         #
# pursuant to a written Restricted Use Nondisclosure Agreement               #
# with Intel Corporation.  It may not be used, reproduced, or                #
# disclosed to others except in accordance with the terms and                #
# conditions of such agreement.                                              #
#                                                                            #
# All products, processes, computer systems, dates, and figures              #
# specified are preliminary based on current expectations, and are           #
# subject to change without notice.                                          #
##############################################################################
#
# Author:
#   Mauricio Marulanda
#
# Description:
#   Deal with inductor stack
#
##############################################################################

class read():
  '''reads and process the contents of the eqvStack file'''
## Read the contents of the file
  def __init__(self,inFile,dummy=None,exclude=None,lti=0,ltb=0,PR=None): #PR = None means you can give none for no limitation in decimals
    import os, re, collections; from stackUtils import readTechFile, correctOxides, getExcludeValue
    self.fileName = inFile; self.PR = PR; self.ltb = ltb; self.lti = lti
    with open(self.fileName,'rb') as fin:
      self.header = {}; self.stack = {'Layer':collections.OrderedDict(),'Metal':collections.OrderedDict(),'Via':collections.OrderedDict()};
      numExp = '([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
      self.header['DUMMY_EXCLUDE_FROM_TOP'] = '0'
      for line in fin:
      ## find the process, skew, temp, BUMP factor, exclusion from top
        for var in ['PROCESS','SKEW','TEMP','BUMP_EPSR_FACTOR','DUMMY_EXCLUDE_FROM_TOP']:
          test = re.search(r'^'+var+'.*\[(.*)\]',line,flags = re.I)
          if test: self.header[var] = test.group(1)
      ## find the epi and find the substrate
        test1 = re.search(r'EPI\s+SIGMA\s+=\s+(\d+)',line,flags = re.I);   test2 = re.search(r'SUBSTRATE\s+SIGMA\s+=\s+'+numExp,line,flags = re.I)
        if test1: self.header['EPI'] = test1.group(1)
        if test2: self.header['SUBSTRATE'] = test2.group(1)
      ## get all the oxides, metals, vias
        for var in ['Layer','Metal','Via']:
          test1 = re.search(r''+var+'\s+#.*?"(\w+).*"',line,flags = re.I); 
          test2 = filter(lambda ff: ff!='', re.findall(r''+numExp,line,flags = re.I));
	  if test1 and test2: 
            #test3 = re.search(r'(tcn|tfr|tf|tfres|tga|capelectrode1|ce|ce1|ce2|ce3|mlv)$', test1.group(1),flags=re.I) # only keep the metals/vias for inductors	  
            test3 = re.search(r'(tcn|tga|ce1|ce2|ce3)$', test1.group(1),flags=re.I) # only for p1231 uncompensated case without csvstack
	    if not test3: self.stack[var][test1.group(1)] = test2[-3:] #store as top_height,epsr,sigma or bottom_height,thickness,sigma	        
      self.dumF = self.header['BUMP_EPSR_FACTOR'] if dummy == None else dummy
      ## correct the oxides first based on file inputs
      self.stack['Layer'] = correctOxides(self.stack['Layer'],int(self.header['DUMMY_EXCLUDE_FROM_TOP']), float(self.header['BUMP_EPSR_FACTOR']),compensate='False',PR=self.PR)
      ## find the oxide under the second from the top metal(c4,tm1 or gm1 or m8) and use it depending on the inputs
      self.exclude = getExcludeValue(self.stack['Layer'],self.stack['Metal']) if exclude == None else exclude      
      ## correct the oxides based on the given inputs
      self.stack['Layer'] = correctOxides(self.stack['Layer'],int(self.exclude),1,compensate=float(self.dumF),lti=self.lti,ltb=self.ltb,PR=self.PR)
      ## apend skews and layermaps
      self.suffix = '_'+self.header['SKEW']+'Q_'+self.header['TEMP']+'C'  
      self.layermap,self.techfiles = readTechFile(self.header['PROCESS'],inFile)

## convert to csv and print
  def printCsv(self):
    import os; from stackUtils import getViaOffset, getMVTable, getOxides
    outLst = ['#PROCESS='+os.path.basename(self.header['PROCESS'])]; del self.header['PROCESS']
    for var in self.header.keys(): 
      if var == 'DUMMY_EXCLUDE_FROM_TOP': outLst.append('#'+var+'='+ self.exclude)
      elif var == 'BUMP_EPSR_FACTOR': outLst.append('#'+var+'='+ self.dumF)
      else: outLst.append('#'+var+'='+ self.header[var])
    outLst += ['Metal,Zbot(um),Ztop(um),Tc(um),mur(ur),Sigma@'+self.header['TEMP']+'C(S/m)']
    outLst += getMVTable(self.stack['Metal'],PR=self.PR)
    outLst += ['Via,Zbot(um),Ztop(um),Tc(um),mur(ur),Sigma@'+self.header['TEMP']+'C(S/m)']
    outLst += getMVTable(self.stack['Via'],offGuide=self.stack['Metal'],PR=self.PR)
    outLst += ['Oxide/Substrate,Zbot(um),Ztop(um),Thickness(um),mur(ur),Sigma'+'C(S/m),EpsrUncomp,EpsrComp,lossTan']
    outLst += getOxides(self.stack['Layer'],self.dumF,self.exclude,self.PR)
    return '\n'.join(outLst)

## create materials.matdb
  def getMatdb(self):
    import layout, re; from numtools import numToStr as n2s
    ##get conductors
    conds = []
    metals,vias = self.stack['Metal'].keys(),self.stack['Via'].keys()
    for ll in xrange(max(len(metals),len(vias))):
      if ll < len(metals): conds.append('    <Conductor parmtype="1" mur_real="1" imag="" name="'+metals[ll]+self.suffix+'" real="'+self.stack['Metal'][metals[ll]][2]+' Siemens/m" mur_imag=""/>')
      if ll < len(vias):   conds.append('    <Conductor parmtype="1" mur_real="1" imag="" name="'+vias[ll]+self.suffix+'" real="'+self.stack['Via'][vias[ll]][2]+' Siemens/m" mur_imag=""/>')
    conds.reverse()    # old    --- for metal,mInfo in self.stack['Metal'].items():    conds=layout.sortMetalVia(conds,prefixExp='name="'); 
    ##get dielectrics
    diels = []; semis = []
    for layer,lInfo in self.stack['Layer'].items(): 
      if re.search(r'^g',layer,flags=re.I): continue
      if re.search(r'^(su|ep)',layer,flags=re.I): semis.append('    <Semiconductor mur_real="1" resistivity="'+n2s(100/float(lInfo[2]),self.PR)+' Ohm.cm" name="'+layer+self.suffix+'" er_real="'+lInfo[1]+'" doping="p" mur_imag=""/>')
      else: diels.append('    <Dielectric loss_type="0" mur_real="1" lowfreq="1 KHz" valuefreq="1 GHz" er_imag="" highfreq="1 THz" er_loss="'+lInfo[3]+'" name="'+layer+self.suffix+'" er_real="'+lInfo[1]+'" mur_imag=""/>')
    return conds,diels,semis     

## create substrate.subst
  def getSubstrate(self,indMetals=None):
    import layout; from stackUtils import findOxide; from numtools import numToStr as n2s 
    newOxides = []; newVias = []; newMetals = []
    for layer in self.stack['Layer'].keys():
      newOxides.append([layer,self.stack['Layer'][layer][0]])
    ## find the oxide intercepting the metal, store the metal(indx and th) and duplicate that oxide
    if indMetals==None: lstLayerStack = enumerate(zip(self.stack['Metal'].keys()[::-1],['vdummy']+self.stack['Via'].keys()[::-1]))
    else: lstLayerStack = enumerate(zip(self.stack['Metal'].keys()[::-1][-int(indMetals):],self.stack['Via'].keys()[::-1][-int(indMetals):]))
    for ii,(metal,via) in lstLayerStack:  
      indx,oxide,skip = findOxide(newOxides,self.stack['Metal'][metal][0])
      newMetals.append([metal,self.stack['Metal'][metal][1],self.layermap[metal],indx]);
      if len(newMetals)>1: 
        if via in self.layermap.keys(): newVias.append([via,newMetals[-2][3],indx,self.layermap[via]]);
	else: print 'ERROR: Via not in layermap: '+via; newVias.append([via,newMetals[-2][3],indx,self.layermap[via]]);
      if skip == True: continue 
      newOxides.insert(indx,[oxide,self.stack['Metal'][metal][0]])
    ## compute the oxides
    subs = ['    <material materialname="AIR" BAL_TYPE="INHERIT" BAL_NUM="0"/>\n    <interface materialname="PERFECT_CONDUCTOR" BAL_TYPE="NONE" thick="0" thickunit="micron" BAL_NUM="0" groundplane="1"/>']  
    interface = '    <interface materialname="" BAL_TYPE="INHERIT" thick="0" thickunit="micron" BAL_NUM="0"/>'
    for ii,(layer,height) in enumerate(newOxides[:]):
      if ii == 0: oldH = float(height); continue
      oxTh = n2s(float(height) - oldH,self.PR); 
      if float(oxTh) == 0: oxTh = '0.001'
      newOxides[ii].append(oxTh)
      subs.append('    <material materialname="'+layer+self.suffix+'" BAL_TYPE="INHERIT" thick="'+oxTh+'" thickunit="micron" BAL_NUM="0"/>\n'+interface)
      oldH = float(height)
    subs.append('    <material materialname="AIR" BAL_TYPE="INHERIT" BAL_NUM="0"/>')    
    ## compute the layers
    layers = []; 
    for metal,th,techNum,indx in newMetals:
      oxIndx = findOxide(newOxides,self.stack['Metal'][metal][0])[0] + 1
      if oxIndx <= len(newOxides) and float(th)>=float(newOxides[oxIndx][2]): ## correct the metal thickness
        th = n2s(float(th) - 0.001)
      layers.append('    <layer materialname="'+metal+self.suffix+'" toprough="" pinsOnly="0" bottomrough="" thick="'+th+'" precedence="0" sheet="0" thickunit="micron" layer="'+techNum+'" negative="0" subtype="0" expand="0" index="'+str(indx)+'" angle="90"/>')
    vias = []
    for via,indx1,indx2,techNum in newVias:
      vias.append('    <via materialname="'+via+self.suffix+'" rough="" index1="'+str(indx1)+'" index2="'+str(indx2)+'" precedence="0" layer="'+techNum+'" subtype="0"/>')
    return subs,layers,vias
