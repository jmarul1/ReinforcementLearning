#!/usr/bin/env python2.7
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
# Author:
#   Chang-Tsung Fu, Mauricio Marulanda
# Description:
#   Type >> tldCrisp.py -h 
##############################################################################

DEFAULT_CRISP = "/nfs/site/eda/group/SYSNAME/tcad/common/netcap3d/v9.0/netcap3d"
DEFAULT_QCAP = "/p/fdk/gwa/ctfu/fdk73/p1273_6x2r0.qcap"

import argparse 
import os
import subprocess as sb
import tempfile
import re
import sys
import shutil


class CrispCell:
  '''A simple class for cell attributes in CRISP analysis.'''
  def __init__(self, cellInfo, workDir):
    '''Create a cell with associate attributes.
    cellname: the cell name in model.
    captype: s2s, s2p, s2g (signal to signal/power/ground)
    testlib: the testcase library name.
    testcell: the testcase with arrayed cell.
    testports: the ports to evaluate capacitance.
    -----------------------------------------
    model: the extracted circuit model in spice format.
    '''
    self.cellname = cellInfo[0]
    self.captype = cellInfo[1]
    self.testlib = cellInfo[2]
    self.testcell = cellInfo[3]
    self.testsize = cellInfo[4]
    self.testports = cellInfo[5].split(' ')

    self.cntlfile = os.path.join(workDir, self.testcell+'.cntl')
    self.testgds = os.path.join(workDir, self.testcell+'.input.gds')
    self.creategds = False
    self.floatfile = os.path.join(workDir, self.testcell+'.floatlist')
    self.cellports = []
    self.nodelist = []
    self.rawmodel = []
    self.cktmodel = []


class inst2:
  def __init__(self, name, n1, n2, typ, val):
    self.name = name
    self.n1 = n1
    self.n2 = n2
    self.typ = typ
    self.val = val
    self.dev = 0


def user_briefing():
  '''
  Brief the execution overview to the user.
  '''
  print('''
    
    TLD Streamlined CRISP Running Procedure 
    (Version: 14ww28; Contact: ctfu, jmarulan)

    Use this environment for CRISP run: 
    > fdk73 pdk736_r1.3 qa -t pdk73i
 
    This procedure will go through the following steps: 
    1. Check and import cell list file input (CellsToRunCrisp.csv). If it doesn't 
       exist, one will be generated as a template and exit. 
    2. Check the existence of the following files for cells in the list: 
         a) GDS stream files (<testcase>.input.gds).
         b) Floating net files (<testcase>.floatnets.txt).
       If they don't exist or the user prefer to regenerate them, a skill file 
       will be created to be run in virtuoso for generating these files. 
       The user can decide to exit and run the skill in a separate virtuoso 
       session or invoke virtuoso by this program.
    3. Invoke virtuoso to stream out files if required.
    4. Create CRISP control files.
    5. Execute CRISP analysis through netbatch (QCAP file is necessary).
    6. Rerun with "-skipcrisp" switch to skip more CRISP runs, check data status, 
       and collect all the data into a csv file. The stored data is scaled down 
       to unit cell.
    7. Process all data into a model file 'Crisp_Output_Model.sp'. 

    The user should provide working directory and qcap file as inputs.
    
    ''')


def check_workdir(dirpath):
  if not os.path.isdir(dirpath):
    print("Directory: '"+dirpath+"' doesn't exist. \n")
    print("Create this directory (default:No)? [y/N] ")
    createfile = sys.stdin.readline().rstrip('\n')
    if (createfile == 'y' or createfile == 'Y'):
      print("Creating: "+dirpath+" \n")
      os.makedirs(dirpath)
    else: 
      return False
  return dirpath


def check_filetype(filepath, typelist):
  '''
  check_filetype(filepath, typelist)

  Check the prvided <filepath> if:
  1) File exists, and
  2) Extended file name matches one in the <typelist> provided 
  Return <filepath> if true, or return 'False' if not.
  '''
  import os
  if os.path.isfile(filepath):
    return filepath.split('.')[-1] in typelist
  else:
    return False


