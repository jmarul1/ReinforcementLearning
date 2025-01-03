#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def describe(): return('''
Creates a permutation of all possible combinations from input csv table (be careful on the size).
############ SAMPLE TABLE #############
parameter   , min , max , discrete ,  type  , steps
paramName1  ,   0 ,  10 ,          ,   int  ,     1
paramName2  ,   a ,   b ,  "a,b,c" , string ,     1 # discrete takes priority
############ SAMPLE TABLE #############''');

def splitInFiles(fullT,split):
  splitNum = int(numtools.getScaleNum(split));
  typeLine = fullT.iloc[0,:].to_frame().transpose()
  sampleT = fullT.drop('type').reset_index(drop=True)
  files = int(len(sampleT)/splitNum)+(1 if len(sampleT)%splitNum > 0 else 0)
  for ss in range(files):
    fname = f'sample_{split}_{ss}.csv'; beg = ss*splitNum; end = min(beg+splitNum-1,len(sampleT))
    tempT = pd.concat([typeLine,sampleT.loc[beg:end,:]])
    tempT.to_csv(fname,index_label='instName'); print(tempT) 

def printSummary(df):
  sampleT = df.drop('type')
  test = sampleT.apply(numtools.getScaleNum).describe(include='all')
  test=test.drop(['25%','50%','75%'])
  print(test.apply(numtools.numToSi,precision=1),file=sys.stderr)
     
##############################################################################
# Argument Parsing
##############################################################################
import argparse, tablegen, os, pandas as pd, sys, numtools
argparser = argparse.ArgumentParser(description=describe(), formatter_class=argparse.RawTextHelpFormatter)
argparser.add_argument(dest='csv', help='csv file or Type "table" to print a sample table')
argparser.add_argument('-sample', dest='sample', type=int, help='Random sample')
argparser.add_argument('-infiles', dest='fs', nargs='?', const='full', help='Split entries in files')
argparser.add_argument('-summary', dest='summary', action='store_true', help='Describe the table')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
fullT = tablegen.bruteForce(args.csv); 
## select a sample if asked
if args.sample: 
  typeLine = fullT.iloc[0,:].to_frame().transpose()
  sampleT = fullT.drop('type').sample(args.sample).reset_index(drop=True)
  fullT = pd.concat([typeLine,sampleT])
## print to stdout or to files if asked
if args.fs: splitInFiles(fullT,args.fs); 
else: stdout = fullT.to_csv(index_label='instName'); print(stdout)
## print for info
if args.summary:  printSummary(fullT)
else: print(fullT,file = sys.stderr)
