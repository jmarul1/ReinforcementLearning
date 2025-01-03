#!/usr/intel/bin/bash

##################################################################################
## start stop watch for wall time reporting
##################################################################################
elapsTime="$(date +%s)"
# Moving common support code to this file.   
real_basedir=`realpath $0`
script_basedir=`dirname $real_basedir`
. $script_basedir/support.sh

##################################################################################
## some default variables
##################################################################################

error_limit="ALL"
follow_report=">&"
error_result_file="cal_out.oas"
oasis_error_results="True"
nb_mem_array=(1 2 4 6 8 10 12 14 18 20 28 32 64 128 256)
run="True"
local_dir=`pwd`
source_tool="False"
tech="null"

if [ ${INTEL_PDK+x} ] ; then
#    echo "Pulling info from env... INTEL_PDK path is: $INTEL_PDK"
    runsetPath="$INTEL_PDK/runsets/calibre"
    tech_name=`echo $INTEL_PDK | awk -F'/' '{printf("%s",$4)}'`
    if [[ $tech_name = "fdk75" ]] ; then
        env_tech="1275"
    elif [[ $tech_name = "fdk73" ]] ; then
        env_tech="1273"
    elif [[ $tech_name = "fdk71" ]] ; then
        env_tech="1271"
    elif [[ $tech_name = "f1222" ]] ; then
        env_tech="1222"
    elif [[ $tech_name = "f1231" ]] ; then
        env_tech="1231"
    elif [[ $tech_name = "f1276" ]] ; then
        env_tech="1276"
    fi
fi
#if [ ${DR_PROCESS+x} ] ; then
#    echo "** Info - DR_PROCESS is being pulled from the envirionment: $DR_PROCESS"
#    dot=$DR_PROCESS
#fi
echo ""
##################################################################################
## usage
##################################################################################
usage="

