#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################
     
##############################################################################
# Argument Parsing
##############################################################################
import argparse, sys, os
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'));
import stockmarket
argparser = argparse.ArgumentParser(description='')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
stk = stockmarket.read('INTC')
stk.fetchData(1)
