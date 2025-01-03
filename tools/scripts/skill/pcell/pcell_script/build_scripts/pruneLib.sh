#!/usr/bin/env bash

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# (C) Copyright Intel Corporation, 2010
# Licensed material -- Program property of Intel Corporation
# All Rights Reserved
#
# This program is the property of Intel Corporation and is furnished
# pursuant to a written license agreement. It may not be used, reproduced,
# or disclosed to others except in accordance with the terms and conditions
# of that agreement.
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

############################################################
#   Script path & cmdline args
############################################################

case "$0" in
  */* ) EXEC_DIRPATH=`dirname "$0"`
        SCRIPT_NAME=`basename "$0"`
        ;;
  * ) IFS=":"
      for EXEC_DIRPATH in $PATH
      do if [ -x "$dir/$0" ]
         then SCRIPT_NAME="$0"
	      break
	 fi
      done
      IFS=" 	"
      ;;
esac
EXEC_DIRPATH=`realpath "$EXEC_DIRPATH"`

usage () {
  local exitstatus="$1"
  echo "Usage: $SCRIPT_NAME -d <libDirPath> -n <libraryName> -w <workDirPath>"
  exit $exitstatus
}

while getopts ":d:n:w:" opt
do case "$opt" in
    d ) LIB_DIRPATH="$OPTARG" ;;
    n ) LIB_NAME="$OPTARG" ;;
    w ) WORK_DIRPATH="$OPTARG" ;;
    : ) echo "ERROR: Flag -$OPTARG requires an argument." 1>&2
        usage 1
        ;;
    \? ) echo "ERROR: Unknown cmd line arg '$opt'" 1>&2
         usage 1
         ;;
   esac
done
shift `expr $OPTIND - 1`

if [ x"$LIB_DIRPATH" = x ]
then echo "ERROR: -d <libDirPath> cmd line arg was not specified." 1>&2
     exit 1
elif [ -d "$LIB_DIRPATH" ]
then :; else
  echo "ERROR: -d <libDirPath> does not refer to a valid directory path." 1>&2
  exit 1
fi
export LIB_DIRPATH

if [ x"$LIB_NAME" = x ]
then echo "ERROR: -n <libName> cmd line arg was not specified." 1>&2
     exit 1
fi
export LIB_NAME

if [ x"$WORK_DIRPATH" = x ]
then echo "ERROR: -w <workDirPath> cmd line arg was not specified." 1>&2
     exit 1
elif [ -d "$WORK_DIRPATH" ]
then :; else
  echo "ERROR: -w <workDirPath> does not refer to a valid directory path." 1>&2
  exit 1
fi
export WORK_DIRPATH

############################################################
#   Derived gobals
############################################################

TARGET_LIB_DIRPATH="$LIB_DIRPATH/$LIB_NAME"
if [ -r "$TARGET_LIB_DIRPATH/cdsinfo.tag" ]
then :; else
  echo "ERROR: No cdsinfo.tag file at $TARGET_LIB_DIRPATH" 1>&2
  exit 1
fi

############################################################
#   Set up paths to our default include
############################################################
if [ x"$CDL_MODELS_FPATHS" = x ]
then if [ x"$FORGE_MODE" = x"ftcdev" ]
     then CDL_MODELS_FPATHS=`find "$FDK_FOSSIL/models/dot${FDK_DOTPROC}/cdl/core/$UPF_VERSION" -follow -name \*.cdl`
     else CDL_MODELS_FPATHS=`find "$FDK_INST_DIR/models/cdl/core/latest" -follow -name \*.cdl`
     fi
     if [ x"$CDL_MODELS_FPATHS" = x ]
     then unset CDL_MODELS_FPATHS
     else export CDL_MODELS_FPATHS
     fi
fi
if [ x"$HSPICED_MODELS_FPATHS" = x ]
then if [ x"$FORGE_MODE" = x"ftcdev" ]
     then HSPICED_MODELS_FPATHS=`find "$FDK_FOSSIL/models/dot${FDK_DOTPROC}/hspice/core/$UPF_VERSION" -follow -name \*.hsp`
     else HSPICED_MODELS_FPATHS=`find "$FDK_INST_DIR/models/hspice/core/latest" -follow -name \*.hsp`
     fi
     if [ x"$HSPICED_MODELS_FPATHS" = x ]
     then unset HSPICED_MODELS_FPATHS
     else export HSPICED_MODELS_FPATHS
     fi
fi
if [ x"$SPECTRE_MODELS_FPATHS" = x ]
then if [ x"$SPECTRE_MODELS_FPATHS" = x ]
     then SPECTRE_MODELS_FPATHS=`find "$FDK_FOSSIL/models/dot${FDK_DOTPROC}/spectre/core/$UPF_VERSION" -follow -name \*.scs`
     else SPECTRE_MODELS_FPATHS=`find "$FDK_INST_DIR/models/spectre/core/latest" -follow -name \*.scs`
     fi
     if [ x"$SPECTRE_MODELS_FPATHS" = x ]
     then unset SPECTRE_MODELS_FPATHS
     else export SPECTRE_MODELS_FPATHS
     fi
fi

############################################################
#   Prepare our cds.lib file
############################################################
cds_lib_fpath="$WORK_DIRPATH/cds.lib"
if echo 'INCLUDE $FDK_CDSLIB' >"$cds_lib_fpath"
then echo "UNDEFINE $LIB_NAME" >>"$cds_lib_fpath"
     echo "DEFINE $LIB_NAME $TARGET_LIB_DIRPATH" >>"$cds_lib_fpath"
else echo "ERROR: Couldn't create file '$cds_lib_fpath'" 1>&2
     exit 1
fi

############################################################
#   Execute our SKILL pruning script
############################################################
prunelib_il_fpath="$EXEC_DIRPATH/pruneLib.il"
if [ -r "$prunelib_il_fpath" ]; then :; else
  echo "ERROR: pruneLib.il SKILL script is not found in build script dir '$EXEC_DIRPATH'" 1>&2
  exit 1
fi
prunelib_cds_log_fpath="$WORK_DIRPATH/pruneLib-CDS.log"
echo -n "Pruning ${LIB_NAME}..."
if ( cd "$WORK_DIRPATH" && virtuoso -nograph -cdslib "$WORK_DIRPATH/cds.lib" -replay "$prunelib_il_fpath" -log "$prunelib_cds_log_fpath" )
then :; else
  echo "ERROR"
  exit 1
fi

############################################################
#   Tell caller about any issues reported in CDS session
############################################################
grep '^\\e ' "$prunelib_cds_log_fpath" | sort | uniq
echo "Done; Check '$prunelib_cds_log_fpath' for details"

############################################################
#   Update permissions again just in case one of
#   intermediate steps messed them up
############################################################
if find "$TARGET_LIB_DIRPATH" -type d -exec chmod u=rwx,g=rx,o= \{} \; -o -type f -exec chmod u=rw,g=r,o= \{} \;
then :; else
  echo "ERROR: Set canonical file/directory access permissions" 1>&2
  exit 1
fi
echo "Set canonical file/directory access permissions"

############################################################
#   Do final cleaning step on pruned library
#   to make sure we didn't accidentally add some crap
#   during the prune session
############################################################
if find "$TARGET_LIB_DIRPATH" \
     -type d -name .SYNC -exec rm -fr \{} \; -prune -o \
     -type d -name 'zpcell*' -print -prune -o \
     -type d -empty -print -o \
     -type f -name '*.cdslck' -print -o \
     -type f -name '*-' -print -o \
     -type f -name '*%' -print -o \
     -type f -name '*.syncmd' -print -o \
     -type f -name '.lock' -print \
   | xargs rm -fr
then :; else
  echo "ERROR: Couldn't do final file clean step." 1>&2
  exit 1
fi
echo "Final file clean step finished"
echo "...Done"

exit 0