usage : $0 [-h] -p <technology> -r <runset dir> -l <layout file> -t <top cell name> -m <drc module>

    Required arguments are:
	-m <module>       : Modules that should be run based on run file name
                              (example modules include drcc IPall lvs).  
                              Multiple modules can be run by quoting a list 
                              (for example: -m \"drcc IPall lvs\")
	-q <flow>         : Flows are module(s) that are grouped per flow 
                              (for example: -q DFM runs equivalent to 
                               -m \"DFM DFMcon\").  These groups are set in the
                               <tech>_module.map file.  Either -q or -m are 
                               required.
	-l <layout path>  : Path to layout (gds or oas file).

    Optional arguments if running inside a kit (required outside a kit):
	-p <process>      : Process name (1222|1231|1271|1273|1275)
	-r <runset dir>   : Path to the runset directory.  

    Optional arguments are:
	-h                : Prints this help info.
	-t <lay top cell> : Layouts top cell name, if none is given first 
                              layout at top of layout file is run.
	-c <# of cpu>     : Number of cores to be used (\"all\")
	-d <dot #>        : Dot number in digit form (0-9... will be translated 
                              for the runset needs).
	-i <switch>       : Calibre specific command line switch (switch is 
                              intended to be exact command to be placed in run 
                              script).  
	-a <error count>  : Output specific number of each error (default is 
                              show all results).
	-o <file name>    : Change output errors destination oasis file. 
                              Changing the output file name to \"NO\" will cause 
                              no layout error file to be generated.
	-n <netlist path> : Path to the schematic netlist.
	-s <sch top cell> : Schematice netlist's top cell.
	-b <# gig needs > : Runs netbatch with the memory request set by the 
                              number passed (expecting a digit 0-9).  If -c gets 
                              an argument of 0 and if -b # is set then netbatch 
                              uses env variables set in the nb_setup.sh file 
                              instead of the -b argument to trigger the nb settings.  
                              Using -c 0 is to allow for bigger jobs.  
	-g                : Generates run files, but doesn't run
	-e s              : Runs section level = NO (default is SL=YES, FD=NO)
	   f              : Runs with fulldie = YES, and section level = NO
	   h              : Runs with fulldie = YES, gate direction horizontal, 
                              and section level = NO
	   unset          : Does not set any of the specified options
        -j <option>       : Runs with merge open = <option> (option must be 
                              YES|NO|ALL, YES is default).
        -f                : Prints log to screen as well as putting it in a file.  
        -k                : Path to a customized useroverrides.svrf (default is 
                              to use the one in given runset directory)
"

##################################################################################
## input parcing
##################################################################################
while getopts "a:b:c:d:e:fghi:j:k:l:m:n:o:p:q:r:s:t:z" opt; do
    case $opt in
	z)
	    source_tool="True"
	    ;;
	o)
	    if [ -z $OPTARG ] ; then
		echo "oasis file name change was called but a name was not given... using default $error_result_file "
                oasis_error_results="True"
	    elif [[ $OPTARG = "NO" || $OPTARG = "no" ]] ; then
                oasis_error_results="False"
            else 
                oasis_error_results="True"
		error_result_file="$OPTARG"
	    fi
	    ;;
	g)
	    run="False"
	    ;;
	h)
	    echo "$usage"
	    exit 1
	    ;;
	i)
	    env_options=($OPTARG)
	    ;;
	l)
	    if [ -f $OPTARG ] ; then
		gdsPath="$OPTARG"
	    else 
		echo "** ERROR - -$opt requires a path to an existing file. $OPTARG does not exist. "
		echo "$usage"
		exit 1
	    fi
	    ;;
	t)
	    if [ -z $OPTARG ] ; then
		gdsTopCell=""
	    else 
		gdsTopCell="$OPTARG"
	    fi
	    ;;
	n)
	    if [ -f $OPTARG ] ; then
		cdlPath=`realpath $OPTARG`
	    else 
		echo "** ERROR - -$opt requires a path to an existing file. $OPTARG does not exist. "
		echo "$usage"
		exit 1
	    fi
	    ;;
	s)
	    if [ -z $OPTARG ] ; then
		schTopCell=""
	    else 
		schTopCell="$OPTARG"
	    fi
	    ;;
	r)
	    if [ -d $OPTARG ] ; then
		runsetPath="$OPTARG"
	    else 
		echo "** ERROR - -$opt requires a path to an existing file. $OPTARG does not exist. "
		echo "$usage"
		exit 1
	    fi
	    ;;
	p)
	    if [[ $OPTARG = "1222" || $OPTARG = "1231" || $OPTARG = "1271" || $OPTARG = "1273" || $OPTARG = "1275" || $OPTARG = "1276" ]] ; then
		tech="$OPTARG"
	    else 
                if [ ${env_tech+x} ] ; then
                    echo "** Info - Pulling process from env ($env_tech).  "
                    tech=$env_tech
                else
                    echo "** ERROR - -$opt requires 1222, 1231, 1271, 1273, 1275 or 1276 as an input. $OPTARG is not an allowed process. "
                    echo "$usage"
                    exit 1
                fi
            fi
            if [[ ${env_tech+x} && "$tech" != "$env_tech" ]] ; then
                echo "** Warning - The process you selected ($tech) does not align with the kit you are in ($env_tech).  "
            fi
	    ;;
	m)
	    if [ -z ${OPTARG+x} ] ; then
		echo "** ERROR - Module must be set. "
		echo "$usage"
		exit 1
	    else 
		module=($OPTARG)
	    fi
	    ;;
	q)
	    if [ -z $OPTARG ] ; then
		echo "** ERROR - -$opt requires a predefined Module name. "
		echo "$usage"
		exit 1
	    else 
		preset_modules="$OPTARG"
	    fi
	    ;;
	c)
	    if [ -z $OPTARG ] ; then
		cpu=""
	    else 
		cpu="$OPTARG"
	    fi
	    ;;
	a)
	    if [[ $OPTARG =~ [0-9]+ ]] ; then
                error_limit=$OPTARG
	    else
              if [ $OPTARG = "all" ] || [ $OPTARG = "ALL" ] ; then
                  error_limit="$OPTARG"
              else
	    	  # if switch is set but not an allowed value error out.  
		  echo "** ERROR - option -$opt (if set) must be a digit... not $OPTARG "
		  echo "$usage"
		  exit 1
  	      fi
	    fi
	    ;;
	d)
	    if [[ "$OPTARG" =~ ^[0-9]+$ ]] ; then
		dot_num="$OPTARG"
		dot=`${script_basedir}/num2eng_trans.sh $dot_num`
	    else
		echo "** ERROR - option -$opt (if set) must be a digit 0-9. "
		echo "$usage"
		exit 1
	    fi
            if [ ${DR_PROCESS+x} ] ; then
                if [[ "$dot" != "$DR_PROCESS" ]] ; then
		    echo "** Warning - The dot you selected ($dot) does not align with the kit you are in ($DR_PROCESS).  "
                fi
            fi
	    ;;
	b)
	    if [[ "$OPTARG" =~ "[0-9][0-9]*" ]] ; then
		for i in ${nb_mem_array[@]}
		do
		  if [ $i -eq $OPTARG ] ; then
		      nb_class="SLES11&&${OPTARG}G"
		      break
		  fi
		done
		if [ -z ${nb_class:-x} ] ; then
		  # if set but not set to allowed value error out.  
		  echo "** ERROR - option -$opt must be a digit ${nb_mem_array[@]}. "
		  echo "** ERROR - option -$opt was set to $OPTARG. "
		  echo "$usage"
		  exit 1
		fi
	    else
		# if switch is set but not an allowed value error out.  
		echo "** ERROR - option -$opt (if set) must be a digit ${nb_mem_array[@]}. "
		echo "** ERROR - option -$opt was set to $OPTARG. "
		echo "$usage"
		exit 1
	    fi
	    ;;
	e)
	    if [[ $OPTARG = "s" || $OPTARG = "f" || $OPTARG = "h" || $OPTARG = "unset" ]] ; then
		section_level="$OPTARG"
	    else 
		echo "** ERROR - -$opt requires s (section_level no), f (fulldie and sl no), or h (fd, and sl no and gate direction horizontal. $OPTARG is not an allowed argument. "
		echo "$usage"
		exit 1
	    fi
	    ;;
	f)
	    follow_report="| tee"
	    ;;
	j)
	    if [[ $OPTARG = "YES" || $OPTARG = "NO" || $OPTARG = "ALL" || $OPTARG = "unset" ]] ; then
		mergeopen="$OPTARG"
	    else 
		echo "** ERROR - -$opt requires YES, NO, or ALL. $OPTARG is not an allowed argument. "
		echo "$usage"
		exit 1
	    fi
	    ;;
	k)
	    if [[ -r $OPTARG ]] ; then
		inc_path=`realpath $OPTARG`
	    else 
		echo "** ERROR - -$opt requires a valid path to a useroverrides... you gave: "
		echo "     $OPTARG"
		echo "$usage"
		exit 1
	    fi
	    ;;
	\?)
	    echo "** ERROR - Invalid option: $OPTARG" 
	    echo "$usage"
	    exit 1
	    ;;
	:)
	    echo "** ERROR - Option -$OPTARG requires an argument." 
	    echo "$usage"
	    exit 1
	    ;;
    esac
