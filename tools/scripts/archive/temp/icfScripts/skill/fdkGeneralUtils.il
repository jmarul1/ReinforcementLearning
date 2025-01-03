;##############################################################################
;# Intel Top Secret                                                           #
;##############################################################################
;# Copyright (C) 2015, Intel Corporation.  All rights reserved.               #
;#                                                                            #
;# This is the property of Intel Corporation and may only be utilized         #
;# pursuant to a written Restricted Use Nondisclosure Agreement               #
;# with Intel Corporation.  It may not be used, reproduced, or                #
;# disclosed to others except in accordance with the terms and                #
;# conditions of such agreement.                                              #
;#                                                                            #
;# All products, processes, computer systems, dates, and figures              #
;# specified are preliminary based on current expectations, and are           #
;# subject to change without notice.                                          #
;##############################################################################
;# Author:
;#   Mauricio Marulanda
;##############################################################################

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

/*---------------------------------------------------------------------------
 procedure: fdkZip
 Created by Mauricio Marulanda
 Purpose: Creates an n_list(rows) of m_lists 
          each element in the output n_list has the nrow_th element of each of the m_lists (Maximum list input = 10)
 ---------------------------------------------------------------------------*/
procedure( fdkZip(lst1 @optional (lst2 nil) (lst3 nil) (lst4 nil) (lst5 nil) (lst6 nil) (lst7 nil) (lst8 nil) (lst9 nil) (lst10 nil))
let( (effLst (len length(lst1)) (newLst list()) )
  ; handle lst1 having sublist (support for indefinate number as long as they are in the first list)
  if(and(!lst2 type(car(lst1))=='list) then effLst=lst1  len=length(car(effLst))
  else effLst = setof(ii list(lst1 lst2 lst3 lst4 lst5 lst6 lst7 lst8 lst9 lst10) ii!=nil) )
  ;input checks
  unless(effLst error("Provide at least one list")) 
  foreach(ii effLst when(len!=length(ii) error("List must be the same length in fdkZip")) )
  ;run for all list extracting the nth element
  for(iiRow 0 len-1 newLst=append1(newLst foreach(mapcar lst effLst nth(iiRow lst)) )  )
newLst)) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkMakeDir
 Created by Mauricio Marulanda
 Purpose: Creates a directory with the path specified, can be relative (according to cadence) or absolute,
          if it already exists creates <pathGiven>_copy#.
          Return the path that was used
 ---------------------------------------------------------------------------*/
procedure( fdkMakeDir(pathGiven)
  let( ( (success nil) (counter 1) (maxCopyNum 10) effectivePath)
    effectivePath = pathGiven
    while( !success && counter <= maxCopyNum
      if(createDir(effectivePath) then
        success = 1 
      else
        effectivePath = strcat(pathGiven sprintf(nil "_copy%d" counter) )
      )
      counter++
    ) ; while
    unless(success error("Could not create Directory, too many copies") )
    effectivePath ; if the path that was used
  ) ; let
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkRmPath
 Created by Mauricio Marulanda
 Purpose: Removes the file or directory completely 
 ---------------------------------------------------------------------------*/
procedure( fdkRmPath(pathGiven)
  when(isDir(pathGiven) || isFile(pathGiven)
    sh(strcat("rm -r " pathGiven)) )
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkNum2Str
 Created by Mauricio Marulanda
 Purpose: Converts a number to string, if the input is not a number it returns the value unchanged.
          A precision of 6 is the default value, if not specified or specified wrongly (must be a digit).
 ---------------------------------------------------------------------------*/
procedure( fdkNum2Str(numberGiven @optional (precision 6) )
  let( ()
    if(numberp(precision) then
      sprintf(precision "%d" fix(precision)) 
    else 
      sprintf(precision "%d" fix(6))
    ) ; if
    case(type(numberGiven)
      ('fixnum sprintf(numberGiven "%d" numberGiven))
      ('flonum sprintf(numberGiven strcat("%." precision "f") float(numberGiven)))
      (t numberGiven)
    ) ; case
    when(rexMatchp("[0-9]*\\." numberGiven )
      while(rexMatchp("0$" numberGiven) numberGiven = rexReplace(numberGiven "" 1)) ; while to remove extra "0s"
      when(rexMatchp("\\.$" numberGiven) numberGiven = rexReplace(numberGiven "" 1) ) ; when to make integer for ".0"
    ) ; when
    numberGiven
  )
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkListBBox
 Created by Mauricio Marulanda
 Purpose: Returns the four coordinates of the bounding box clockwise.
 ---------------------------------------------------------------------------*/
procedure( fdkListBBox(bBoxGiven)
  let( (leftBotX leftBotY rightTopX rightTopY)
    leftBotX = caar(bBoxGiven)
    leftBotY = cadar(bBoxGiven)
    rightTopX = caadr(bBoxGiven)
    rightTopY = cadadr(bBoxGiven)
    list(list(leftBotX leftBotY) list(leftBotX rightTopY) list(rightTopX rightTopY) list(rightTopX leftBotY) )
  )
) ; procedure

/*---------------------------------------------------------------------------
 proc: fdkCountElem
 Created by Mauricio Marulanda
 Purpose: Returns number of times element in the list 
 ---------------------------------------------------------------------------*/

procedure( fdkCountElem(elem lst)
let( ((cc 0))
  foreach(ii lst when(ii==elem cc++))
cc ))

/*---------------------------------------------------------------------------
 procedure: oalibs
 Created by Mauricio Marulanda
 Purpose: Returns the number of elements in a list
 ---------------------------------------------------------------------------*/
procedure( oalibs()
  case(getShellEnvVar("PROJECT")
  ("fdk73" ddGetObj("intel73custom")~>readPath)
  ("f1275" ddGetObj("intel75custom")~>readPath)
  ("f1222" ddGetObj("intel22custom")~>readPath))
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkCompFloatNum
 Purpose: Compares two floating numbers, tolerance if not given is 1e-12. If inputs are not numbers, nil is return
 ---------------------------------------------------------------------------*/
procedure(fdkCompFloatNums(fNum1 fNum2 @optional (tolGiven 1e-12) )
  let( ( (result nil) )
    when(and(numberp(fNum1) numberp(fNum2) abs(fNum1-fNum2) < tolGiven) result=t) 
    result
)); procedure

/*---------------------------------------------------------------------------
 procedure: fdkReadCsv
 Purpose: Reads the csv into a de-embodied file using the first text line as the headers, takes string or files
 ---------------------------------------------------------------------------*/
procedure(fdkReadCsv(filePath @key (string nil) (delimeter ","))
let( (fin line values (first t) (dict gensym()) headers effHeaders key effVal feedNext (cc 0) rep)
  unless(or(string isFile(filePath)) error("File path does not exist"))
  fin = (if string parseString(filePath "\n") infile(filePath))
  feedNext = lambda( (feeder ii) (if string (if ii<length(feeder) nth(ii feeder) nil) gets(line feeder)) )
  while(line=apply(feedNext list(fin cc)) ;gets(line fin)
    unless(pcreMatchp("^\\s*#|^\\s*$" line) ;skip blanklines or beginning with #
    rexCompile(delimeter) line=rexReplace(line strcat(" " delimeter " ") -1) ;add spaces to every comma to allow empty strings
    line = car(parseString(line "#")) ; throw comments after #
    values = mapcar('lambda((x) buildString(parseString(x))) parseString(line delimeter)) ;remove head/tail blanks
    if(first then first=nil ;store the headers
      rexCompile("\"")   headers=list()  effHeaders=list()
      when(blankstrp(car(last(values))) values = reverse(cdr(reverse(values))) ) ;remove the last entry if its empty     
      foreach(jj values 
        headers=append1(headers rexReplace(jj "" -1))  rep=(if (rep=fdkNum2Str(fdkCountElem(jj headers)))=="1" "" strcat("#" rep))
        jj=strcat(car(last(headers)) rep) effHeaders=append1(effHeaders jj) putprop(dict list() jj) );foreach
    else ;put in each header
      for(jj 0 length(effHeaders)-1
        key = nth(jj effHeaders)   
	effVal = (if jj<length(values) nth(jj values) "") ;if line has less values than headers, for more just dont put them
        putprop(dict append1(get(dict key) effVal) key) ) ;for
    );if
  ) cc++ );unless ;while
dict )); procedure

/*---------------------------------------------------------------------------
 procedure: fdkListToSet
 Purpose: Create a list without duplicate values
 ---------------------------------------------------------------------------*/
procedure(fdkListToSet(t_list)
let( ((newList list()))
  when(type(t_list) != 'list error(sprintf(nil "Input is not a list: %L" t_list)))
  foreach(ii t_list
    unless(member(ii newList) newList = append1(newList ii))
  );when
newList  
));procedure

;Calculate the density for all layers in the current cell
procedure( fdkCalcDensity(cv)
let( (layers area totalArea getArea tmpStr (outStr "") effList)
  getArea = lambda((bBox) (rightEdge(bBox) - leftEdge(bBox))*(topEdge(bBox) - bottomEdge(bBox)) )
  printf("Reading all the shapes\n...\n")
  effList = setof(ii cv~>shapes cadr(ii~>lpp) == "drawing")
  layers = fdkListToSet(effList~>layerName)
  printf("REPORT:\n")
  foreach(layer layers 
    area = fdkGetRectArea(cv~>shapes layer)
    totalArea = apply(getArea list((if cv~>prBoundary~>bBox cv~>bBox)) )
    tmpStr = sprintf(nil "%s,(area;%%) = (%s , %s%%)\n" layer fdkNum2Str(area 3) fdkNum2Str(100*area/totalArea 3))
    printf("%s" tmpStr)    
    outStr = strcat(outStr tmpStr)    
  );foreach
  printf("END\n\n")
outStr));

/*----------------------------------------------------------------------------
 procedure: fdkGetWH
 purpose: get the width and heigth of a cell based on the bBox
 ---------------------------------------------------------------------------*/
procedure( fdkGetWH(bBox)
let( (width height)
width = rightEdge(bBox) - leftEdge(bBox)
height = topEdge(bBox) - bottomEdge(bBox)
list(width height)
));let procedure

/*----------------------------------------------------------------------------
 procedure: fdkCCSFindTopCellsInLib
 purpose: get the width and heigth of a cell based on the bBox
 ---------------------------------------------------------------------------*/
procedure( fdkCCSFindTopCellsInLib(libName @key (viewName "layout") "tt")
let( (myCellList nonTopCellsList) 
  unless(member(libName	ddGetLibList()~>name)  error("Please pass a valid library name") )
  foreach(cell ddGetObj(libName)~>cells
    if( car(CCSIsCellWithHier(cell viewName))	then
      myCellList = cons(cell~>name myCellList)
      nonTopCellsList = append(nonTopCellsList	cadr(CCSIsCellWithHier(cell viewName)))
  ));if ;foreach 
  setof(cell myCellList !member(cell nonTopCellsList))
)); let proc

procedure( CCSIsCellWithHier(cellId view)
    prog( (cvId flag nonTopCellList)
	if( member(view 
	    ((cellId~>views)~>name)
	)
	    then
	    case( view
		("layout"
		    (cvId = dbOpenCellViewByType(((cellId~>lib)~>name) 
			    (cellId~>name) view "maskLayout" "r"
			))
		    when(cvId 
			if( (cvId~>instances)
			    then
			    if( member(((cellId~>lib)~>name) 
				((cvId~>instances)~>libName)
			    )
				then
				(flag = t)
				(nonTopCellList = (setof(inst 
					    (cvId~>instances) 
					    ((inst~>libName) == ((cellId~>lib)~>name))
					)~>cellName))
				return(list(flag nonTopCellList))
				else
				(flag = nil)
				return(list(flag nil))
			    )
			    else
			    (flag = t)
			    return(list(flag nil))
			) 
			dbPurge(cvId)
		    ))
		("schematic"
		    (cvId = dbOpenCellViewByType(((cellId~>lib)~>name) 
			    (cellId~>name) view "schematic" "r"
			))
		    when(cvId 
			if( (cvId~>instances)
			    then
			    if( member(((cellId~>lib)~>name) 
				((cvId~>instances)~>libName)
			    )
				then
				(flag = t)
				(nonTopCellList = (setof(inst 
					    (cvId~>instances) 
					    ((inst~>libName) == ((cellId~>lib)~>name))
					)~>cellName))
				return(list(flag nonTopCellList))
				else
				(flag = nil)
				return(list(flag nil))
			    )
			    else
			    (flag = t)
			    return(list(flag nil))
			) 
			dbPurge(cvId)
		    ))
		(t
		    error("unexpected view provided"))
	    )
	)
    )
)

procedure( fdkGetProject()
if(pcreMatchp("(71|73|75)" getShellEnvVar("PROJECT")) then pcreSubstitute("\\1")
else error("No PROJECT environment variable") )
);let procedure

procedure( fdkFlattenList(lista @optional (flatLst list()))
if(type(lista) == 'list then
  foreach(ll lista flatLst=fdkFlattenList(ll flatLst))
else flatLst = append1(flatLst lista))
flatLst)

procedure( fdkRemoveLast(lst)
let( (effLen (y 0))
  effLen = length(lst)
setof(ii lst ++y < effLen) ));proc

procedure( fdkGetSourceVersion(libName)
let( (lst outf src)
  outf = outfile(simplifyFilename("versionOut.csv"))
  fprintf(outf "cellName,version\n")
  foreach(ii ddGetObj(libName)~>cells
    cv = dbOpenCellViewByType(libName ii~>name "layout")
    when(cv
      src = or(cv~>sourceId cv~>sourceID cv~>sourceid)
      fprintf(outf "%s,%L\n" ii~>name src)
      dbPurge(cv))
  )
  close(outf)
t))