def check_gdsfile(filepath):
  '''
  check_gdsfile(filepath)

  Use check_filetype() to check the prvided <filepath> if:
  1) File exists, and
  2) Extended file name matches 'gds' or 'csv' 
  Return <filepath> if true, or return 'False' if not.
  '''
  return check_filetype(filepath, 'gds')


def import_celllist(workDir):
  '''
  Import list file content
  '''
  cellListFilePath = os.path.join(workDir, 'CellsToRunCrisp.csv')
  if os.path.isfile(cellListFilePath):
    cellListFile = open(cellListFilePath, 'r')
    cellList = []
    for line in cellListFile:
      if (line[0] != '#') & (line.strip() != ''):
        cellInfo = line.strip(' \n').split(',')
        cellList.append(cellInfo)
    cellListFile.close()
    if cellList == '':
      print("No cell is specified in the list file to run: \n"+cellListFilePath+'\n')
      return False

    cellNum = 0
    crispRunCells = []
    checkErrorFlag = [0,0]
    #The first flag is for each cell assignment, the second is for overall exception. 
    for cellInfo in cellList:
      checkErrorFlag[0] = 0
      for test in crispRunCells: 
        if cellInfo[2:4] == [test.testlib, test.testcell]: 
          print("[Error] Same testcase '"+test.testcell+"'is redefined in line "+str(cellNum+1)+".")
          checkErrorFlag = [1,1]
        elif cellInfo[0] == test.cellname: 
          print("[Warning] Cell "+cellInfo[0]+" has multiple test cases.")
          checkErrorFlag = [0,0]   
      if checkErrorFlag[0] == 0:
        # Regorganize cell info as data class CrispCell.  
        crispRunCells.append( CrispCell(cellInfo, workDir) )
      
      cellNum += 1
    if checkErrorFlag[1] == 1:
      print("Please correct the 'CellsToRunCrisp.csv' file. \n") 
      return False
    return crispRunCells

  else:
    print("The list file: '"+cellListFilePath+"' is not found. \n")
    print('A template file is generated as: ./CellsToRunCrisp.csv \n')
    cellListFile = open(cellListFilePath, 'w')
    cellListFile.write("""# Cell List for CRISP Analysis.
# The TestPorts list below defines ports to have full cap evaluation. 
# <CapType> should be s2s s2p or s2g. This needs to be specified precisely (no debug capability).
# <TestCase_ArraySize>: If the test array is a 10x12 array then the size is '120' (10 times 12).
# Use "#" to comment out the line.
# Example:
#<Template_Cellname>,<CapType>,<TestCase_Library>,<TestCase_Cellname>,<TestCase_ArraySize>,<TestPorts (separate with space)>
#d86smfcnvm7a,s2s,intel73lvqa,d86smfcnvm7a_10x10,100,mfcport1 mfcport2
#d8xsmfcevm4a,s2s,intel73lvqa,d8xsmfcevm4a_3x3,9,mfcport1_ehv mfcport2_ehv 
\n""")
    print("Please prepare the 'CellsToRunCrisp.csv' file and run this program again. \n")
    cellListFile.close()
    return False


def create_skill_file(workDir, crispRunCells):
  skillFilePath = os.path.join(workDir, 'makeCrispInputs.il')
  skillFile = open(skillFilePath, 'w')
  skillFile.write('''
load("/p/fdk/gwa/jmarulan/fdk73/work/utils/scripts/skill/mauSkill")

/*---------------------------------------------------------------------------
 procedure: createCrispGds()
 Created by Mauricio Marulanda
 Purpose: Insert Pins in the test row
 ---------------------------------------------------------------------------*/
procedure( createCrispGds(libName cellName outDir) 
  let( (cv outFile fidOut outCellName outLibName)
    outDir = simplifyFilename(outDir)
    unless(isDir(outDir) sh(strcat("mkdir " outDir)))
  ; save cell in home library
    cv = dbOpenCellViewByType(libName cellName "layout")
    if(cv then
      outCellName = strcat(upperCase(cellName))
      outLibName = strcat(getShellEnvVar("USER") "_p" getShellEnvVar("FDK_DOTPROC")) 
      dbSave(cv outLibName outCellName "layout")
      dbClose(cv)
      fdkStreamGds(outLibName strcat(outCellName "$") outDir strcat(cellName ".input.gds"))
    else
      printf(strcat("ERROR: " cellName " does not exist"))       
    ); if
));;procedure

''')
  for cell in crispRunCells:
    if cell.creategds:
      skillFile.write('createCrispGds("'+cell.testlib+'" "'+cell.testcell+'" "'+workDir+'") \n')
  skillFile.close()
  print("\nExecute below command in Virtuoso CIW:")
  print('load("'+skillFilePath+'")\n')