done

##################################################################################
## option checking
##################################################################################
if [[ $tech = "null" ]] ; then
    if [ ${env_tech+x} ] ; then
        echo "** Info - Pulling process from env ($env_tech).  To manually set use -p"
        tech=$env_tech
    else
        echo "** ERROR - -p must be manually set to 1222, 1231, 1271, 1273, 1275 or 1276 if not running in a kit. "
        echo "$usage"
        exit 1
    fi
fi

if [[ ${preset_modules+x} ]] ; then
    module=(`_read_module cal $tech $script_basedir $preset_modules`)
fi

#echo "Module is $module"
#echo "Module is ${module[@]}"
#echo "cpu is $cpu, module is $module, tech is $tech, runsetPath is $runsetPath, schTopCell is $schTopCell, cdlPath is $cdlPath, gdsTopCell is $gdsTopCell, gdsPath is $gdsPath"
#exit 0

if [[ -z ${gdsPath+x} ]] ; then
    echo "** ERROR - The layout file was not specified. "
    echo "$usage"
    exit 1
fi

if [ ! -f "$gdsPath" ] ; then
    echo "** ERROR - The layout file is not the proper file type. "
    echo " $gdsPath"
    echo "$usage"
    exit 1
else
    gdsPath=`realpath $gdsPath`
    layout_file=`basename $gdsPath`
    layout_name=${layout_file%%.*}
    layout_dir=`dirname $gdsPath`
    if [[ -z ${inc_path+x} ]] ; then
	inc_path=$layout_dir/${layout_name}_CAL_OVERRIDES/useroverrides.svrf
	if [[ ! -r $inc_path ]] ; then
	    inc_path=$layout_dir/useroverrides.svrf
	    if [[ ! -r $inc_path ]] ; then
		inc_path=$layout_dir/calibre/useroverrides.svrf
		if [[ ! -r $inc_path ]] ; then
		    inc_path=$runsetPath/includes/useroverrides.svrf
		    if [[ ! -r $inc_path ]] ; then
			inc_path=$runsetPath/includes/useroverrides/useroverrides.svrf
			if [[ ! -r $inc_path ]] ; then
			    inc_path=$runsetPath/useroverrides.svrf
			fi
			if [[ ! -r $inc_path ]] ; then
			    echo "** ERROR - can't find useroverrides: $inc_path"
			else
			    echo "** Info - Using runset useroverrides: $inc_path"
			fi
		    fi
		else
		    echo "** Info - Using useroverrides from calibre dir located with layout: $inc_path"
		fi
	    else
		echo "** Info - Using useroverrides in same dir as the layout: $inc_path"
	    fi
	fi
    fi
