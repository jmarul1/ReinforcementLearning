#! /bin/csh -f
unalias *
set cellList = ()
if($#argv == 0) then
    echo "no command line arguments"
else
    @ argnum = 1
    while ($argnum <= $#argv)
        switch ($argv[$argnum])
            case -p:
                @ argnum++
                set process = $argv[$argnum]
                # Make sure process is only a number. The "p" will be added later when creating the  build path
                set process = `echo $argv[$argnum]| sed s/^p//`

            breaksw
            case -workPath:
                @ argnum++
                set workPath = $argv[$argnum]
            breaksw
            case -libPath:
                @ argnum++
                set buildPath = $argv[$argnum]
            breaksw
            case -l:
                @ argnum++
                set library = $argv[$argnum]
            breaksw

            case -c:
                @ argnum++
                set cellList = ($cellList $argv[$argnum])
            breaksw

            case -package:
                @ argnum++
                set package = $argv[$argnum]
            breaksw
        endsw
        @ argnum++
    end
endif


set root = $package:t:r
set curDir                = ${PWD}
#set buildPath             = ${curDir}/build/p${process}

#set workPath              = ${buildPath}/work

set pcell_load_file         = ${workPath}/loadPcell_${root}.il
set pcell_log_file         = ${workPath}/loadPcell_${root}.cds.log
set commonPath            = ${curDir}/../lib/skill/common


/bin/rm -f ${pcell_load_file}
# create replay file realtime including:
#      common
#      package context file
#      load_pacage.il
# start virtuoso  with replay 

### loading pcell File if exists
set pcellFile = ${curDir}/lib/pcell/${package}/fdkPcell_${root}.pc
if ( -e ${pcellFile}) then

    setenv DO_NOT_LOAD_LIBINIT 1
    #echo '(loadi (strcat (ddGetObjReadPath (ddGetObj "'${library}'")) "/libInit.il"))' >> ${pcell_load_file}

    # Load common files
    foreach commonFile ( ${commonPath}/*.il )
        echo '(load "'${commonFile}'")' >> ${pcell_load_file}
    end

    foreach pcell ( ${curDir}/lib/pcell/$package/*.il  ${pcellFile} )
        echo '(load "'${pcell}'")' >> ${pcell_load_file}
    end

    # create calls to top level pcell subroutine for each cell
    # This will assume that the top function name is the same as the file name
    foreach cell ($cellList)
        echo fdkPcell_"${root}("'"'${library}'" "'${cell}'")'  >> ${pcell_load_file}
    end
#    echo "exit()" >> ${pcell_load_file}


    ###
    echo "Loading Pcells load script <${pcell_load_file}> using virtuoso"
    setenv PRIM_SKILLPATH ${workPath}/lib.skill
    pushd ${workPath}
    \virtuoso -nocdsinit -nograph -replay ${pcell_load_file} -log $pcell_log_file
    $curDir/../build_scripts/check_cdslog_for_errors.rb $pcell_log_file
    exit $status
endif

