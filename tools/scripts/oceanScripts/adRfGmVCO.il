;load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/cdsinit")
load "/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/oceanScripts/utils.il"

procedure( plotGmVCO(widthLst nlegsLst @key (csv simplifyFilename("vcoGm.csv"))) ;float floatRng floatRng floatRng floatRng
let( (runArea plottingWin gm suf line freqRng)
  runArea = "/nfs/pdx/disks/wict_wd/s22i/jmarulan/temp";
  runArea = adCreateTmpDir(?prefix "sim_")
  plottingWin = awvCreatePlotWindow() addTitle(sprintf(nil "gmVCO" )); addSubwindow()
  freqRng = list("1G" "100G") vbias = "0.5"
  foreach(ww widthLst
    foreach(nlegs nlegsLst
      gm = processGm(ww nlegs vbias freqRng runArea)
      suf = sprintf(nil "_%Lwth_%Lnlegs" ww*1e9 nlegs)
      awvSetCurrentSubwindow(plottingWin 1)
      plot(gm ?expr strcat("gm" suf) )
      ; create table
      foreach(data adWaveToList(gm)
        line = tconc(line sprintf(nil "%.2f,%d,%.2f,%.2f\n" ww*1e9 pcFix(nlegs) car(data)*1e-9 cadr(data)*1e3)) )
  ))
awvSetYAxisLabel(currentWindow() 1 "-gm")  
fout = outfile(csv)  fprintf(fout "width(nm),nlegs,freq(GHz),-gm(mS)\n%s" buildString(car(line) "")) close(fout)
runArea))

procedure( processGm(wth nlegs vbias freqRng runArea)  
let( (netlist gm biasFile)
  createGmNetlist(runArea)
  netlist = strcat(runArea "/netlist")  biasFile = strcat(runArea "/stimulus")
  ; start simulation
  simulator( 'spectre )
  hostMode('local)
  design(netlist)  resultsDir(runArea)
  modelFile('("$INTEL_RF/models/rf/spectre/be22/intel22rf.scs" "tttt") '("$INTEL_PDK/models/core/spectre/be2/p1222_2_var.scs" "tttt")) 
  stimulusFile(?xlate nil biasFile)   
  desVar("width" wth) desVar("nlegs" nlegs) desVar("vbias" vbias)
  analysis('sp ?ports list("gmPort") ?start car(freqRng) ?step "1G" ?stop cadr(freqRng) )
  envOption('analysisOrder  list("sp") )  temp(25) 
  run(); 
  ; calculations  
  gm = -1*real(yp(1 1 ?result "sp"))
)); proc

procedure( createGmNetlist(runArea)
let( (fout netlist uniq)
  uniq = sprintf(nil "/netlist_wth_nlegs")
  netlist = sprintf(nil "\n\
  mn1 (op on vss vss) b88nulrf w=width l=40n nf=nlegs multx=1 multy=1 stlen=1\n\
  mn0 (on op vss vss) b88nulrf w=width l=40n nf=nlegs multx=1 multy=1 stlen=1\n\
  K0  (sp vss op    vbias) transformer n1=2\n\
  K1  (sp vss vbias on   ) transformer n1=2\n\
  vvbias (vbias vss) vsource dc=vbias type=dc\n\
  vvss   (vss 0)     vsource dc=0\n\
  gmPort (sp vss) port r=50 type=sine\n")  
  fout = outfile(strcat(runArea uniq))             fprintf(fout netlist) close(fout)
  fout = outfile(strcat(runArea "/netlist"))       fprintf(fout netlist) close(fout)   
  fout = outfile(strcat(runArea "/netlistFooter")) fprintf(fout "\n") close(fout)
  fout = outfile(strcat(runArea "/netlistHeader")) fprintf(fout "\nsimulator lang=spectre\nglobal 0\n") close(fout)
  fout = outfile(strcat(runArea "/stimulus"))      fprintf(fout "** left blank on purpose") close(fout)
t));proc
