#! /bin/csh -f
unalias *
set cellList = ()
set cellsToUpdate = ()
set myStatus = 0
set viewName = "layout"

if($#argv == 0) then
    echo "-E- Error: No command line arguments"
    goto HELP_MESSAGE

else
    @ argnum = 1
    while ($argnum <= $#argv)
        switch ($argv[$argnum])
            case -p:
                @ argnum++
                set process = $argv[$argnum]
                # Make sure process is only a number. The "p" will be added later when creating the build path
                set process = `echo $argv[$argnum]| sed s/^p//`

            breaksw
            case -libPath:
                @ argnum++
                set libPath = $argv[$argnum]
            breaksw
            case -workPath:
                @ argnum++
                set workPath = $argv[$argnum]
            breaksw
            case -l:
                @ argnum++
                set oa_lib_name = $argv[$argnum]
            breaksw
            case -c:
                @ argnum++
                set cellList = ($cellList $argv[$argnum])
            breaksw
            case -u:
                @ argnum++
                set cellsToUpdate = ($cellsToUpdate $argv[$argnum])
            breaksw
            case -view:
                @ argnum++
                set viewName = $argv[$argnum]
            breaksw
            case -h*:
                goto HELP_MESSAGE
            breaksw

            default:
                set package = $argv[$argnum]
            breaksw
        endsw
        @ argnum++
    end
endif

echo "-----------------------"
echo  " Building PyCell in library($oa_lib_name) for package ($package)"
echo "-----------------------"

set basePackage = $package:t


#set workPath = ${PWD}/build/p${process}/work
set oa_lib_path = "$libPath/$oa_lib_name"

# remove old data if it exists
if (-e $workPath/$package) then
    rm -rf $workPath/$basePackage
endif
cp -Lr lib/python/$package $workPath
cp -Lr ../lib/python/common/* $workPath/$basePackage


#This section is no longer needed because we are creating the __init__.py file on the fly.
# Copy dot specific __init__dot#.py file to  __init__.py
pushd $workPath
if ( -e $package/__init__.dot${process}.py ) then
    cp $basePackage/__init__.dot${process}.py $basePackage/__init__.py
endif


# This section builds the __init__.py file on the fly.
# This requires 3 operations.
#   1) Need to import the source code. This will always be called <package>.py
#   2) a pass through class structure needs to be built to isolate each cell
#   3) a lib.definePcell  function call needs to be made for the specified cell.
#
# The Source code file should always be called <package>.py and the top class should always be called <package>. This allows auto generation of the init file.

echo "from  ${basePackage} import *" >${workPath}/$basePackage/__init__.py
foreach cell ($cellList)
    echo "class ${basePackage}_${cell}(${basePackage}):" >>${workPath}/$basePackage/__init__.py
    echo "    pass" >>${workPath}/$basePackage/__init__.py
end

echo "def definePcells(lib):" >>${workPath}/$basePackage/__init__.py
foreach cell ($cellList)
    if ($viewName == "schematic") then
        echo "   lib.definePcell(${basePackage}_${cell}," '"'"${cell}"'", '"'schematic'"', '"'schematic'"')' >>${workPath}/$basePackage/__init__.py
    else 
        echo "   lib.definePcell(${basePackage}_${cell}," '"'"${cell}"'")' >>${workPath}/$basePackage/__init__.py
    endif
end


# It is possile, but not recommended to modify a single cell. It is not a great idea because the souce code
# in the zip file is also updated and impacts all cells previously updated.
if ($#cellsToUpdate > 0) then
    set cells = ""
    foreach cell ($cellsToUpdate)
        if ($cells == "") then
            set cells =  $cell
        else
            set cells =  "$cells,$cell"
        endif
    end
    cngenlib --verbose --update  --bundle=encrypted_source --no_core_dlos pkg:$basePackage $oa_lib_name $oa_lib_path --for_pycells $cells
    set myStatus = $status
else
    cngenlib --verbose --update  --bundle=encrypted_source --no_core_dlos pkg:$basePackage $oa_lib_name $oa_lib_path
    set myStatus = $status
endif

popd

exit $myStatus

HELP_MESSAGE:
    echo "SYNTAX: $0:t [-h] -p <#> -l <library> -workPath <path> -libPath <path>  {-c <cell> ...} <package>"
    echo "    -p <#>          Process Number "
    echo "    -l <library>    Name of library to build "
    echo "    -workPath <path>  Path to work directory "
    echo "    -libPath <path>  Path to library directory "
    echo "    -c <cell> ...   Name of cells for build"
    echo "                      Example:  -c n -c p -c ntg -c ptg "
    echo "    <package>       Name of package"
    echo ""
    echo "Example:"
    echo "     $0:t -p 4 -l fdk73prim -c n -c p  mos"
    echo ""

    exit $myStatus
