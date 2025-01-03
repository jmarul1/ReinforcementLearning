;load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/cdsinit")

procedure( plotRfCapBCh(fRng xtr wRng nlRng mfcRng) ;float string floatRng floatRng floatRng float
let( (runArea temp cap  plottingWin suf)
  ;b88nulrf
  runArea = adCreateTmpDir(?prefix "sim_")
  plottingWin = awvCreatePlotWindow() addSubwindow()
  foreach(fff fRng
   foreach(width wRng
    foreach(nlegs nlRng
     foreach(mfc mfcRng
      temp = processRfCapBCh(fff xtr nlegs width mfc runArea)
      suf = sprintf(nil "%LG_%Lw_%Lnl_%Lmfc" fff*1e-9 width*1e9 nlegs mfc*1e15)
      cap = nth(0 temp) Q = nth(1 temp)
      awvSetCurrentSubwindow(plottingWin 1)
      plot(cap ?expr strcat("Cd" suf)) 
      awvSetCurrentSubwindow(plottingWin 2)
      plot(Q ?expr strcat("Q" suf))      
      temp = adWaveToList(cap) cadadr(temp)
  ))));foreach
;  awvRemoveSubwindowTitle(plottingWin ?subwindow 1)  awvRemoveSubwindowTitle(plottingWin ?subwindow 2)
runArea))

procedure( getBstCB(fRng xtr wRng nlRng mfcRng @key (csv nil))
let( (runArea temp cap plottingWin suf capDlt capDltRms Cmax Cmin Qon Qoff csvF )
  ;b88nulrf
  runArea = adCreateTmpDir(?prefix "sim_")  
  when(csv csv = simplifyFilename(csv) csvF = outfile(csv) fprintf(csvF "Freq(GHz),w(nm),nl,mfc(fF),cmin(fF),cmax-cmin(fF),Qon\n"))
  plottingWin = awvCreatePlotWindow()  addSubwindow()
  foreach(fff fRng
   foreach(width wRng
    foreach(nlegs nlRng
     foreach(mfc mfcRng
      temp = processRfCapBCh(fff xtr nlegs width mfc runArea)
      cap = nth(0 temp) Q = nth(1 temp)  
      temp =  adWaveToList(cap) Cmax = cadr(nth(1 temp)) Cmin = cadr(nth(0 temp))
      temp =  adWaveToList(Q)   Qon = cadr(nth(1 temp)) Qoff = cadr(nth(0 temp))
      capDlt =  Cmax - Cmin 
      capDltRms = rms(capDlt) Cmin = rms(Cmin) Qon = rms(Qon)
      when(csvF fprintf(csvF "%s,%s,%s,%s,%.3f,%.3f,%.3f\n" adNum2Str(fff*1e-9) adNum2Str(width*1e9) adNum2Str(nlegs) adNum2Str(mfc*1e15) Cmin*1e15 capDltRms*1e15 Qon))
      suf = sprintf(nil "%sG_%sw_%snl_%smfc" adNum2Str(fff*1e-9) adNum2Str(width*1e9) adNum2Str(nlegs) adNum2Str(mfc*1e15))
      awvSetCurrentSubwindow(plottingWin 1)  plot(cap ?expr strcat("C" suf))      
      awvSetCurrentSubwindow(plottingWin 2)  plot(Q ?expr strcat("Q" suf))            
  ))));foreach
;  awvRemoveSubwindowTitle(plottingWin ?subwindow 1)  awvRemoveSubwindowTitle(plottingWin ?subwindow 2)
close(csvF)
csv))

procedure( processRfCapBCh(frequency xtr nlegs width mfc runArea)  
let( (netlist biasFile cap sweep)
  createCapBNetlists(runArea xtr width nlegs)
  netlist = strcat(runArea "/netlist")
  biasFile = strcat(runArea "/stimulus")
  ; start simulation
  simulator( 'spectre )
  hostMode('local)
  design(netlist)  resultsDir(runArea)
  modelFile('("$INTEL_RF/models/rf/spectre/be22/intel22rf.scs" "tttt") '("$INTEL_PDK/models/core/spectre/be2/p1222_2_var.scs" "tttt")) 
  stimulusFile(?xlate nil biasFile)   
  desVar("iiVCtrl" 1) desVar("mfc" mfc) desVar("rpull" 1)
  analysis('sp ?ports list("PORT1") ?freq sprintf(nil "%L" frequency) ?param "rpull" ?start "1" ?stop "50k" )
  envOption('analysisOrder  list("sp") )  temp(25) 
  sweep = paramAnalysis("iiVCtrl" ?values list(0 1) )
  paramRun('sweep) ;run(); 
  ; calculations  
  cap = imag(yp(1 1 ?result "sp")) / (2*3.1416*frequency)
  Q = imag(-zp(1 1 ?result "sp"))/real(zp(1 1 ?result "sp"))
list(cap Q)
)); proc

procedure( createCapBNetlists(runArea xtr width nlegs)
let( (fout netlist uniq)
  uniq = sprintf(nil "/rpull_mfc_netlist")
  netlist = sprintf(nil "\n\
  mn0 (net1 vctrl net2 vss) %s w=%L l=40n nf=%L multx=1 multy=1 stlen=1\n\
  C1 (net1 net6) capacitor c=mfc\n\
  C0 (net2 net10) capacitor c=mfc\n\
  R1 (vctrlb net1) resistor r=rpull\n\
  R0 (vctrlb net2) resistor r=rpull\n\
  mpi0 (vctrlb vctrl vdd_half vdd) b88pulrf w=270n l=40n nf=4 multx=1 multy=1 stlen=1\n\
  mni0 (vctrlb vctrl vss vss) b88nulrf w=270n l=40n nf=4 multx=1 multy=1 stlen=1\n\
  PORT1 (net10 net6) port r=50 type=sine\n" xtr width nlegs)  
  fout = outfile(strcat(runArea uniq))             fprintf(fout netlist) close(fout)
  fout = outfile(strcat(runArea "/netlist"))       fprintf(fout netlist) close(fout)   
  fout = outfile(strcat(runArea "/netlistFooter")) fprintf(fout "\n") close(fout)
  fout = outfile(strcat(runArea "/netlistHeader")) fprintf(fout "\nsimulator lang=spectre\nglobal 0\n") close(fout)
  fout = outfile(strcat(runArea "/stimulus"))      
  fprintf(fout "vvctrl (vctrl 0) vsource dc=iiVCtrl type=dc\nvvddhalf (vdd_half 0) vsource dc=0.5 type=dc\n") 
  fprintf(fout "vvdd (vdd 0) vsource dc=1 type=dc\nvvss (vss 0) vsource dc=0 type=dc\n") close(fout)
t));proc