def create_cntlfile(cell, qcapFilePath, nbrun):
  '''Create CRISP control file for the cell member'''
  _portlist = ''
  for _port in cell.testports:
    _portlist = _portlist + ' ' + _port
  _portlist = _portlist.lstrip()
  if nbrun:
    nbrun_cmd = '''
NETBATCH_CMD: nbjob run --target pdx_vpnb --class SLES11_EM64T_16G --qslot /icf/fdk/pck_max
NETBATCH_POOL: pdx_normal
'''
  else:
    nbrun_cmd = ''

  with open(cell.cntlfile,'wb') as cntlfile: 
    cntlfile.write('''
; (1) Add these lines to the .cshrc:
;     setenv TCAD_HOME /nfs/site/eda/group/SYSNAME/tcad
;     alias crisp \$TCAD_HOME/common/netcap3d/v9.0/netcap3d
;
; (2) In the stream out form in Cadence, choose Options and make sure that 
;     case sensitive is set to "upper".
;
; (3) Make sure that in the control file (i.e this file) the cell name is 
;     typed in capital. 
;
; (4) Don't forget to source the file crisp.setup.
;
; (5) Make sure that the GDS file is called my_file_name.input.gds and 
;     in the same directory as the one you run netcap3d from.
; 
; (6) invoke as 'crisp netcap3d.cntl'
;NETBATCH_CMD: nbjob run --target pdx_normal --class SLES10_EM64T_CSG --class-reservation "fRM=65536" --qslot /ciaf/pck_max

CELL_NAME: '''+cell.testcell.upper()+'''
FORMAT_LAYOUT_INFILE:   stream
LAYOUT: '''+cell.testcell+'''
SCALE_FACTOR:     1.0

ENGINE:     CRISP5

PROCESS_FILE_QCAP:      '''+os.path.realpath(qcapFilePath)+'''
FLOATINGNET_FILE:       '''+os.path.realpath(cell.floatfile)+'''
EXTRACT_SIGNAL: '''+_portlist+'''
;Window_signal: '''+_portlist+'''
;SIZE_OF_WINDOW:         50
TIME_FOR_EXTRACTION:    60
TOTAL_CAP_ACCURACY:     0.05%@1fF
XCAP_ACCURACY:          0.05%@1fF
RENAME_TEXT_OPEN: 0
; RENAME_TEXT_OPEN: 0 -> allows netlisting short and gets rid of "INTEL_*" float nets.
MIN_XCAP_PERCENT:       0

'''+nbrun_cmd+'\n')


def run_crisp(workdir, crispExe, crispRunCells, seqrun):
  '''Invoke batched CRISP analysis'''
  actualRunList = []
  for cell in crispRunCells:
    outDir = os.path.join(workdir, 'crisp5', cell.testcell.upper())
    if os.path.isdir(outDir): 
      if os.path.isfile(os.path.join(outDir,'allNets.summary')):
        print("Skip CRISP as the completed result exists: "+cell.testcell)
        continue
    sb.call('rm -rf '+outDir,shell=True)
    print("To be run with CRISP:: "+cell.testcell)
    actualRunList.append(cell)

  # Ask user to proceed running CRISP.  
