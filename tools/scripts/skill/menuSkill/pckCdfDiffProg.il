;;=============================================================================== 
; File Name : CCScdfDiffProg.il 
; Date Created : 07-28-2005 
; Group : Custom IC, Cadence Design Systems Inc. 
; Language : SKILL 
; 
; Last Modified : 08-03-2005 
; Revision No. : 1 
; 
; Description : This code will list CDF parameters in columns 
; in an output file. This will allow easier viewing 
; for cell vs. cell comparison which is helpful for PDK or 
; techfile updates. 
; 
; How to Run : In the CIW, load this file CCScdfDiffProg.il: 
; (load (strcat PCK_SKILL_DIR "/1271/utils/pckCdfDiffProg.il"))
; and run - 
; (pckCdfDiffProg "testLib1" "cell1" "testLib2" "cell2" "/tmp/cell1.v.cell2.cdf.diff") 
; where testLib1 - library name 
; cell1 - cell1 name 
; testLib2 - library name 
; cell2 - cell2 name 
; /tmp/cell1.v.cell2.cdf.diff - output file with optional fullpath 
; 
; Tested in : IC5141 
; SKILL Lint Score (Max=100) : 100 
; No private functions are used. 
;=============================================================================== 

(defun pckCdfDiffProg (libname cellname libname2 cellname2 reportfile "ttttt") 
  (let (cell cell2 outPort cdfId1 cdfId2 cdfParamOnlyCell1 cdfParamOnlyCell2 found 
			 param2 position restOfList) 
	
	(setq cell (ddGetObj libname cellname)) 	
	(setq cell2 (ddGetObj libname2 cellname2)) 

	;; output port for report file 

	(setq  outPort (outfile reportfile)) 
	(fprintf outPort "CDF Diff Program: Cell vs. Cell\n") 			 
	(fprintf outPort "\n") 

	(CCSfprintParam outPort "Library:" libname libname2) 

	(CCSfprintParam outPort "Cell:" cellname cellname2) 
	(fprintf outPort "\n") 

	(setq cdfId1 (cdfGetBaseCellCDF cell)) 
	(setq cdfId2 (cdfGetBaseCellCDF cell2)) 

	(CCSfprintParam outPort "CDF Parameter" "Cell1" "Cell2") 
	(CCSfprintParam outPort "-------------" "----------------------------" "----------------------------") 
	(fprintf outPort "\n") 

	(setq restOfList cdfId2~>parameters) 

	(setq cdfParamOnlyCell1 (list))

	(foreach param cdfId1~>parameters
			 (setq  position
					(difference  (length cdfId2~>parameters~>name) 
						(length (member param~>name cdfId2~>parameters~>name)))) 
			 (setq found (nth position cdfId2~>parameters~>name)) 

			 (if found 

				 (progn
				   restOfList = setof(x restOfList x~>name != param~>name ) 
				   param2 = nth(position cdfId2~>parameters) 
				   (CCSfprintParam outPort "name" param~>name param2~>name) 
				   (CCSfprintParam outPort "prompt" param~>prompt param2~>prompt) 
				   (CCSfprintParam outPort "value" param~>value param2~>value) 
				   (CCSfprintParam outPort "defValue" param~>defValue param2~>defValue) 
				   (CCSfprintParam outPort "units" param~>units param2~>units) 
				   (CCSfprintParam outPort "type" param~>paramType param2~>paramType) 
				   (CCSfprintParam outPort "display" param~>display param2~>display) 
				   (CCSfprintParam outPort "editable" param~>editable param2~>editable) 
				   (CCSfprintParam outPort "dontSave" param~>dontSave param2~>dontSave) 
				   (CCSfprintParam outPort "storeDefault" param~>storeDefault param2~>storeDefault) 
				   (CCSfprintParam outPort "parseAsNumber" param~>parseAsNumber param2~>parseAsNumber) 
				   (CCSfprintParam outPort "parseAsCEL" param~>parseAsCEL param2~>parseAsCEL) 
				   (CCSfprintParam outPort "callback" param~>callback param2~>callback) 
				   fprintf(outPort "\n") 


				   )
			   (progn
				 (setq cdfParamOnlyCell1 (append cdfParamOnlyCell1 list(param) )))
			   )
			 
			 ) 

	(setq cdfParamOnlyCell2 restOfList) 

	(foreach param cdfParamOnlyCell1 
			 (CCSfprintParam outPort "name" param~>name "NOT FOUND") 			
			 (CCSfprintParam outPort "prompt" param~>prompt) 
			 (CCSfprintParam outPort "value" param~>value) 
			 (CCSfprintParam outPort "defValue" param~>defValue) 
			 (CCSfprintParam outPort "units" param~>units) 
			 (CCSfprintParam outPort "type" param~>paramType) 
			 (CCSfprintParam outPort "display" param~>display) 
			 (CCSfprintParam outPort "editable" param~>editable) 
			 (CCSfprintParam outPort "dontSave" param~>dontSave) 
			 (CCSfprintParam outPort "storeDefault" param~>storeDefault) 
			 (CCSfprintParam outPort "parseAsNumber" param~>parseAsNumber) 
			 (CCSfprintParam outPort "parseAsCEL" param~>parseAsCEL) 
			 (CCSfprintParam outPort "callback" param~>callback) 
			 (fprintf outPort "\n") 
			 ) 
	(foreach param cdfParamOnlyCell2 
			 (CCSfprintParam outPort "name" "NOT FOUND" param~>name) 
			 (CCSfprintParam outPort "prompt" "" param~>prompt) 
			 (CCSfprintParam outPort "value" "" param~>value) 			 
			 (CCSfprintParam outPort "defValue" "" param~>defValue) 
			 (CCSfprintParam outPort "units" "" param~>units) 
			 (CCSfprintParam outPort "type" "" param~>paramType) 
			 (CCSfprintParam outPort "display" "" param~>display) 
			 (CCSfprintParam outPort "editable" "" param~>editable) 
			 (CCSfprintParam outPort "dontSave" "" param~>dontSave) 
			 (CCSfprintParam outPort "storeDefault" "" param~>storeDefault) 
			 (CCSfprintParam outPort "parseAsNumber" "" param~>parseAsNumber) 
			 (CCSfprintParam outPort "parseAsCEL" "" param~>parseAsCEL) 
			 (CCSfprintParam outPort "callback" "" param~>callback) 
			 (fprintf outPort "\n") 
			 ) 

	(close outPort) 

	(printf "CCScdfDiffProg completed. Please see file: %s\n" reportfile) 

	)							;let 

  ) ; end 

(defun CCSintegerToString (val) 
  (let (stringval) 
	(sprintf stringval "%d" val) 
	)
  ) 
(defun CCSfloatToString (val) 
  (let (stringval) 
	  (sprintf stringval "%g" val) 
	  ) 
  ) 

(defun CCSfprintParam (outP param paramCell1 @optional (paramCell2 "")) 
  
  (when (integerp paramCell1) 
	(setq paramCell1 (CCSintegerToString paramCell1)) 
	) 

  (when (integerp paramCell2) 
	(setq paramCell2 (CCSintegerToString paramCell2)) 
		) 

  (when (floatp paramCell1) 
	(setq paramCell1 (CCSfloatToString paramCell1)) 
		) 

  (when (floatp paramCell2) 
	(setq paramCell2 (CCSfloatToString paramCell2)) 
	) 

  (fprintf outP "%-13s %-28s %-28s\n" param
		   (or paramCell1 "nil")
		   (or  paramCell2 "nil")) 
  )

