;load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/cdsinit")

procedure( plotRfXtrCh(xtr freq nlegsRng wRng) ;string float floatRng floatRng
let( (runArea temp Gmax NFmin ft GmaxMinusNFmin plottingWin suf)
  runArea = adCreateTmpDir(?prefix "sim_")
  plottingWin = awvCreatePlotWindow() addTitle(sprintf(nil "freq=%LG" freq/1e9)) addSubwindow()
  foreach(nlegs nlegsRng
    foreach(ww wRng
      temp = processRfXtrCh(xtr freq nlegs ww runArea)
      suf = sprintf(nil "_%Lnl_%Lw" nlegs ww*1e9)
      Gmax = nth(0 temp) NFmin = nth(1 temp) ft = nth(2 temp) GmaxMinusNFmin = Gmax - NFmin
      awvSetCurrentSubwindow(plottingWin 1)
      plot(Gmax ?expr strcat("Gmax dB10" suf) ?strip 1)             plot(NFmin ?expr strcat("NFmin dB10" suf) ?strip 2)
      awvSetCurrentSubwindow(plottingWin 2)
      plot(GmaxMinusNFmin ?expr strcat("GMax-NFmin" suf) ?strip 1)  plot(ft ?expr strcat("ft" suf) ?strip 2)  
  ));foreach
  awvRemoveSubwindowTitle(plottingWin ?subwindow 1)  awvRemoveSubwindowTitle(plottingWin ?subwindow 2)
runArea))

procedure( processRfXtrCh(xtr frequency nlegs width runArea)  
let( (netlist biasFile ft Gmax_dB10 NFmin_dB10)
  createXtrNetlists(runArea xtr width nlegs)
  netlist = strcat(runArea "/netlist")
  biasFile = strcat(runArea "/stimulus")
  ; start simulation
  simulator( 'spectre )
  design(netlist)  resultsDir(runArea)
  modelFile('("$INTEL_RF/models/rf/spectre/be22/intel22rf.scs" "tttt") '("$INTEL_PDK/models/core/spectre/be2/p1222_2_var.scs" "tttt")) 
  stimulusFile(?xlate nil biasFile)   
  desVar("iiBias" 1)
  analysis('sp ?ports list("PORT1" "PORT2") ?freq sprintf(nil "%L" frequency) ?param "iiBias" ?start "0" ?stop "1" ?donoise "yes" ?oprobe "PORT2" ?iprobe "PORT1")
  envOption('analysisOrder  list("sp") )  temp(25) 
  run()
  ; calculations  
  Gmax_dB10 = db10(gmax(sp(1 1 ?result "sp") sp(1 2 ?result "sp") sp(2 1 ?result "sp") sp(2 2 ?result "sp")))
  NFmin_dB10 = db10(getData("Fmin" ?result "sp_noise"))
  ft = 50G*mag(hp(2 1 ?result "sp"))  
list(Gmax_dB10 NFmin_dB10 ft)
)); proc

procedure( createXtrNetlists(runArea xtr width nlegs)
let( (fout netlist uniq)
  uniq = sprintf(nil "/%s_%Lw_%Lnl_netlist" xtr width*1e9 nlegs)
  netlist = sprintf(nil "\n\
  mn0 (net1 net2 0 0) %s w=%L l=40n nf=%L multx=1 multy=1 stlen=1\n\
  L1 (vbias net1) inductor l=1\n\
  L0 (vbias net2) inductor l=1\n\
  PORT1 (net2 0) port r=50 type=sine\n\
  PORT2 (net1 0) port r=50 type=sine\n" xtr width nlegs)  
  fout = outfile(strcat(runArea uniq))             fprintf(fout netlist) close(fout)
  fout = outfile(strcat(runArea "/netlist"))       fprintf(fout netlist) close(fout)   
  fout = outfile(strcat(runArea "/netlistFooter")) fprintf(fout "\n") close(fout)
  fout = outfile(strcat(runArea "/netlistHeader")) fprintf(fout "\nsimulator lang=spectre\nglobal 0\n") close(fout)
  fout = outfile(strcat(runArea "/stimulus"))      fprintf(fout "vvbias (vbias 0) vsource dc=iiBias type=dc\n") close(fout)
t));proc