#  print("\nReady to run CRISP. Proceed? (default:N)? [y/N] ") 
  keyin = 'y' #sys.stdin.readline().rstrip('\n')
  if not (keyin == 'y' or keyin == 'Y'):
    return

  for cell in actualRunList:
    cmdToRun = crispExe+' '+cell.cntlfile+' > '+workdir+'/'+cell.testcell+'.CrispLOG'
    runCrisp = sb.Popen(cmdToRun,shell=True)
    print cmdToRun
    print("Runing: "+cell.testcell)
    runCrisp.communicate()
    #runCrisp = sb.Popen(crispExe+' '+cell.cntlfile,stdout=sb.PIPE,stderr=sb.PIPE,shell=True);
    if seqrun: runResult = runCrisp.wait()
  #print 'STDERR\n'+runResult[1]+'\n\n'
  #print 'STDOUT\n'+runResult[0]+'\n\n'


def collect_data(workdir, crispRunCells):
  '''Return CRISP extracted model of the cell'''
  cellsRdyForModel = []
  print('Post-CRISP Data Avalability: \n')
  for cell in crispRunCells:
    crispOutDir = os.path.join(workdir, 'crisp5', cell.testcell.upper())
    crispOutSumFile = os.path.join(crispOutDir,'allNets.summary')
    if not os.path.isfile(crispOutSumFile): 
      print("Waiting for CRISP Result for cell: "+cell.cellname+" ("+cell.testcell+")") 
      continue
    print("Data Available: "+cell.cellname)
    cellsRdyForModel.append(cell)
  print('\n')

  for cell in cellsRdyForModel:
    crispOutDir = os.path.join(workdir, 'crisp5', cell.testcell.upper())
    crispOutSumFile = os.path.join(crispOutDir,'allNets.summary')
    netlist = []
    nodelist = []
    prim_node_list = []
    with open(crispOutSumFile, 'r') as crispSumFile:
      for line in crispSumFile:
        
        # Find the primary node
        match_node_0 = re.search('Capacitance Extraction Report for Net\s*(\w+)', line)
        if match_node_0:
          prim_node = match_node_0.group(1)
          prim_node_list.append(prim_node)
          if prim_node not in nodelist:
            nodelist.append(prim_node)
          # Define special instance to ground for the primary node.
          cgnum = re.search('\w+(\d+)\w*', prim_node)
          if cgnum:
            cgname = 'Cg'+cgnum.group(1)
          else:
            cgname = 'Cgp'
          capground = inst2(cgname, prim_node, 'vssx', 'C', 0)
          continue

        # Filter out low ratio *floatiss* nodes.
        match_float = re.search('\s*\w*float\w*\s+(\d+?.?\d+)\s+', line)
        if match_float: 
          if float(match_float.group(1)) < 0.1:
            continue

        # Find the cap value of other nodes to the primary node.
        match_node_n = re.search('\s*(\w+)\s+(\d+?.?\d+)\s+(\d+?.?\d+)\s*\((\d+?.?\d+%)\)', line)
        if match_node_n:
          if match_node_n.group(1) != prim_node:
            capval = float(match_node_n.group(3)) / int(cell.testsize)
            # Merge data associated with VSS and ground to VSS only. 
            if match_node_n.group(1) in ['VSS', 'ground']:
              capground.val = capground.val + capval
              continue
            if match_node_n.group(1) not in nodelist:
              nodelist.append(match_node_n.group(1))

            # Search if there aredata from different tests to merge with. 
            multidata = False
            for capinst in netlist:
              if (prim_node, match_node_n.group(1)) == (capinst.n2, capinst.n1) :
                multidata = True
                capinst.val = (capinst.val + capval) / 2
                capinst.dev = abs(capval / capinst.val - 1) * 100

            if not multidata:
              newcap = inst2('Ctemp', prim_node, match_node_n.group(1), 'C', capval)
              netlist.append(newcap)
        
        # Find the border of the primary node, and do instance name arrangement.
        match_border = re.search('\=+', line)
        if match_border and capground.val != 0:
          netlist.append(capground)
    
    cell.nodelist = nodelist
    cell.nodelist.append('vssx')
    cell.rawmodel = netlist
    cell = cellModelMatch(cell)

  
  # Ask user to display the data as a glance or not.  
