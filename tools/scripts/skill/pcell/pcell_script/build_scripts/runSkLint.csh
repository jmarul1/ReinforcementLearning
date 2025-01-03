#! /bin/csh -f
unalias *

set fileList = ()
set currDir = ${PWD}
set outPath = ${currDir}/skLint
set showWarn = 1
set showError = 1
set showUnused = 1

if($#argv == 0) then
    echo "No command line arguments"
    goto HELP_MESSAGE
else
    @ argnum = 1
    while($argnum <= $#argv)
        switch($argv[$argnum])
            case -h*:
                goto HELP_MESSAGE
            breaksw

            case -o:
                @ argnum++
                set outPath = $argv[$argnum]
            breaksw

            case -noWarn:
                set showWarn = 0
            breaksw

            case -noError:
                set showError = 0
            breaksw

            case -noUnused:
                set showUnused = 0
            breaksw

            default:
                set skillFile = $argv[$argnum]
                set fileRoot = $skillFile:r:t
                if(! -e $skillFile) then
                    echo "-E- Error: Skill file not found ($skillFile)"
                    exit 1
                endif
                set skillFile = `realpath $skillFile`
                set fileList = ($fileList $skillFile)
            breaksw
        endsw
        @ argnum++
    end
endif

if(! -e $outPath) then
    mkdir $outPath
endif

set skillLoadFile = ${outPath}/runSkLint.il
if(-e $skillLoadFile) then
    rm -f $skillLoadFile
endif

set logFile = ${outPath}/skLintOut.log
foreach file ($fileList)
    set skillLintLog = ${outPath}/$file:t_lintLog.out
    echo 'sh("echo Running SKILL Lint on '$file:t'")' >> ${skillLoadFile}
    echo 'sklint(?file "'${file}'" ?outputFile "'${skillLintLog}'")' >> ${skillLoadFile}
end

set reportFile = ${outPath}/skLintReport.out
if(-e $reportFile) then
    rm -f $reportFile
endif 

echo "Loading SKILL Lint Script"
echo "========================="
\virtuoso -nocdsinit -nographE -replay ${skillLoadFile} -log ${logFile}
echo "==========================="
echo "Completed SKILL Lint Script"

echo "==========================="
echo "Lint Score Summary"
echo "==========================="

echo "Running with the following options enabled:"
echo "Running with the following options enabled:" >> $reportFile
echo "  * Global Variable Check ON"
echo "  * Global Variable Check ON" >> $reportFile

if($showWarn == 1) then
	echo "  * Warnings ON"
	echo "  * Warnings ON" >> $reportFile
else
	echo "  * Warnings OFF"
	echo "  * Warnings OFF" >> $reportFile
endif

if($showUnused == 1) then
	echo "  * Unused Variables ON"
	echo "  * Unused Variables ON" >> $reportFile
else
	echo "  * Unused Variables OFF"
	echo "  * Unused Variables OFF" >> $reportFile
endif

if($showError == 1) then
	echo "  * Errors ON"
	echo "  * Errors ON" >> $reportFile
else
	echo "  * Errors OFF"
	echo "  * Errors OFF" >> $reportFile
endif
echo "==========================="
echo "****************************************" >> ${reportFile}
echo >> $reportFile

foreach file ($fileList)
    set currLogFile = ${outPath}/$file:t_lintLog.out
    echo "SKILL Lint results for" $file:t >> ${reportFile}
    echo "****************************************" >> ${reportFile}
    grep 'INFO (IQ)' ${outPath}/$file:t_lintLog.out >> ${reportFile}
    echo -n $file:t' --> '
    grep 'INFO (IQ)' ${outPath}/$file:t_lintLog.out 
    grep GLOB ${outPath}/$file:t_lintLog.out >> ${reportFile}
    if($showWarn == 1) then
        grep 'WARN (' ${outPath}/$file:t_lintLog.out >> ${reportFile}
    endif
    if($showUnused == 1) then
        grep UNUSED ${outPath}/$file:t_lintLog.out >> ${reportFile}
    endif
    if($showError == 1) then
        grep ERROR ${outPath}/$file:t_lintLog.out >> ${reportFile}
    endif
    echo >> ${reportFile}
    echo >> ${reportFile}
end

echo "==========================="
echo "Detailed Results Found In "${reportFile}

exit $status

HELP_MESSAGE:

    echo "SYNTAX: $0:t [-h] [-noError] [-noWarn] [-noUnused] [-o] <outputDir> <fileList>"
    echo
    echo "-h       : show this help message"
    echo "-noError : suppress error messages from output"
    echo "-noWarn  : suppress warning messages from output"
    echo "-noUnused: suppress unused variable messages in output file"
    echo "-o       : specify the directory for all output files"
    exit 0
