;; get the parameters of the instance overlapping the box
procedure(derivePcellFromDRC(cv errN box)
let( (insts cdfs (csv gensym()) values params param paramVal)
  cdfs = foreach(mapcar inst setof(ii dbGetOverlaps(cv box nil 0) ii~>objType=="inst") cdfGetInstCDF(inst))
  params = setof(ii adListToSet(adFlattenList(cdfs~>parameters~>name)) ii)
  csv~>libName = list()  csv~>cellName = list()
  foreach(cdf cdfs
    putprop(csv cons(cdf~>id~>libName get(csv "libName")) "libName") putprop(csv cons(cdf~>id~>cellName get(csv "cellName")) "cellName") putprop(csv cons(errN get(csv "drc")) "drc")
    foreach(paramN params 
      param = cdfFindParamByName(cdf paramN) paramVal = if(param && type(param~>value)=='list  "NaN" adNum2Str(param~>value))
      values = if(member(stringToSymbol(paramN) csv~>?) cons(paramVal get(csv paramN)) list(paramVal)) 
      putprop(csv values paramN)	));foreach
csv))

;; read a csv with lib/cellName/error/box and create a new csv with instMasterLIB/CELL,error,parameters
procedure(pcellqaDrcReport(libName csv @optional (outD "."))
let( (boxes cv errN params csvStr dplE dplN fout cellName nowCell)
  outD = simplifyFilename(outD)  outD = adCreateTmpDir(?dir outD)  csv = adReadCsv(csv)
  foreach(line adZip(csv~>cellName csv~>box csv~>drc)
    errN = nth(2 line) boxes = parseString(nth(1 line) ";") cellName = nth(0 line) fout = sprintf(nil "%s/%s.csv" outD cellName)  dplN = list()
    when(nowCell != cellName 
      when(dbValidP(cv) dbClose(cv))
      cv = dbOpenCellViewByType(libName cellName "layout") nowCell = cellName ) ;when(noCell
    foreach(box boxes
      box = mapcar('evalstring parseString(box))
      dplN = cons(derivePcellFromDRC(cv errN box) dplN)  );foreach
    if(isFile(fout) then dplE = adReadCsv(fout) csvStr = adCsvFromDpls(cons(dplE dplN))
    else csvStr = adCsvFromDpls(dplN) ) ;; create a csvString from dpl        
    fout = outfile(sprintf(nil "%s/%s.csv" outD cellName)) fprintf(fout "%s" csvStr) close(fout)   
  );foreach
  when(dbValidP(cv) dbClose(cv))  
outD))
