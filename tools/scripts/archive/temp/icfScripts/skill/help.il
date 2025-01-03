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

procedure( myFuns(proc)
; Check Skill files in the general utils/scripts/SKILL Area
  let( (customSkillDir fileFullpath env fin line)
    env = getShellEnvVar("PROJECT")
    foreach(customSkillDir list("/p/fdk/gwa/jmarulan/utils/scripts/skill" strcat("/p/fdk/gwa/jmarulan/" env "/work/utils/scripts/skill") )
      when(and(isDir(customSkillDir) isReadable(customSkillDir))
        foreach( file setof(x getDirFiles(customSkillDir) equal(".il" index(x ".il")))
          sprintf(fileFullpath "%s/%s" customSkillDir file)
          when( isReadable(fileFullpath)
            fin = infile(fileFullpath)
	    while(gets(line fin)
	      line = buildString(parseString(line))
	      when(pcreMatchp(strcat("procedure\\(\\s*(\\w*" proc "\\w*\\(.*)") line 0x00000001) printf("%s\n" pcreSubstitute("\\1")) ); when
	    );while
	    close(fin)	
          ) ; when
        ) ; foreach
      ) ; when
    ) ;foreach
    t
  ); let
);procedure
