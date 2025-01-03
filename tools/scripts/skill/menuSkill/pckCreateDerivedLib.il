/****************************************************************************
 INTEL CONFIDENTIAL. COPYRIGHT © 2012, INTEL CORPORATION ALL RIGHTS RESERVED               
          
  UNAUTHORIZED REPRODUCTION/DISTRIBUTION OF PART OR ALL OF THIS CODE 
                          IS STRICTLY PROHIBITED                                    
*****************************************************************************

Author             : Ronald Kalim (ronald.kalim@intel.com>
Date               : Jan 14, 2012
Version            : 0.1  
Application        : Skill
Description        : Scripts to generate derive library
Return Value       : t/nil.
Bugs/Limitatiions  : Please report any issue to the author.
                     Make sure to run it on dbmenu terminal.
 		     DO NOT LOAD this file inside loader.il 
****************************************************************************/

(printf "PCK === creating derived libraries")

;;1.	Build Dfd, primtemplate, logic
;;2.	Build esd, idv
;;3.	Build tapeout
;;4.	Build tapeout_wrapper
;;5.	Build lvqa
;;
(pckCreateDotSpecificLib "dfd")
(pckCreateDotSpecificLib "primtemplate")
(pckCreateDotSpecificLib "logic")


(pckCreateDotSpecificLib "esd")
(pckCreateDotSpecificLib "idv")

(pckCreateDotSpecificLib "tapeout")
(pckCreateDotSpecificLib "tapeout_wrapper")
(pckCreateDotSpecificLib "lvqa")



(exit)