#  print("Would you like to have the glance of data? (default:N)? [y/N] ")
  keyin = 'n' #sys.stdin.readline().rstrip('\n')
  if not (keyin == 'y' or keyin == 'Y'):
    return cellsRdyForModel
  for cell in cellsRdyForModel:
    print('.SUBCKT '+cell.cellname+' '+' '.join(node for node in cell.nodelist))
    for capinst in cell.rawmodel:
      if capinst.dev == 0:
        print(capinst.name+' '+capinst.n1+' '+capinst.n2+' '+capinst.typ\
          +' %.4f' % capinst.val)
      else:
        print(capinst.name+' '+capinst.n1+' '+capinst.n2+' '+capinst.typ\
          +' {0:.4f} (dev:{1:.2f}%)'.format(capinst.val,capinst.dev))
    print('.ENDS '+cell.cellname+'\n')
  return cellsRdyForModel


def cellModelMatch(cell):
  if cell.captype == 's2g':
    for inst in cell.rawmodel:
      inst.name = 'Cg'

  elif cell.captype == 's2p':
    for inst in cell.rawmodel:
      if inst.name == 'Ctemp':
        inst.name = 'Cp'
  
  elif cell.captype == 's2s':
    for inst in cell.rawmodel:
      if inst.name == 'Ctemp':
        ccnum = re.search('\w+(\d+)\w*', inst.n1)
        if ccnum:
          ccnum2 = re.search('\w+(\d+)\w*', inst.n2)
          if ccnum2:
            ccname = 'Cc'
          else:
            clsh = re.search('\w+lower\w*', inst.n2)
            if clsh:
              ccname = 'Clsh'+ccnum.group(1)
            else:
              ccname = 'Cush'+ccnum.group(1)
          inst.name = ccname
  '''
  !! Still need to match term order and the rest junction cap...!!
  '''
  return cell


def model_to_Csv(workdir,cellsRdyForModel):
  outCsvFile = os.path.join(workdir,'Crisp_Result.csv')
  with open(outCsvFile, 'w') as outfile:
    outfile.write('Signal to Signal MFCs:\n')
    outfile.write('Cellname,Cc,Clsh1,Cush1,Clsh2,Cush2,Cg1,Cg2\n')
    for cell in cellsRdyForModel:
      if cell.captype == 's2s':
        Cc,Cush1,Cush2,Clsh1,Clsh2,Cg1,Cg2 = '','','','','','',''
        for inst in cell.rawmodel:
          if (inst.name == "Cc"): Cc = str(inst.val)
          if (inst.name == "Cush1"): Cush1 = str(inst.val)
          if (inst.name == "Cush2"): Cush2 = str(inst.val)
          if (inst.name == "Clsh1"): Clsh1 = str(inst.val)
          if (inst.name == "Clsh2"): Clsh2 = str(inst.val)
          if (inst.name == "Cg1"): Cg1 = str(inst.val)
          if (inst.name == "Cg2"): Cg2 = str(inst.val)
        outfile.write(cell.cellname+','+Cc+','+Clsh1+','+Cush1+','+Clsh2+','+Cush2+','+Cg1+','+Cg2+'\n')

    outfile.write('\nSignal to Power MFCs:\n')
    outfile.write('Cellname,Cp,Cg1,Cgp\n')
    for cell in cellsRdyForModel:
      if cell.captype == 's2p':
        Cp,Cg1,Cgp = '','',''
        for inst in cell.rawmodel:
          if (inst.name == "Cp"): Cp = str(inst.val)
          if (inst.name == "Cg1"): Cg1 = str(inst.val)
          if (inst.name == "Cgp"): Cgp = str(inst.val)
        outfile.write(cell.cellname+','+Cp+','+Cg1+','+Cgp+'\n')

    outfile.write('\nSignal to Ground MFCs:\n')
    outfile.write('Cellname,Cg\n')
    for cell in cellsRdyForModel:
      if cell.captype == 's2g':
        Cg = ''
        for inst in cell.rawmodel:
          if (inst.name == "Cg"): Cg = str(inst.val)
        outfile.write(cell.cellname+','+Cg+'\n')

  print('CSV File Generated: \n'+outCsvFile+'\n')

##########################
## Main Script 
##########################

