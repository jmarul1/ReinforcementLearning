#! /bin/csh -f
unalias *

set CP_CMD='/bin/cp '
set MD_CMD='/bin/mkdir '
set RD_CMD='/bin/rm '
set CM_CMD='/bin/chmod '
set LS_CMD='/bin/ls '
set CP_CMD_OPTS=' -rL '
set RD_CMD_OPTS=' -rf '
set CM_CMD_OPTS=' -R '
set script=$0:t
set oalibPath = `realpath  $cwd/..`

set curDir                = ${PWD}
set tclcompiler=/p/fdk/eda/activestate/ActiveTDK/5.3.0/bin/tclcompiler84
set getlicense=/p/fdk/eda/activestate/ActiveTDK/license-linux-x86_64
set bypassactivestate=0
set sourcePath=""
set nocompile = 0
set clean = 0
set help = 0
set lib = ""
set logPath = ""
set process = ""
set mystatus = 0

if($#argv == 0) then
    echo "-E- $script--No command line arguments"
    set mystatus=1
    goto HELP
else
    @ argnum = 1
    while ($argnum <= $#argv)
        switch ($argv[$argnum])
            case -p:
                @ argnum++
                # Make sure process is only a number. The "p" will be added later when creating the  build path
                set process = `echo $argv[$argnum]| sed s/^p//`
            breaksw
            case -libPath:
                @ argnum++
                set buildPath = $argv[$argnum]
            breaksw
            case -workPath:
                @ argnum++
                set workPath = $argv[$argnum]
            breaksw
            case -l:
                @ argnum++
                set lib = $argv[$argnum]
            breaksw
            case -log:
                @ argnum++
                set logPath = $argv[$argnum]
            breaksw
            case -nocompile:
                set nocompile = 1
            breaksw

            case -clean:
                set clean = 1
            breaksw

            case -test:
                set test = 1
            breaksw

            case -h*:
                set help = 1
            breaksw
            
            default:
                set sourcePath = $argv[$argnum]
            breaksw
        endsw
        @ argnum++
    end
endif
# do help right away
if ( $help == 1) then
    goto HELP
endif
echo "-------------------"
echo "-I- Compiling TCL: $sourcePath"
echo "-------------------"

#log path must exist
if ($logPath != "") then
    if (! -e $logPath:h) then
        echo "-E- $script--The logPath directory (from -log) does not exist.  This must exist: $logPath:h"
        set mystatus=5
        exit $mystatus
    endif 
endif

#from here on out, start a log 
if ($logPath != "") then
    echo "-I- $script--start...">>&$logPath
else
    echo "-I- $script--start..."
endif
if ($sourcePath == "") then
    set msg="-E- $script--The sourcePath was not specified"
    if ($logPath != "") then
        echo "$msg" >>& $logPath
    else
        echo "$msg"
    endif
    set mystatus=6
    goto HELP
endif
if (! -e $sourcePath) then
    set msg="-E- $script--Non-existant sourcePath:$sourcePath"
    if ($logPath != "") then
        echo "$msg" >>& $logPath
    else
        echo "$msg"
    endif
    set mystatus=2
    goto HELP
endif
if ( process == "") then
    set msg="-E- $script--No -p option. Need process!"
    if ($logPath != "") then
        echo "$msg" >>& $logPath
    else
        echo "$msg"
    endif
    set mystatus=3
    goto HELP
endif
if ( lib == "") then
    set msg="-E- $script--No -l option. Need library!"
    if ($logPath != "") then
        echo "$msg" >>& $logPath
    else
        echo "$msg"
    endif
    set mystatus=4
    goto HELP
endif
#set buildPath             = ${curDir}/build/p${process}
set libPath              = ${buildPath}/${lib}
set targetPath           = ${libPath}/lib_tcl.dir
#set workPath              = ${buildPath}/work

#build process dir if it doesn't exist
if (! -e $buildPath) then
  $MD_CMD $buildPath
endif 
#build lib path if it doesn't exist
if (! -e $libPath) then
  $MD_CMD $libPath
endif 
#build target path if it doesn't exist or clean if requested
if (! -e $targetPath) then
  $MD_CMD $targetPath
else
    if ($clean == 1) then
        $RD_CMD $RD_CMD_OPTS $targetPath
        $MD_CMD $targetPath
    endif
endif 
#build work path if it doesn't exist
if (! -e $workPath) then
  $MD_CMD $targetPath
endif 
#copy the tcl not in compile if there is any. if none, send msg to dev/null
$CP_CMD $CP_CMD_OPTS $sourcePath/*.tcl $targetPath/ >& /dev/null
#$CP_CMD $CP_CMD_OPTS ../lib/tcl/common/compile/*.tcl $targetPath/ >& /dev/null

#run tclcompiler or copy
if ($nocompile == 0) then
    set returnString=`$getlicense`
    set mystatus = $status
    if($mystatus != 0) then
        set msg= "-E- $script--$getlicense |$mystatus| $returnString"
        if ($logPath != "") then
            echo "$msg" >>& $logPath
        else
            echo "$msg"
        endif
        exit $mystatus
    endif
    set nullString=`echo $returnString | grep -v "successfully"`
    if ($nullString != "") then
        set msg= "-E- $script--$getlicense -- $returnString"
        if ($logPath != "") then
            echo "$msg" >>& $logPath
        else
            echo "$msg"
        endif
        exit $returnString
    endif
    if ($logPath == "") then
        $tclcompiler ${sourcePath}/compile/*.tcl -out $targetPath/.
    else
        $tclcompiler ${sourcePath}/compile/*.tcl -out $targetPath/. >>& $logPath
    endif
    set mystatus = $status
    if($mystatus != 0) then
        set msg= "-E- $script--$tclcompiler |$mystatus|"
        if ($logPath == "") then
            echo "$msg" >>& $logPath
        else
            echo "$msg"
        endif
        exit $mystatus
    endif
else
    $CP_CMD $CP_CMD_OPTS ${sourcePath}/compile/*.tcl $targetPath/
    #$CP_CMD $CP_CMD_OPTS ../lib/tcl/common/compile/*.tcl $targetPath/
endif
$CM_CMD $CM_CMD_OPTS 0770 $targetPath
        
set mystatus = $status
if ($mystatus == 0) then
    set msg="-I- $script--Built tcl in library $lib at $targetPath"
    if ($logPath != "") then
        echo "$msg" >>& $logPath
    else
        echo "$msg"
    endif
else
    set msg="-E- $script--Failure building tcl in library $lib. Status:|$mystatus| at $targetPath"
    if ($logPath != "") then
        echo "$msg" >>& $logPath
    else
        echo "$msg"
    endif
endif
exit $mystatus
HELP:
    if ($logPath != "") then
        set msg="SYNTAX: $0:t [-h] -p <#> -l <library> [-log <logPath>] <sourcePath>"
        echo "$msg" >>& $logPath
        set msg="    -p <#>          Process Number "
        echo "$msg" >>& $logPath
        set msg="    -l <library>    Name of library to build "
        echo "$msg" >>& $logPath
        set msg="    -log <logPath>  tclcompiler log file path (directory must exist)"
        echo "$msg" >>& $logPath
        set msg="                    not specified, output to standard out"
        echo "$msg" >>& $logPath
        set msg="    <sourcePath>    Where tcl files (if any) & compile dir are located"
        echo "$msg" >>& $logPath
        set msg="    -h              Do nothing but provide this help"
        echo "$msg" >>& $logPath
        set msg="    -clean          Clean the targetPath first (do for only 1st pkg!)"
        echo "$msg" >>& $logPath
        set msg="    -nocompile      Don't compile tcl found in compile dir"
        echo "$msg" >>& $logPath
        set msg=""
        echo "$msg" >>& $logPath
        set msg= "Example:"
        echo "$msg" >>& $logPath
        set fosline='$oalibPath/prim/build/p4/work/mostclbuild.log $oalibPath/prim/lib/tcl/mos'
        set msg="     $0:t -p 4 -l intel73prim -log $fosline"
        echo "$msg" >>& $logPath
    else
        echo "SYNTAX: $0:t [-h] -p <#> -l <library> [-log <logPath>] <sourcePath>"
        echo "    -p <#>          Process Number "
        echo "    -l <library>    Name of library to build "
        echo "    -log <logPath>  tclcompiler log file path (directory must exist)"
        echo "                    not specified, output to standard out"
        echo "    <sourcePath>    Where tcl files (if any) & compile dir are located"
        echo "    -h              Do nothing but provide this help"
        echo "    -clean          Clean the targetPath first (do for only 1st pkg!)"
        echo "    -nocompile      Don't compile tcl found in compile dir"
        echo ""
        echo "Example:"
        set fosline='$oalibPath/prim/build/p4/work/mostclbuild.log $oalibPath/prim/lib/tcl/mos'
        echo "     $0:t -p 4 -l intel73prim -log $fosline"
    endif
    exit $mystatus
