##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2014, Intel Corporation.  All rights reserved.               #
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
#   Works with the number
#
##############################################################################

## Check if it is a number
def isNumber(numIn):
  try:
    float(numIn)
    return True
  except ValueError:
    return False   

def isInteger(numIn):
  if int(numIn) - numIn == 0 : return True
  else: return False

def numToLetter(numIn): 
  if type(numIn) == str: ## if numIn is not a number raise an exception
    if isNumber(numIn) and numIn.isdigit(): numIn = int(numIn); 
    else: raise ValueError('Input must represent an integer > 1: \''+numIn+'\'')
  elif not(str(numIn).isdigit() and numIn >= 1): raise ValueError('Input number must be an integer > 1: \''+str(numIn)+'\'')
  tmpl = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  if numIn/(len(tmpl)+1) == 0: return tmpl[numIn-1]
  else: return tmpl[numIn/len(tmpl)-1]+numToLetter(numIn%len(tmpl))

def getFreqM(units):
  from re import search, I
  if search(r'^T.*', units): return 1e12  
  if search(r'^G.*', units): return 1e9
  if search(r'^M.*', units): return 1e6
  if search(r'^k.*', units, flags=I): return 1e3
  if search(r'^m.*', units): return 1e-3
  if search(r'^u.*', units): return 1e-6
  if search(r'^n.*', units): return 1e-9
  if search(r'^p.*', units): return 1e-12 
  if search(r'^f.*', units): return 1e-15  
  if search(r'^a.*', units): return 1e-18  
  return 1 ## no units found

def getScaleNum(strNum):
  from re import search
  if isNumber(strNum): return float(strNum) ## if already a number
  numExp = '([+-]?\d*(?:\.\d*)?(?:[eE][+-]?\d+)?)'; 
  test = search(r'^\s*'+numExp+'\s*([TGMKkmunpfa])?\s*$',strNum.strip())
  if test: 
    unitsM = getFreqM(test.group(2)) if test.group(2) else 1
    return float(test.group(1))*unitsM
  else: 
    #Warning('numtools.getScalNum did not get a number: '+strnum); 
    return strNum ## is not a number just return the input
  
def numToStr(floatNum,precision=None,exp=False):
  """convert the number to string using decimals or exponential depending on the input selection"""
  import re 
  if not isNumber(floatNum): return floatNum
  pGiven = True if precision or precision == 0 else False
  numExp = '([+-]?\d*)(\.\d*)?(?:[eE]([+-]?\d+))?'; inNumStr = str(float(floatNum))
  test = re.search(r''+numExp,inNumStr)
  minDecs = str(abs(int(test.group(3)))+(len(test.group(2))-1+len(test.group(1)) if test.group(2) else 0)) if re.search(r'[eE]-',inNumStr) else None #-ve exponential
  if pGiven: minDecs = str(int(precision));  #if precision overwrite any minDecimals
  if exp: outNumStr = ('%.'+minDecs+'e')%(float(floatNum)) if pGiven else '%e'%(float(floatNum))
  elif pGiven: outNumStr = ('%.'+minDecs+'f')%(float(floatNum)) 
  else: 
    if minDecs: outNumStr = ('%.'+minDecs+'f')%(float(floatNum)) 
    else: 
      outNumStr = str(float(floatNum)); test=re.search(r'(-?\d+)\.(\d*?)0+$',outNumStr); 
      if test: outNumStr = '.'.join(test.groups()) if test.group(2) else test.group(1)
  return outNumStr

def closestNum(numLst,value,tolerance):
  """find the closest number given the tolerance"""
  newLst = list(map(lambda ff: abs(ff - value), numLst)); tempMin = min(newLst)
  if tempMin <= tolerance:
    return newLst.index(tempMin)
  else: return 'NOT'

def percToNum(num):
  if type(num) == str: num = num.replace(' ','').rstrip('%')
  if isNumber(num): num = float(num)/100
  return num
    
def cmpFloat(num1,num2):
  if abs(num1 - num2) < 1e-20: return True
  else: return False
  
def numToWords(integer,first=True):
  if not(isNumber(integer) and isInteger(float(integer))): raise IOError('Input must be an integer: '+str(integer))
  integer = int(float(integer))
  if integer < 0: integer = abs(integer)
  if first and cmpFloat(integer,0): return 'Zero'
  units = ['','One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten','Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eigthteen','Nineteen']
  if integer < 20: return units[integer]
  tens = ['','','Twenty','Thirty','Forty','Fifty','Sixty','Seventy','Eighty','Ninety']
  if integer < 1e2: return tens[int(integer/10)]+numToWords(integer%10,False)
  if integer < 1e3: return units[int(integer/1e2)]+'Hundred'+numToWords(integer%1e2,False)
  if integer < 1e6: return numToWords(int(integer/1e3),False)+'Thousand'+numToWords(integer%1e3,False)    
  if integer < 1e9: return numToWords(int(integer/1e6),False)+'Million'+numToWords(integer%1e6,False)      
  if integer < 1e12: return numToWords(int(integer/1e9),False)+'Billion'+numToWords(integer%1e9,False)        
  if integer < 1e15: return numToWords(int(integer/1e12),False)+'Trillion'+numToWords(integer%1e12,False)          
