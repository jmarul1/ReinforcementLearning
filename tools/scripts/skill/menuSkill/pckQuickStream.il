;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Filename: pckQuickStream.il                   Project: TCC
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (C) Copyright Intel Corporation, 2006
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional description:
;;     Quick way to create a STREAM file from a layout
;;
;;
;; Revision History:
;;     02/20/2006 Bill Harris       Original.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (load "pckQuickStream.il")
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun pckQuickStreamGUI (@optional cv)

  (let (CellNameField defLib defCell defPath defStreamName
					  quickStreamForm LibNameField PathField StreamNameField )


	
	(unless cv (setq cv (geGetEditCellView)))

	defLib = cv~>libName
	defCell = cv~>cellName
	(setq defStreamName (strcat defCell ".gds"))
	(setq defPath (strcat (getShellEnvVar "FDK_WORK") "/pds/stream"))

	(setq  CellNameField
		   (hiCreateStringField
			?name		'CellNameField
			?prompt		"Cell Name:"
			?value      defCell
			?callback   "{ quickStreamForm->StreamNameField->value = streamNameCB( CellNameField->value) }"
			))

	(setq LibNameField (hiCreateStringField
						?name		'LibNameField
						?prompt		"Library Name:"
						?value      defLib
						))

	(setq PathField
		  (hiCreateStringField
		   ?name		'PathField
		   ?prompt		"Stream File Path:"
		   ?value      defPath
		   ))

	(setq StreamNameField
		  (hiCreateStringField
		   ?name		'StreamNameField
		   ?prompt		"Stream File Name:"
		   ?defValue   defStreamName
		   ?value      defStreamName
		   ))

	(setq quickStreamForm
		  (hiCreateAppForm
		   ?name		'quickStreamForm
		   ?fields		list('CellNameField
							 'LibNameField
							 'PathField
							 'StreamNameField
							 )
		   ?formTitle	"Quick STREAM File (pCells are OK)"
		   ?callback	"{ quickStreamCB( quickStreamForm) }"

		   ))
	(hiDisplayForm 'quickStreamForm )
	)
  )

;;
;; This is the main callback procedure:
;;
(defun quickStreamCB ( formHandle)
  (let ()
	(makeQuickStream 
	 formHandle->CellNameField->value  
	 formHandle->LibNameField->value 
	 formHandle->PathField->value 
	 formHandle->StreamNameField->value 
	 )  	
	)
 )

(defun streamNameCB (cellName)
  (strcat cellName ".stm")  
  )


(defun makeQuickStream (cellName libName path streamName)
  (let (runDir streamFileName stm1 ProcName )

	(setq ProcName "pckQuickStream")
	(setq runDir (strcat (getShellEnvVar "FDK_WORK") "/pds/stream"))
	(pckInfo ProcName (sprintf nil "\nStreaming out cell %s/%s\n" libName cellName ))
	(setq streamFileName (strcat path "/" streamName))
	(setq stm1 (pckStreamOut libName cellName "layout" runDir streamFileName )) 
	(pckInfo ProcName (sprintf nil "Stream File:\n%s\nCompleted ...\n" stm1))
	)
  )