def main():
  argparser = argparse.ArgumentParser(description='TLD Streamlined CRISP Running Procedure (Version: 14ww30; Authors: ctfu, jmarulan)')
  argparser.add_argument(dest='workdir', nargs='?', default='$WARD/CRISP/', help='Working directory. Default: $WARD/CRISP/')
  argparser.add_argument('-qcap', dest='qcap', default=DEFAULT_QCAP, help='Specify alternative technology QCap File.')
  argparser.add_argument('-crisp', dest='crispexe', default=DEFAULT_CRISP, help='Specify alternative CRISP engine.')
  argparser.add_argument('-skipcrisp', dest='skipcrisp', action='store_true', help='Skip CRISP run and process with the previous results.')
  argparser.add_argument('-nb', dest='nb', action='store_true', help='Run CRISP in Netbatch.')
  argparser.add_argument('-seq', dest='seq', action='store_true', help='Run CRISP sequentially.')
  args = argparser.parse_args()
  user_briefing()   # Brief the execution overview to the user. 

  workdir = os.path.realpath(os.path.expandvars(args.workdir))
  print("Working Directory: "+str(workdir))
  if check_workdir(workdir) == False:
    print("Quit the procedure. \n")
    return 
  qcapfile = args.qcap
  if not check_filetype(qcapfile, 'qcap'): raise IOError("ERROR: QCAP file is not found:"+qcapfile)
  print("QCAP file: "+str(qcapfile))  
  crispexe = args.crispexe
  if not os.path.isfile(crispexe):
    print("ERROR: CRISP execution file is not found. \n \
    The procedure can be continued till the execution of actual CRISP run.\n")
    crispexe = False
  print("CRISP execution file: "+str(crispexe))  
  skipcrisp = args.skipcrisp
  print("Skip CRISP run option: "+str(skipcrisp))
  if not skipcrisp:
    nbrun = args.nb
    print("Netbatch run option: "+str(nbrun))
    seqrun = args.seq
    print("Sequential run option: "+str(seqrun))
  print("\n")
  ###############################################
  crispRunCells = import_celllist(workdir)
  if crispRunCells == False:
    print("Quit the procedure. \n")
    return
  cwd_orig = os.getcwd()
  os.chdir(workdir)

  if not skipcrisp:
    # Check the existence of GDS and float files.
    create_skill = False
    for cell in crispRunCells:
      if not check_gdsfile(cell.testgds):
        print(os.path.basename(cell.testgds)+" doesn\'t exist ... to be created.")
        cell.creategds = True
        create_skill = True
      if not os.path.isfile(cell.floatfile):
        print(os.path.basename(cell.floatfile)+" doesn\'t exist ... one is generated with default content.")
        with open(cell.floatfile, 'w') as floatfile:
          floatfile.write('''FLOAT\nFloat\nfloat\nSYN\nSyn\nsyn\ngenerated\n''')
  
    # Check if one needs to create skill file for gds and float file generation.
    if create_skill:
      create_skill_file(workdir, crispRunCells)
      print("Quit the procedure for now.")
      print("Please rerun after finishing executing the skill file in Virtuoso.\n")
      return
    
    # Check existence of qcap file. 
    if not qcapfile:
      print("Please locate the right QCAP file before continue.\n") 
      print("Quit the procedure. \n")
      return
    
    # Always recreate the cntl files.
    for cell in crispRunCells:
      create_cntlfile(cell, qcapfile, nbrun)
    
    # Check existence of CRISP engine. 
    if not crispexe:
      print("Please locate the right CRISP engine to run. \n \
        (E.g., '$TCAD_HOME/common/netcap3d/v9.0/netcap3d')\n") 
      print("Quit the procedure. \n")
      return
    run_crisp(workdir, crispexe, crispRunCells, seqrun)

  # Collect completed CRISP results.
  cellsForModel = collect_data(workdir, crispRunCells)

  # Ask user to proceed running CRISP.  
 # print("\nMake CSV table and hspice model? (default:N)? [y/N] ")
 # keyin = sys.stdin.readline().rstrip('\n')
 # if not (keyin == 'y' or keyin == 'Y'):
 #   return

  # Export CSV table file for visual review.
  model_to_Csv(workdir, cellsForModel)

if __name__ == '__main__':
  main()





