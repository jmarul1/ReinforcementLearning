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

procedure( fdkGetKorLibLst(libName @optional (tipo "fill"))
;; Go thru the entire library and return a dpl with fill FOR
let( (lst cv (dpl gensym()) )
  unless(ddGetObj(libName) error("Library does not exist"))
  foreach(cell ddGetObj(libName)~>cells
    when(and(member("layout" cell~>views~>name) cv=dbOpenCellViewByType(libName cell~>name "layout"))
      lst = setof(ii cv~>blockages ii~>type==tipo)~>layer
      lst = fdkListToSet(lst)
      when(lst putprop(dpl lst cell~>name))
      dbClose(cv) );when
  );foreach
dpl));proc

procedure( fdkQAKor(libName @key (fout "korQA.csv") (tipo "fill") (refKor "/p/fdk/gwa/jmarulan/fdk73/managed/fdk73/oalibs/common/custom/v2.9/templates_KORfill.txt"))
;; print into a file the QA for KOR
let( (korLayLst orgLst  expLayers korLays missing extra temp (line 0) (errLst list()))
  korLayLst = fdkGetKorLibLst(libName tipo) ; get the kor list 
  orgLst = fdkReadCsv(refKor ?delimeter "\t")  ; get the expected list
  expLayers = setof(jj foreach(mapcar ii orgLst~>? when(not(ii=='Category||ii=='Cell\ Name) lowerCase(ii))) jj)
  korLays = mapcar('symbolToString korLayLst~>?) 
  ; go for each cellName 
  foreach(cell orgLst~>Cell\ Name
    cell = buildString(parseString(cell))
    iiExpKors = setof(ii foreach(mapcar ll expLayers unless(blankstrp(nth(line get(orgLst ll))) ll)) ii);get the expected kors
    if(member(cell korLays) then     ;; find if the cell exists in the kor Lst
      missing = setof(ii iiExpKors !member(ii get(korLayLst cell)) )
      extra = setof(ii get(korLayLst cell) !member(ii iiExpKors))
      temp = buildString(list( (if missing buildString(missing " - ") "") (if extra buildString(extra " - ") "") ) ",")
      when(temp!="," errLst = append1(errLst strcat(cell "," temp)) )
    else errLst = append1(errLst strcat(cell "," buildString(iiExpKors " - ") ",")) );if
    line+=1    );foreach
  ;find  from korLayLst that are not in GOLDEN
  foreach(cell setof(ii korLays !member(ii orgLst~>Cell\ Name))
    errLst = append1(errLst strcat(cell ",," buildString(get(korLayLst cell) " - ")) ) )  
  fout = outfile(simplifyFilename(fout))
  if(errLst then fprintf(fout "cellName, MISSING in layout but in GOLDEN, EXTRA in layout but NOT in GOLDEN\n%s" buildString(errLst "\n") )
  else fprintf(fout "CLEAN") )
  close(fout)
t))
