procedure(adLoadPropBagFromCsv(lib cell csv tech)
let( (keys vals bag (props gensym()) )
  csv = adReadCsv(csv) tech = pcreReplace(pcreCompile("p") tech "" 1)
  unless(ddGetObj(lib cell) bag=dbOpenCellViewByType(lib cell "layout" "maskLayout" "w") dbSave(bag) dbPurge(bag))
  bag = dbOpenBag(ddGetObj(lib cell) "w")
  foreach(line adZip(csv~>parameter get(csv tech))
    vals = cadr(line)  keys = parseString(car(line) ".") 
    props = adCreateHierParam(props vals keys) )
  foreach(pp props->? adCreateHierBag(pp get(props pp) bag) );foreach
  dbSaveBag(bag) dbPurgeBag(bag)
t))

procedure(adCreateHierParam(props vals keys) ;hierarchival store for adReadPropBagCsv
if(length(keys) == 1 then putprop(props vals car(keys))
else  unless(get(props car(keys)) putprop(props gensym() car(keys)) ) adCreateHierParam(get(props car(keys)) vals cdr(keys)) )
props);proc

procedure(adCreateHierBag(propName propVal bag)
let( (newHierBag)
  propName = symbolToString(propName)
  if(stringp(propVal) then dbReplaceProp(bag propName "string" propVal)
  else newHierBag = dbReplaceHierProp(bag propName) foreach(ppName propVal->? adCreateHierBag(ppName get(propVal ppName) newHierBag) ) ) ; is list hierarchy
t))  
