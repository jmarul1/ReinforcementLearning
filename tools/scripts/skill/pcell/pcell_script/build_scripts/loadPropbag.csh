#! /bin/csh -f
unalias *
set cellList = ()
set clean = 0 
set test = 0 
set yamlPath = ""
set libdefs = ""

if($#argv == 0) then
    echo "no command line arguments"
else
    @ argnum = 1
    while ($argnum <= $#argv)
        switch ($argv[$argnum])
            case -h*:
            goto HELP_MESSAGE
            breaksw
            case -p:
                @ argnum++
                set process = $argv[$argnum]
                # Make sure process is only a number. The "p" will be added later when creating the build path
                set process = `echo $argv[$argnum]| sed s/^p//`
            breaksw
            case -libdef:
                @ argnum++
                set libdefs = $argv[$argnum]
            breaksw
            case -l:
                @ argnum++
                set oa_lib_name = $argv[$argnum]
            breaksw
            case -test:
                set test = 1
            breaksw
            case -workPath:
                @ argnum++
                set workPath = $argv[$argnum]
            breaksw
            case -libPath:
                @ argnum++
                set libPath = $argv[$argnum]
            breaksw
            case -clean:
                set clean = 1
            breaksw
            case -y:
                @ argnum++
                set yamlPath = $argv[$argnum]
            breaksw
            case -c:
                @ argnum++
                set cellList = ($cellList $argv[$argnum])
            breaksw


            default:
                set package = $argv[$argnum]
            breaksw
        endsw
        @ argnum++
    end
endif

#set workPath = ${PWD}/build/p${process}/work

# Check if package is a full path to CSV file of just a family name
set root = $package:r:t
if ( $root == $package ) then
    set csvFile = "propbag.dir/$package/$package.csv"
else
    set csvFile = $package
    if ($yamlPath == "") then
        echo "-E- ERROR:  Must specify -y option when a CSV file is explicitly defined"
        exit 1
    endif
endif

if ($yamlPath == "") then
    set yamlPath = $workPath/propbags/$package 
endif


if ($libdefs == "") then
    set libdefs = $workPath/lib.defs
endif



if ( $clean == 1 && -e $yamlPath) then
    rm -rf $yamlPath
endif

mkdir -p  $yamlPath

# Create cell list sting, if cells are specified on command line
# This list will be used by csv2yaml.pl
set cellString = ""
if ($#cellList >0 ) then
    foreach item ($cellList)
        set cellString = "$cellString -c $item"
    end
endif
../build_scripts/csv2yaml.pl -p $process -y $yamlPath $cellString  $csvFile

if ($test == 0) then
    # Create cellList for oalibprop if cells are specified on the command line
    if ($#cellList <= 0 ) then
        foreach item ($yamlPath/*.yaml)
            set cellList = ($cellList $item:r:t)
        end
    endif

    foreach cell ($cellList)
        echo "Building Property Bag in Library ($oa_lib_name) for cell ($cell)"
        oalibprop.rb -d $libdefs  -l $oa_lib_name -c $cell -y $yamlPath/$cell.yaml
    end
endif


exit 0


HELP_MESSAGE:
echo "SYNTAX: $0:t [-h] [-clean] [-test] [-libdef <path>] -p <#> -l <library> [-c <cell> ...] <package>"
echo "    -p <#>          Process Number "
echo "    -libdef         Pointer to lib.defs file"
echo "                       default: <PWD>/build/p<process>/work/lib.defs"
echo "    -l <library>    Name of library to build property bags"
echo "    -workPath <path>    Name of work path"
echo "    -libPath <path>    Name of library path"
echo "    -test           Will create yaml files, but will not generate library property bags"
echo "    -c <cell> ...   Name of cell property bag to build. This allows building of only seleceted propery bags from CSV"
echo "                       default: build all cells in CSV file"
echo "                    Multiple cells can be specified by  multiple -c <cell>  arguments"
echo "                      Example:  -c n -c p  -c ntg -c ptg "
echo "    -y  <path>      Alternate directory for yaml files to be built" 
echo "                       default: <PWD>/build/p<process>/work/propbags/<package>"
echo "    -clean          Removes existing yaml path directory, before generating new files"
echo "    <package>       Name of package (family) of cells. The propertybag CSV file will be located at ./propbag.dir/<package>/<package>.csv"
echo "                    The package can also be defined as an explicit path.i When this is done, the -y option must also be used."
echo ""
echo "Description:"
echo "   This utility will build property bags from the prim or tech library, by reading a CSV file"
echo "   By default, it will look for the CSV file from: ./propbag.dir/<package>/<package>.csv"
echo "   The resulting  yaml files will be located at:   ./build/p<process #>/work/propbag/<package>"
echo "   oalibprop.rb will be run on these yamls and propbag will be built on the specified library."
echo ""
echo ""
echo "Examples:"
echo "   Use default locations for yaml file generation as well as package location"
echo "   $0:t -p 4 -workPath ./build/work -libPath ./build/lib -l fdk73p4prim  mos"
echo ""
echo "   Use alternate CSV file"
echo "   $0:t -p 4 -workPath ./build/work -libPath ./build/lib -l fdk73p4prim -y ../test_dir/results ../test_dir/mos.csv"
