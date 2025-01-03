#! /bin/csh -f
unalias *

set cellList = ()

if($#argv == 0) then
    echo "no command line arguments"
    goto HELP_MESSAGE
else
    @ argnum = 1
    while ($argnum <= $#argv)
        switch ($argv[$argnum])
            case -h*:
                goto HELP_MESSAGE
            breaksw
            case -p:
                @ argnum++
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

            default:
                set cdfFile = $argv[$argnum]
            breaksw

        endsw
        @ argnum++
    end
endif

set fileRoot = $cdfFile:r:t

set curDir                = ${PWD}
set buildPath             = ${curDir}/build/p${process}

#set workPath              = ${buildPath}/work

set cdf_load_file         = ${workPath}/loadCdf_${fileRoot}.il
set cdf_log_file          = ${workPath}/loadCdf_${fileRoot}.cds.log
set commonPath            = ${curDir}/../lib/skill/common


if(! -e $cdfFile) then
    echo "-E- Error: CDF file not found ($cdfFile)"
    exit 1 
endif
set cdfFile = `realpath $cdfFile`

if(-e $cdf_load_file) then
    /bin/rm -f $cdf_load_file
endif

### 

setenv DO_NOT_LOAD_LIBINIT 1
;echo '(loadi (strcat (ddGetObjReadPath (ddGetObj "'${library}'")) "/libInit.il"))' >> ${cdf_load_file} 

# need this to get cdf* functions in dbAccess.
echo '(loadContext "'${CDSHOME}'/tools/dfII/etc/context/cdf.cxt")' >> ${cdf_load_file}
# Load common files
foreach commonFile ( ${commonPath}/*.il )
    echo '(load "'${commonFile}'")' >> ${cdf_load_file}
end


### loading cdf File if exists
if ( -e $cdfFile) then

    echo '(load "'${cdfFile}'")' >> ${cdf_load_file}

    # create calls to top level CDF subroutine for each cell
    # This will assume that the top function name is the same as the file name
    set cdfName = $cdfFile:t:r
    foreach cell ($cellList)
        echo "${cdfName}("'"'${library}'" "'${cell}'")'  >> ${cdf_load_file}
    end
    echo "exit()" >> ${cdf_load_file}


    ###
    echo "Loading CDF load script <${cdf_load_file}> using dbAccess"
    setenv PRIM_SKILLPATH ${workPath}/lib.skill
    pushd ${workPath}
#    \virtuoso -nocdsinit -nographE -replay ${cdf_load_file} -log $cdf_log_file
    dbAccess -load  ${cdf_load_file} >! $cdf_log_file
    $curDir/../build_scripts/check_cdslog_for_errors.rb $cdf_log_file
    exit $status
endif

exit

HELP_MESSAGE:

    echo "SYNTAX: $0:t [-h] -p <#> -l <library> {-c <cell> ...} <file.cdf>"
    echo "    -p <#>          Process Number "
    echo "    -l <library>    Name of library to build CDF"
    echo "    -workPath <path>    Name of work path"
    echo "    -libPath  <path>    Name of library path"
    echo "    -c <cell> ...   Name of cell for CDF build"
    echo "                      Example:  -c n -c p  -c ntg -c ptg "
    echo "    <file.cdf>      CDF File"
    echo ""
    echo "Example:"
    echo "     $0:t -p 4 -l fdk73prim -workPath ./build/work -libPath ./build/lib -c n -c p cdf.skill/mos/fdkCdf_mos.cdf"
    echo ""
    exit 0