fi

layout_file_type=${gdsPath##*.}
if [ $layout_file_type != "gds" ] && [ $layout_file_type != "oas" ] && [ $layout_file_type != "stm" ] && [ $layout_file_type != "sp" ] && [ $layout_file_type != "cdl" ] ; then
    echo "** ERROR - Layout file must be gds, oasis, cdl or sp file"
    echo " $layout_file_type"
    echo "$usage"
    exit 1
fi

#dot=${dot:-dotSix}
if [[ -z ${dot+x} ]] ; then
    echo "** ERROR - Dot must be manually set (-d [0-9] at command line)"
    echo "$usage"
    exit 1
fi

if [ $layout_file_type = "oas" ] ; then
    set_layout_file_type="setenv DR_INPUT_FILE_TYPE OASIS" 
elif [ $layout_file_type = "sp" ] || [ $layout_file_type = "cdl" ] ; then
    set_layout_file_type="setenv DR_INPUT_FILE_TYPE spice"
else
    set_layout_file_type="setenv DR_INPUT_FILE_TYPE GDS"
fi

if [ ! -d $runsetPath ] ; then
    echo "** ERROR - The rule directory is not a directory. "
    echo " $runsetPath"
    echo "$usage"
    exit 1
fi

################################################################################
# Module Specific Settings
################################################################################
if [[ -z ${module+x} && ${#module[@]} < 1 ]] ; then
    echo "** ERROR - The module or flow is not defined. Use -m <module> to set it. "
    echo "$usage"
    exit 1
elif [ "${module[0]}" = "drc" ] ; then
    module_line=""
    rule_file="drcc"
    engine="-drc"
    # the following line is to run a subset of a given runset... hooks for this are not complete.  
    #module_line="setenv DRC_SELECT "$module
elif [ "${module[0]}" = "lvs" ] ; then
    rule_file=${module[0]}
    if [ -z $cdlPath ] ; then
	engine="-spice lay.spi"
    elif [ "$set_layout_file_type" = "setenv DR_INPUT_FILE_TYPE spice" ] ; then
        engine="-lvs"
    else
        engine="-lvs -spice lay.sp"
    fi
        if [[ -z ${schTopCell+x} ]] ; then
	    if [[ -z ${gdsTopCell+x} ]] ; then
		echo "** Warning - Schematic top cell not specified using first top cell found in layout file.  "
		mod_spec_env="setenv DR_SCH_FILE $cdlPath ; setenv DR_SCH_CELL \"\$topCellName\""
	    else
		mod_spec_env="setenv DR_SCH_FILE $cdlPath ; setenv DR_SCH_CELL $gdsTopCell"
	    fi
	else
            mod_spec_env="setenv DR_SCH_FILE $cdlPath ; setenv DR_SCH_CELL $schTopCell"
	fi
elif [[ ${module[0]} = "drcdcon" ]] ; then
    engine="-drc"
    rule_file=${module[0]}
    if [[ $tech = "1222" ]] ; then
	mod_spec_env=""
    else
	mod_spec_env="setenv CALIBRE_ENABLE_NET_APEX 1"
    fi
elif [[ ${module[0]} = "drcperc" ]] ; then
    engine="-perc -ldl"
    rule_file=${module[0]}
    mod_spec_env=""
elif [[ ${module[0]} = "ldl" ]] ; then
    engine="-perc -ldl"
    rule_file=${module[0]}
    if [[ -z ${schTopCell+x} ]] ; then
	if [[ -z ${gdsTopCell+x} ]] ; then
	    echo "** Warning - Neither the schematic or layout top cells were specified using first top cell found in layout file.  "
	    mod_spec_env="setenv RUNLDLONLY YES ; setenv DR_SCH_FILE $cdlPath ; setenv DR_SCH_CELL \"\$topCellName\""
	else
	    mod_spec_env="setenv RUNLDLONLY YES ; setenv DR_SCH_FILE $cdlPath ; setenv DR_SCH_CELL $gdsTopCell"
	fi
    else
        mod_spec_env="setenv RUNLDLONLY YES ; setenv DR_SCH_FILE $cdlPath ; setenv DR_SCH_CELL $schTopCell"
    fi
else
    engine="-drc"
    rule_file=${module[0]}
    mod_spec_env=""
fi

################################################################################
# Runset path
################################################################################

rule_file_path="$runsetPath/p${tech}_${rule_file}.svrf"
if [ ! -f $rule_file_path ] ; then
    rule_file_path="$runsetPath/UTILITY/p${tech}_${rule_file}.svrf"
    if [ ! -f $rule_file_path ] ; then
	rule_file_path="$runsetPath/includes/p${tech}_${rule_file}.svrf"
	if [ ! -f $rule_file_path ] ; then
	    rule_file_path="$runsetPath/p${tech}_${rule_file}.sh"
	    if [ ! -f $rule_file_path ] ; then
		echo "$rule_file does not exist in path $runsetPath (includes or utility dir)..."
		echo "Module and runset path do not develop a valid runset. "
		echo "$usage"
		exit 1
	    fi
	fi
    fi
fi

#echo "rule file is: $rule_file"

#if [ ! -f $rule_file ]
#then
#     if ! grep -q "$module" $runsetPath/select_check_file 
#     then
#	echo "** ERROR - The rule file does not exist or is not the proper file type. "
# 	echo "$usage"
# 	exit 1
#     fi
#fi

################################################################################
# Machine requirements
################################################################################
if [[ $cpu =~ "[1-9]+" ]] ; then
    do="nothing"
    nb_cpu="_${cpu}C"
elif [[ $cpu =~ "0" ]] ; then
    cpu=""
    nb_cpu="_32C"
elif [[ $cpu = "all" || $cpu = "ALL" ]] ; then
    cpu="-turbo_all"
    nb_cpu="_${cpu}C"
else
    cpu="2"
    nb_cpu=""
fi

nb_cpu=${nb_cpu:-""}

log=cal.${module[0]}.log

if [[ $oasis_error_results = "True" ]] ; then
    error_file_type=${error_result_file##*.}
    if [[ $error_file_type = "gds" || $error_file_type = "stm" ]] ; then
        error_file_type="GDSII"
    elif [[ $error_file_type = "oas" ]] ; then
        error_file_type="OASIS"
    else
        echo "** Warning - The error output file type sufix was not recognized so it will be output as an oasis file... it is expected to have a suffix of .oas|.gds|.stm., but $error_result_file was given. "
        error_file_type="OASIS"
    fi
    oasis_results="setenv DR_OUTPUT_FILE $error_result_file 
setenv DR_OUTPUT_FILE_TYPE $error_file_type"
else
    oasis_results=""
fi

if [[ ! -f $rule_file_path ]] ; then
    echo "** ERROR - The rule file does not exist or is not the proper file type. "
    echo "$rule_file_path"
    echo "$usage"
    exit 1
fi

if [ -z ${env_options+x} ] ; then
    env_options=""
fi

#section level/fulldie/gate_dir
if [[ -z ${section_level+x} ]] ; then
    section_level_command="setenv DR_SECTION_LEVEL YES
setenv DR_FULL_DIE NO"
elif [[ $section_level = "s" ]] ; then
    section_level_command="setenv DR_SECTION_LEVEL NO"
elif [[ $section_level = "f" ]] ; then
    section_level_command="setenv DR_SECTION_LEVEL NO
setenv DR_FULL_DIE YES"
elif [[ $section_level = "h" ]] ; then
    section_level_command="setenv DR_SECTION_LEVEL NO
setenv DR_FULL_DIE YES
setenv DR_GATE_DIRECTION HORIZONTAL"
elif [[ $section_level = "unset" ]] ; then
    section_level_command="##setenv DR_SECTION_LEVEL NO
##setenv DR_FULL_DIE YES
##setenv DR_GATE_DIRECTION HORIZONTAL"
else
    echo "** ERROR - -e requires s (section_level no), f (fulldie and sl no), or h (fd, and sl no and gate direction horizontal. $section_level is not an allowed argument. "
    echo "$usage"
    exit 1
fi

#merge open
if [ -z ${mergeopen+x} ] ; then
    mergeopen_command="setenv DR_MERGEOPEN YES"
elif [[ $mergeopen = "YES" || $mergeopen = "NO" || $mergeopen = "ALL" ]] ; then
    mergeopen_command="setenv DR_MERGEOPEN $mergeopen"
elif [[ $mergeopen = "unset" ]] ; then
    mergeopen_command="##setenv DR_MERGEOPEN NO|YES|ALL"
else
    echo "** ERROR - -f requires setting of YES|NO|ALL. $mergeopen is not an allowed argument. "
    echo "$usage"
    exit 1
fi


##################################################################################
## make run scripts
##################################################################################

_mkdirI $rule_file $layout_file cal

waiver=`_waiverGen $tech cal $rule_file $layout_file_type $run`

#gen useroverrides
end_include="./cal_sh_useroverrides.svrf"
limit_results="setenv DR_userOverrides $end_include"
error_limit_val=""
if [[ $tech = "1275" ]] ; then
    if grep -q "DRC MAXIMUM RESULTS ALL" $runsetPath/p1275.tvf ; then
	if ! grep -q "^ *DRC MAXIMUM RESULTS ALL" $inc_path ; then
	     cat $inc_path > $end_include
	     error_limit_val="setenv DR_MAXIMUM_RESULTS $error_limit"
	else
	    echo "** ERROR - useroverride file has redundant DRC MAXIMUM RESULTS statement"
	    exit 1
	fi
    else
	if ! grep -q "DRC MAXIMUM RESULTS ALL" $inc_path ; then
	    echo "** Warning - user override file is missing the drc maximum results statement"
	    cp $inc_path $end_include
	    echo "/// adding max results where it was missing. " >> $end_include
	    echo "DRC MAXIMUM RESULTS $error_limit" >> $end_include
	    echo "/// end max results addition where it was missing. " >> $end_include
	else
	    sed -e "s%DRC MAXIMUM RESULTS ALL%DRC MAXIMUM RESULTS $error_limit%g" $inc_path > $end_include
	fi
    fi
else 
    sed -e "s%DRC MAXIMUM RESULTS ALL%DRC MAXIMUM RESULTS $error_limit%g" $inc_path > $end_include
fi

if [[ $tech != "1275" ]] ; then

cat <<EOF >local_${module[0]}.svrf
//LAYOUT INPUT EXCEPTION SEVERITY POLYGON_DEGENERATE 1
//LAYOUT INPUT EXCEPTION SEVERITY MISSING_REFERENCE 1
INCLUDE $rule_file_path
EOF

  rule_file="local_${module[0]}.svrf"
else
  rule_file="\$Calibre_RUNSET/p${tech}_${rule_file}.svrf"
fi

if [[ "$tech" == "1276" || "$tech" == "1275" || "$tech" == "1222" || "$tech" == "1231" ]] ; then
  if [[ "${module[0]}" = "tapein_merge" ]] ; then
      run_command="$Calibre_RUNSET/$"
  else
      run_command="calibre $engine -hier -turbo $cpu -hyper $rule_file $follow_report $log"
  fi
  input_CELL="DR_INPUT_CELL"
else
  if [[ "${module[0]}" = "tapein_merge" ]] ; then
      run_command="calibre $engine -hier -turbo $cpu -hyper $rule_file $follow_report $log"
  else
      run_command="calibre $engine -hier -turbo $cpu -hyper $rule_file $follow_report $log"
  fi
  input_CELL="DR_LAY_CELL"
fi

tool_source=""

if [ -z ${gdsTopCell+x} ] ; then
    echo "** Warning - Topcell not specified using first top cell found in layout file: $gdsTopCell"
    topCell_arg='set topCellName=`calibredrv -a "puts [layout peek '$gdsPath' -topcell]"`'
    topCell_call="setenv $input_CELL \"\$topCellName\""
else
    topCell_arg=""
    topCell_call="setenv $input_CELL \"$gdsTopCell\""
fi

#runtime evaluation tool
rt_tool="calibre_runtime_info.pl"
rt_tool_path=`which $rt_tool`
if [ -f $rt_tool_path ] ; then
    runtime_eval="$rt_tool -i . -o cal.${module[0]}.rt.csv > cal.${module[0]}.rt.log"
else
    runtime_eval=""
fi

run_script="cal.${module[0]}.tcsh"
cat <<EOF >$run_script
#!/usr/intel/bin/tcsh

$tool_source

$topCell_arg

setenv Calibre_RUNSET "$runsetPath"
setenv DR_PROCESS $dot
source \$Calibre_RUNSET/p$tech.env
setenv DR_INPUT_FILE  "$gdsPath"
setenv DR_SPILT_COLLETRAL YES
$set_layout_file_type
$topCell_call
$limit_results
$module_line
${env_options[@]}
$mod_spec_env
$oasis_results
$section_level_command
$mergeopen_command
$error_limit_val
$run_command 

$runtime_eval

EOF

##################################################################################
## run script
##################################################################################

_Running ${module[0]}

chmod 770 $run_script
if [ $run == "True" ] ; then
  nb_class=${nb_class:-false}
  if [ $nb_class == "false" ] ; then
      ./$run_script
  else
      if [ "$nb_cpu" == "_32C" ] ; then
         source $script_basedir/nb_setup.sh
         jobid=`nbjob run --task $USER.task ./$run_script | awk '{printf("%s",$7)}' | sed -e "s^,^^g"`
      else 
         echo "nbjob run --target pdx_normal --qslot /icf/fdk/general --class ${nb_class} --task $USER.task ./$run_script" > nb_log
         jobid=`nbjob run --target pdx_normal --qslot /icf/fdk/general --class ${nb_class} --task $USER.task ./$run_script | awk '{printf("%s",$7)}' | sed -e "s^,^^g"`
      fi
  fi
  if [ -z ${jobid+x} ] ; then
      echo "CELL: $gdsTopCell"
  else
      echo "CELL: $gdsTopCell, jobID: $jobid"
  fi
fi

##################################################################################
## check run
##################################################################################

elapsTime="$(($(date +%s)-elapsTime)) seconds"

if [[ $run = "True" ]] ; then
if [[ $nb_class = "false" ]] ; then

if [ "${module[0]}" = "lvs" ] ; then
    if grep -q "SPICE NETLIST FILE" $log ; then
	if [ -z $cdlPath ] ; then
	    status="EXTRACTED"
	else
	    status=`grep "LVS complete" $log | grep -v CPU | awk '{printf("%s\n",$3)}'`
	fi
	echo "*** LVS $status (elaps time is: $elapsTime) ***"
    else
	echo "*** ERROR - LVS run problem (elaps time is: $elapsTime) ***"
    fi
else
    if grep -q "DRC-H EXECUTIVE MODULE COMPLETED." $log ; then
	errors=`grep "TOTAL RESULTS GENERATED" $log | awk '{printf("%s %s",$6,$7)}'`
	echo "*** $errors DRC errors (elaps time is: $elapsTime) ***"
    else
	echo "*** ERROR - DRC run problem (elaps time is: $elapsTime) ***"
    fi
fi

fi

fi

##################################################################################
## print a local command line to a local file
##################################################################################
cat <<EOF >.cal_run_file
    
#run generated with:  
$0 $@

EOF

cd ..

echo ""

arg_orig=$@
_recurse arg_orig[@]


