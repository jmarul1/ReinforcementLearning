#!/usr/intel/bin/bash

_mkdirI () 
{

rule_file=$1
layout_file=$2
tool_local=$3

### make run directory.
root_name=${tool_local}-${rule_file}-${layout_file}
end_file_name=${root_name}
if [ -d ${root_name} ] ; then
new_run=`ls -1d * | grep -c ${root_name}-`
#new_run=`find . -type d -name "${root_name}-" | wc -l`
if [[ "$new_run" -gt 0 ]] ; then
  largest_file_iteration=`ls -1d  ${root_name}-[0-9]*  | awk -F'-' '{printf("%s\n",$NF)}' | sort -g | awk '{printf("%s ",$1)}' | awk '{printf($NF)}'`
  largest_file_iteration=`expr $largest_file_iteration + 1`
else
  largest_file_iteration=0
fi
  end_file_name=${root_name}-${largest_file_iteration}
  mv $root_name $end_file_name || (echo "** ERROR - could not mv previous run directory:  ${root_name}  " && exit 1)
fi

mkdir  ${root_name} || (echo "** ERROR - could not create run directory:  ${root_name}  " && exit 1)
cd  ${root_name} || (echo "** ERROR - could not cd to run directory:  ${root_name}" && exit 1)
}

_recurse ()
{
if [[ ${#module[*]} -gt 1 ]] ; then
    module_orig=${module[@]}
    unset module[0]
    module=( ${module[@]} )
    #echo "Running Module ${module[0]} ... modules left to run are: ${module[@]}"
    arg_local=("${@}")
    #echo "arg_local is: $arg_local, arg_orig is: $arg_orig"
    if [[ $arg_orig =~ ".*-q.*" ]] ; then
	command1="${arg_orig/${preset_modules}/\"${module[@]}\"}"
	command="${command1/-q/-m}"
	#echo "command is set to: $command"
    else
	command="${arg_orig/ ${module_orig[@]} / \"${module[@]}\" }"
    fi
    run_this="$0 $command"
    echo "$run_this"
    eval $run_this
fi
}

_read_module ()
{
tool=$1
shift 
tech=$1
shift 
script_basedir=$1
shift 
preset_modules=$@
#echo "setings are: _read_module cal $tech $script_basedir $preset_modules"

if [[ "$tool" = "cal" ]] ; then
    module=(`grep "^$preset_modules " $script_basedir/${tech}_module.map | awk '{printf("%s",$2)}'| sed -e "s^|^ ^g"`)
elif [[ "$tool" = "icv" ]] ; then
    module=(`grep "^$preset_modules " $script_basedir/${tech}_module.map | awk '{printf("%s",$3)}'| sed -e "s^|^ ^g"`)
elif [[ "$tool" = "pvs" ]] ; then
    module=(`grep "^$preset_modules " $script_basedir/${tech}_module.map | awk '{printf("%s",$2)}'| sed -e "s^|^ ^g"`)
else
    echo "** ERROR - bad stuff happened. "
    exit 1
fi
echo ${module[@]}
}

_waiverGen ()
{
loc_tech=$1
loc_tool=$2
loc_rule_file=$3
loc_lay_file_type=$4
loc_run=$5
loc_waiver=""

if [[ $loc_tool = "cal" ]]; then
    if [[ $loc_tech = "1273" || $loc_tech = "1275" ]] && [[ $loc_rule_file = "drcc" ]] ; then
	if [[ $loc_lay_file_type = "oas" ]] ; then
	    if [[ $loc_tech = "1273" ]] ; then
		loc_waiver="-waiver \$Calibre_RUNSET/waive/${loc_tech}_waivers_setup_oas"
	    else
		loc_waiver="-waiver \$Calibre_RUNSET/includes/waive/${loc_tech}_waivers_setup_oas"
	    fi
	else
	    if [[ $loc_tech = "1273" ]] ; then
		loc_waiver="-waiver \$Calibre_RUNSET/waive/${loc_tech}_waivers_setup_gds"
	    else
		loc_waiver="-waiver \$Calibre_RUNSET/includes/waive/${loc_tech}_waivers_setup_gds"
	    fi
	fi
    else
	loc_waiver=""
    fi
elif [[ $loc_tool = "pvs" ]]; then
    if [[ $loc_tech = "1273" ]] && [[ $loc_rule_file = "drcc" ]] ; then
	if [[ $loc_tech = "1273" ]] ; then
	    loc_waiver="-bwf \$PVS_RUNSET/waive/${loc_tech}_waivers_setup_file"
	else
	    loc_waiver="-bwf \$PVS_RUNSET/includes/waive/${loc_tech}_waivers_setup_file"
	fi
    else
	loc_waiver=""
    fi
elif [[ $loc_tool = "icv" ]]; then
    if [[ $loc_tech = "1273" || $loc_tech = "1275" ]] && [[ $loc_rule_file != "trclvs.rs" ]] ; then
	if [ $loc_run == "True" ] ; then
	    #cp -r $runsetPath/CPYDB .
	    #chmod -R 770 CPYDB
	    loc_waiver="cp -r \$icvr/CPYDB . ; chmod -R 777 CPYDB"
	fi
	#loc_waiver="-I ./CPYDB"
	loc_waiver="cp -r \$icvr/CPYDB . ; chmod -R 777 CPYDB"
    else
	loc_waiver=""
    fi
else 
    echo "** Error - Invalid tool name given... internal code issue with _waiver function.  "
    exit 1
fi
echo "$loc_waiver"
}

_Running ()
{

line="--------------------------------------------------------------------------------"
report=$1
echo ""
echo "$line"
echo " - Running $report - "
echo "$line"
echo ""
}

_nb_setupNrun ()
{
      if [ ${NBQSLOT+x} ] ; then
	  nb_qslot_env=""
      else
	  nb_qslot_env="--qslot /icf/fdk/general"
      fi
      if [ ${NBCLASS+x} ] ; then
	  nb_class_env=""
      else
	  nb_class_env="--class ${nb_class}${nb_cpu}"
      fi
      if [ ${NBCLASS+x} ] ; then
	  nb_pool_env=""
      else
	  nb_pool_env="--target pdx_normal"
      fi

      echo "nbjob run $nb_pool_env $nb_qslot_env $nb_class_env --task $USER.task ./$run_script" > nb_log
      nbjob run $nb_pool_env $nb_qslot_env $nb_class_env --task $USER.task ./$run_script
}