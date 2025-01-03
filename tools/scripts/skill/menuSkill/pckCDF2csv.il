
;; SKILL script to parse a CDF file into a comma delimited text file for Excel spreadsheet

;; load "tcc_collateral/core/skill/pckCDF2csv.il"


(defun getCDF ( libname cellname)
(let (cv outfp outfname )

    (setq cv (dbOpenCellViewByType libname cellname "layout"))
	outfname = cellname
    outfname = strcat( "~/" outfname ".csv")
    
    sh(strcat("rm  -f " outfname))

    outfp = outfile(outfname "w")

    fprintf( outfp "Name\tPrompt\tDefault Value\n")
		
    (foreach param  cv~>parameters~>value 
         fprintf( outfp "%s\t%s\t%L\n" param~>name param~>name param~>value )
    )

    close( outfp)

    view( outfname )

    printf("CDF data saved in %s\n" outfname )
)
)


/*********************************************************************
NOTE: This assumes the CDF definitions are in the following format:

 cdfCreateParam cdfId
				?name           yourCDFName
				?prompt         your CDF prompt
				?defValue       your default value or expression
                ?callback       your callback function

This is a QUICK and DIRTY program to use to make Excel's of your
CDF's for Shahriar (or whomever)

**********************************************************************/

procedure( getCDF_old( infname)
let(  
  
	(line lb ll commentSign infp itemList keyWord 
     outfp outfname cdfName cdfPrompt cdfDefVal cdfCB
    )

	outfname = rindex(infname "/")
    ll = nindex(outfname ".il")
	outfname = substring( outfname 1 (ll-1))
    outfname = strcat( "~/" outfname ".csv")
    
    infp = infile(infname)

    if( (infp == nil) then
        printf("ERROR: cannot open input file %s\n" infname)
    else

        sh(strcat("rm  -f " outfname))

	    outfp = outfile(outfname "w")

	    fprintf( outfp "Name,Prompt,Default Value,Callback\n")
		
	)
    if( (infp != nil) then

        cdfName = nil
        cdfCB = ""

        while( (gets( line infp) != nil)
       
			;;printf("Line %d -> %s" nLine line)

			commentSign = nindex( line ";")
            if( (commentSign != nil)
			then
				line = substring(line 1 (commentSign - 1))
			)

	        ;; Now back to the original code.  Kept the same but if condition now redundant!

			itemList = parseString( line " \t\n\15")
			ll = length(itemList)
			keyWord   = nth(0 itemList)

		    if( (keyWord == "?name") then 
				if( (cdfName != nil) then
				    fprintf( outfp "%s,%s,%s,%s\n" cdfName cdfPrompt cdfDefVal cdfCB)
				)
				cdfName = nth(1 itemList)
                cdfCB = ""
                		    
			)
		    if( (keyWord == "?prompt") then 

				lb = nindex(line nth(1 itemList))
				ll = strlen(line)
                
				cdfPrompt = substring( line lb (ll-lb))
                		    
			)
		    if( (keyWord == "?defValue") then 
				lb = nindex(line nth(1 itemList))
				ll = strlen(line)
                
				cdfDefVal = substring( line lb (ll-lb))

;;				fprintf( outfp "%s,%s,%s\n" cdfName cdfPrompt cdfDefVal)
                		    
			)
		    if( (keyWord == "?callback") then 
				lb = nindex(line nth(1 itemList))
				ll = strlen(line)
                
				cdfCB = substring( line lb (ll-lb))
			)

		); file read loop

		;; Save the last CDF values:
		if( (cdfName != nil) then
			fprintf( outfp "%s,%s,%s,%s\n" cdfName cdfPrompt cdfDefVal cdfCB)
		)

        close( infp)
        close( outfp)

		view( outfname )

	    printf("CDF data saved in %s\n" outfname )

	); file opened OK

); let
); procedure