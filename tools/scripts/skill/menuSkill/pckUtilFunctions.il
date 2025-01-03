;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Filename: pckUtilFunctions.il             Project: TCC
;; 
;;  Version: $Id: pckUtilFunctions.il.rca 1.1 Fri Dec 10 15:47:47 2010 pvrott Experimental $
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Copyright Intel Corporation 2004
;;
;; Author: Pavel Rott
;; Keywords: TC Project; Utility Functions
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional Description:
;;
;; Miscelaneous functions
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; load "/prj/tcc/utils/skill/pckUtilFunctions.il"
;;
;;
/*
                  CIW: history

                  This will output a numbered list of the previous Skill
                  commands. To change the number of commands use:
                        CIW: skillHistoryLength =  20  
                  The output of a history command looks like this:
                        ...
                          1  dmSetDefaultAccess( list( "read" "write" "delete") 
                           list( "read" "write" ) list( "read" ) nil ) 
                          2  dmFindLib("myLib")
                          3  (x=5)
                          4  println("hello world")
                          5  hiFormDone(dmbLibPathForm)
                          6  dmbOpenLibBrowser()

                  CIW: !4
                  This will re-execute the fourth command entered after 
                  loading skillHistory.il. The world will be notified of your
                  selection.

                  CIW: !dmF
                  This will re-execute the last command typed into the CIW 
                  that started with "dmF"--in this case it will re-execute
                  the dmFindLib("myLib") command.

        Known Bugs (John Gianni):
        One bug is that if you load the skill history file 3 times, it
        repeats each command 3 times when you type in the history command. 

        Another unexpected feature is the fact that all Skill commands
        (even those entered by the graphical interface) are placed in the
        history list.

        See also PCR 99541 (John Gianni) and PCR 72947 (Ranganathan Ramaswamy)
        for details.        

        If you enhance this skillHistory.il program, please append your 
        additions to the appropriate PCR listed above.
*/
; BEGIN SkillHistory.il
(procedure (skillInitHistory)
		   setq( skillHistoryList     nil )
		   setq( skillHistoryCounter  1   )
		   setq( skillHistoryLength   50  )
		   (regBeforeCall 'skillBeforeProc)
		   )

(defun hist (@optional length)
  "This will output a numbered list of the previous Skill commands. To change the number of commands use:
                        CIW: skillHistoryLength =  20 => l_list"
  (let (tmp)
			 (when length
			   (setq skillHistoryLength length)
			   )
			 (setq tmp (reverse skillHistoryList) )

			 (when (length skillHistoryList ) > skillHistoryLength
				   (setq tmp (nthcdr (difference (length tmp ) skillHistoryLength) tmp))
				   )

			 (foreach item tmp
					  (printf "%4d %s\n" (car item) (skilliCallListToString (cadr item)))
					  )
			 t
			 )
		   )

(procedure (skilliCallListToString calls )
		   (let ( ( string "" ) )
			 (if (listp calls ) then
			   (foreach call calls
						(sprintf string "%s%L " string call )
						)
			   else
			   (sprintf string "%s" calls )
			   )
			 string
			 )
		   )

procedure( skillBeforeProc( listOfCalls )
						  (let ( arg from to tmp
									 ( firstCall car( listOfCalls ) )
									 )
							when( listp( firstCall )
									   caseq( car( firstCall )
												 ( null
												   arg = cadr( firstCall )
												   caseq( type( arg )
															  ( fixnum
																listOfCalls = cadr( assq( arg skillHistoryList ) ) )
															  ( symbol
																tmp = car(
																		  exists( x skillHistoryList
																					aelRegex( strcat( "^(*" arg ) ;)
																									list( skilliCallListToString( cadr(x) ) )
																									)
																					)
																		  )
																if( tmp then
																		listOfCalls = cadr( tmp ) 
																		else
																		listOfCalls = list( nil )
																		) )
															  )
												   printf( "%s\n" skilliCallListToString( listOfCalls ) )
												   )
												 ( bxor
												   from = get_string( cadr( firstCall ) )
												   to   = get_string( caddr( firstCall ) )
												   listOfCalls = cadar( skillHistoryList )
												   sprintf( tmp "%L" listOfCalls )
												   tmp = parseString( tmp from )
												   tmp = buildString( tmp to   )
												   listOfCalls = car( linereadstring( tmp ) )
												   printf( "%s\n" skilliCallListToString( listOfCalls ) )
												   )
												 )
									   )

     ;;; add calls to history list
							skillHistoryList = cons( list( skillHistoryCounter++ listOfCalls )
														 skillHistoryList )
							listOfCalls
							)
						  )

skillInitHistory()
;; End of skillHistory.il




;;; pckUtilFunctions.il ends here
