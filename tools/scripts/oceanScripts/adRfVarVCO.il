;load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/cdsinit")

procedure( plotRfVarCh(freq vrefRng rpullRng mfcRng varMRng @key (csv simplifyFilename("varactor.csv"))) ;float floatRng floatRng floatRng floatRng
let( (runArea temp cap plottingWin suf effCdDeriv line fout)
  runArea = "/nfs/pdx/disks/wict_wd/jmarulan/temp";
  runArea = adCreateTmpDir(?prefix "sim_")
  plottingWin = awvCreatePlotWindow() addTitle(sprintf(nil "freq=%LG" freq/1e9)) addSubwindow() addSubwindow()
  foreach(vref vrefRng
    foreach(rpull rpullRng
     foreach(mfc mfcRng
      foreach(varM varMRng
       temp = processRfVarCh(freq vref rpull mfc varM runArea)
       suf = sprintf(nil "_%LvRef_%LrPull_%Lmfc_%LvarM" vref rpull mfc*1e15 varM)
       cap = nth(0 temp) Q = nth(1 temp)
       awvSetCurrentSubwindow(plottingWin 1) plot(cap ?expr strcat("Cd" suf) ) 
       awvSetCurrentSubwindow(plottingWin 2) plot(Q ?expr strcat("Qd" suf) )        
       ;effFreqDeriv = deriv(1/(2*3.1416*(cap*ind)**0.5))
       effCdDeriv = deriv(cap) awvSetCurrentSubwindow(plottingWin 3) plot(effCdDeriv ?expr strcat("dCd" suf)) 
       ; create table
       line = tconc(line sprintf(nil "%.2f,%.2f,%.2f,%d,%.2f,%.2f,%.2f,%.2f\n" 1.0*vref rpull/1e3 mfc*1e15 pcFix(varM) ymax(cap)*1e15 ymin(cap)*1e15 (ymax(cap)-ymin(cap))*1e15 value(Q 0)))
  ))));foreach  ;  awvRemoveSubwindowTitle(plottingWin ?subwindow 1)  awvRemoveSubwindowTitle(plottingWin ?subwindow 2)
fout = outfile(csv)  fprintf(fout "vref(V),rpull(kOhms),mfc(fF),varM,Cmax(fF),Cmin(fF),Cmax-Cmin(fF),Qon\n%s" buildString(car(line))) close(fout)
runArea))

procedure( processRfVarCh(frequency vref rpull mfc varM runArea)  
let( (netlist biasFile cap sweep Q)
  createVarNetlists(runArea)
  netlist = strcat(runArea "/netlist")
  biasFile = strcat(runArea "/stimulus")
  ; start simulation
  simulator( 'spectre )
  design(netlist)  resultsDir(runArea)
  modelFile('("$INTEL_RF/models/rf/spectre/be22/intel22rf.scs" "tttt") '("$INTEL_PDK/models/core/spectre/be2/p1222_2_var.scs" "tttt")) 
  stimulusFile(?xlate nil biasFile)   
  desVar("iiVCtrl" 1) desVar("iiVRef" vref) desVar("mfc" mfc) desVar("rpull" rpull) desVar("varM" varM)
  analysis('sp ?ports list("PORT1") ?freq sprintf(nil "%L" frequency) ?param "iiVCtrl" ?start "0" ?stop "1" )
  envOption('analysisOrder  list("sp") )  temp(25) 
  run(); 
  ; calculations  
  cap = imag(yp(1 1 ?result "sp")) / (2*3.1416*frequency) Q = imag(-1*zp(1 1 ?result "sp"))/real(zp(1 1 ?result "sp"))
list(cap Q)
)); proc

procedure( createVarNetlists(runArea)
let( (fout netlist uniq)
  uniq = sprintf(nil "/iiVref_rpull_mfc_netlist")
  netlist = sprintf(nil "\n\
  I0 (net8 net7 vctrl 0) b88xvarnwle2001xnxunx m=varM\n\
  *I0 (net8 net7 vctrl 0) b88vargbndz270f16_prim m=varM\n\
  C1 (net8 net6) capacitor c=mfc\n\
  C0 (net10 net7) capacitor c=mfc\n\
  R1 (vref net8) resistor r=rpull\n\
  R0 (vref net7) resistor r=rpull\n\
  PORT1 (net10 net6) port r=50 type=sine\n")  
  fout = outfile(strcat(runArea uniq))             fprintf(fout netlist) close(fout)
  fout = outfile(strcat(runArea "/netlist"))       fprintf(fout netlist) close(fout)   
  fout = outfile(strcat(runArea "/netlistFooter")) fprintf(fout "\n") close(fout)
  fout = outfile(strcat(runArea "/netlistHeader")) fprintf(fout "\nsimulator lang=spectre\nglobal 0\n") close(fout)
  fout = outfile(strcat(runArea "/stimulus"))      
  fprintf(fout "vvctrl (vctrl 0) vsource dc=iiVCtrl type=dc\nvvref (vref 0) vsource dc=iiVRef type=dc\n") close(fout)
t));proc
