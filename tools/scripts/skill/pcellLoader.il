procedure(loadIndPCell(libName cellPrefix @optional (techP "1222_2") );; load the pcell
let( (csv pcell cellName CT)
  csv = "/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/pcell/indPropBag.csv"
  pcell = "/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/pcell/mmindPcellPkg.ils"
  load(pcell)                                         ; load the callbacks and read property bag for defaults
  cellName = strcat(cellPrefix "2t") CT = nil
  adLoadPropBagFromCsv(libName cellName csv techP)    ; read property bag and load into cell
  load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/pcell/mmind.pc")          ; build pcell layout
  load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/pcell/mmind.cdf")         ; build the cdf
  cellName = strcat(cellPrefix "3t") CT = t
  adLoadPropBagFromCsv(libName cellName csv techP)    ; read property bag and load into cell  
  load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/pcell/mmind.pc")          ; build pcell layout
  load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/pcell/mmind.cdf")         ; build the cdf
  printf("\nMake sure to include the script below in \"libInit\" from \"library:%s\"\n%s\n" libName pcell)   ; print last instructions
t))
