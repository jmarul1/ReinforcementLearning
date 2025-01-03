#!/usr/bin/env perl

##############################################################################
## Intel Top Secret                                                         ##
##############################################################################
## Copyright (C) 2013, Intel Corporation.  All rights reserved.             ##
##                                                                          ##
## This is the property of Intel Corporation and may only be utilized       ##
## pursuant to a written Restricted Use Nondisclosure Agreement             ##
## with Intel Corporation.  It may not be used, reproduced, or              ##
## disclosed to others except in accordance with the terms and              ##
## conditions of such agreement.                                            ##
##                                                                          ##
## All products, processes, computer systems, dates, and figures            ##
## specified are preliminary based on current expectations, and are         ##
## subject to change without notice.                                        ##
##############################################################################

use strict;
use warnings;

# $Header: /nfs/pdx/disks/icf_f1273_dsvault001/sync_vault/server_vault/Projects/fdk73/oalibs/common/custom/build_scripts/rcgen.pl.rca 1.29 Thu Sep  3 16:47:53 2015 kflowers Experimental $
our $VERSION = '$Revision: 1.29 $';
$VERSION =~ s/^\$\s*Revision:\s*//;
$VERSION =~ s/\s*\$$//;
# $KeysEnd$

use Cwd;
use Data::Dumper;
$Data::Dumper::Indent = 2;
use File::Basename;
use File::Compare;
use File::Copy;
use File::Copy::Recursive qw(dircopy);
use File::Find;
use File::Path;
use File::Spec;
use FindBin;
use Getopt::Long qw(:config permute);
use Text::CSV;

##############################################################################
##   env var values
##############################################################################
sub check_env_var ($) {
  my ($env_var_nm) = @_;
  my $env_var_val;
  if (exists($ENV{$env_var_nm})) {
    $env_var_val = $ENV{$env_var_nm};
    undef $env_var_val if ($env_var_val =~ m/^\s*$/);
  }
  if (!defined($env_var_val)) {
    printf STDERR "ERROR: %s env var is not defined.\n", $env_var_nm;
    exit 1
  }
  return $env_var_val;
}
my $cdshome = check_env_var("CDSHOME");
my $d8lib_vers = check_env_var("D8LIB_VERSION");
my $fdk_dotproc = check_env_var("FDK_DOTPROC");
my $fdk_managed_area = check_env_var("FDK_MANAGED_AREA");
my $fdk_oalib_type = check_env_var("FDK_OALIB_TYPE");
my $kit_nm = check_env_var("KIT_NAME");
my $pck_build = check_env_var("PCK_BUILD");
my $pck_utils = check_env_var("PCK_UTILS");
my $process_nm = check_env_var("PROCESS_NAME");
my $user_nm = check_env_var("USER");

##############################################################################
##   command line options
##############################################################################
my $lib_nm = 'intel73custom';

my $master_lib_dirpath = 
  sprintf(
    "%s/fdk73/oalibs/common/custom/%s/%s",
    $fdk_managed_area, $d8lib_vers, $lib_nm
  );

my $package_dirpath =
  sprintf(
    "%s/fdk73/oalibs/common/custom/package",
    $fdk_managed_area
  );

my $rc_libInit_scriptpath =
  sprintf(
    "%s/fdk73/oalibs/common/custom/build_scripts/lib/libInit.il",
    $fdk_managed_area
  );

my $rc_autoLoad_scriptpath =
  sprintf(
    "%s/fdk73/oalibs/common/custom/build_scripts/lib/autoLoad.file",
    $fdk_managed_area
  );

my $tclcompiler_execpath = "/p/fdk/eda/activestate/ActiveTDK/5.3.0/bin/tclcompiler84";

my $work_dirpath = 
  sprintf(
    "%s/fdk73/oalibs/common/custom/%s/build/work/p%s/%s",
    $fdk_managed_area, $d8lib_vers, $fdk_dotproc, $fdk_oalib_type
  );

my $dest_dirpath = 
  sprintf(
    "%s/fdk73/oalibs/common/custom/%s/build/lib/p%s/%s",
    $fdk_managed_area, $d8lib_vers, $fdk_dotproc, $fdk_oalib_type
  );

### Gets set to 1 by default if FDK_OALIB_TYPE env var is "pycell", 0 otherwise
my $pycell_flag = ($ENV{FDK_OALIB_TYPE} && ($ENV{FDK_OALIB_TYPE} =~ m/^pycell$/i));

my $prune_flag = 1;

my $prune_lib_scriptpath =
  sprintf(
    "%s/fdk73/oalibs/common/custom/build_scripts/lib/pruneLib.il",
    $fdk_managed_area
  );

sub usage ($) {

  my ($ev) = @_;

  print <<__EOF__;
Usage:

  $FindBin::Script [ -help ]
    Generates this message.

    or

  $FindBin::Script \\
    [ -genrclib ] \\
    [ -masterlib=$lib_nm ] \\
    [ -masterlibdir=$master_lib_dirpath ] \\
    [ -packagedir=$package_dirpath ] \\
    [ -rclibinitscript=$rc_libInit_scriptpath ] \\
    [ -rclibautoloadscript=$rc_autoLoad_scriptpath ] \\
    [ -tclcompiler=$tclcompiler_execpath ] \\
    [ -workdir=$work_dirpath ] \\
    [ -destdir=$dest_dirpath ] \\
    [ -pycell | -nopycell ] \\
    [ -noprune ] \\
    [ -prunelibscript=$prune_lib_scriptpath ]

__EOF__

  exit $ev;

}

my $genrclib_flag;
GetOptions(
  'help|?' => sub { usage(0); },
  'genrclib' => sub { $genrclib_flag = 1; },
  'masterlib=s' => \$lib_nm,
  'masterlibdir=s' => \$master_lib_dirpath,
  'packagedir=s' => \$package_dirpath,
  'rclibinitscript=s' => \$rc_libInit_scriptpath,
  'rclibautoloadscript=s' => \$rc_autoLoad_scriptpath,
  'tclcompiler=s' => \$tclcompiler_execpath,
  'workdir=s' => \$work_dirpath,
  'destdir=s' => \$dest_dirpath,
  'pycell' => sub { $pycell_flag = 1; },
  'nopycell' => sub { $pycell_flag = 0; },
  'noprune' => sub { $prune_flag = 0; },
  'prunelibscript=s' => \$prune_lib_scriptpath
  ) or do {
  printf STDERR "ERROR: parsing command-line\n";
  usage(1);
};
usage(0) if !$genrclib_flag;

### Sanity check master lib path
if (! -d $master_lib_dirpath) {
  printf STDERR "ERROR: No such master lib directory '%s'\n", $master_lib_dirpath;
  exit(1);
}
if (! -r sprintf("%s/cdsinfo.tag", $master_lib_dirpath)) {
  printf STDERR "ERROR: Didn't find cdsinfo.tag file at -masterlibdir '%s'\n", $master_lib_dirpath;
  exit(1);
}
if (! -d $package_dirpath) {
  printf STDERR "ERROR: No such package directory '%s'\n", $package_dirpath;
  exit(1);
}
if (! -r $rc_libInit_scriptpath) {
  printf STDERR "ERROR: Couldn't find libInit.il file '%s'\n", $rc_libInit_scriptpath;
  exit(1);
}
if (! -r $rc_autoLoad_scriptpath) {
  printf STDERR "ERROR: Couldn't find autoLoad.file file '%s'\n", $rc_autoLoad_scriptpath;
  exit(1);
}
if (! -x $tclcompiler_execpath) {
  printf STDERR "ERROR: Couldn't find Tcl compiler script '%s'\n", $tclcompiler_execpath;
  exit(1);
}
if (! -d $work_dirpath) {
  mkpath($work_dirpath, 1, 0770) or
    die("ERROR ($!): mkpath $work_dirpath");
}
if (! -d $dest_dirpath) {
  mkpath($dest_dirpath, 1, 0770) or
    die("ERROR ($!): mkpath $dest_dirpath");
}
if (! -r $prune_lib_scriptpath) {
  printf STDERR "ERROR: Couldn't find SKILL pruning script '%s'\n", $prune_lib_scriptpath;
  exit(1);
}

##############################################################################
##   remove_lib_dir
##############################################################################
sub remove_lib_dir ($) {

  my ($dp) = @_;

  printf "Removing existing '%s' directory...\n", $dp;

  ### Use File::Find to override permissions where necessary
  File::Find::find({
      wanted => sub {
        my $fpath = $File::Find::name;
        if (-d $fpath) {
          chmod(0750, $fpath) or die("ERROR ($!) chmod 0750 $fpath");
        } else {
          chmod(0640, $fpath) or die("ERROR ($!) chmod 0640 $fpath");
        }
      }
    },
    $dp
  );

  rmtree($dp) or die("ERROR ($!): rmtree $dp");

  print "...Done\n";

}

##############################################################################
##   copy_master_lib_to_work_dir
##############################################################################
sub copy_master_lib_to_work_dir ($$$) {

  my ($src, $dst, $lnm) = @_;

  my $lib_dirpath = File::Spec->catdir($dst, $lnm);

  # Go ahead and copy the master library to the specified work directory
  printf "Copying '%s' to '%s'...\n", $src, $lib_dirpath;

  { local $File::Copy::Recursive::RMTrgDir = 1;
    local $File::Copy::Recursive::KeepMode = 0;
    local $File::Copy::Recursive::CopyLink = 0;
    dircopy($src, $lib_dirpath) or
      die("ERROR ($!): dircopy($src, $lib_dirpath)"); }

  # Get rid of any extra autoload stuff from the master lib
  my $unwanted_libInit_fpath = File::Spec->catfile($lib_dirpath, 'libInit.il');
  if (-w $unwanted_libInit_fpath) {
    unlink($unwanted_libInit_fpath) or
      die("ERROR ($!): unlink $unwanted_libInit_fpath");
  }
  my $unwanted_libcxt_dirpath = File::Spec->catdir($lib_dirpath, 'lib.cxt');
  if (-w $unwanted_libcxt_dirpath) {
    rmtree($unwanted_libcxt_dirpath) or
      die("ERROR ($!): rmtree $unwanted_libcxt_dirpath");
  }
  my $unwanted_autoLoad_fpath = File::Spec->catfile($lib_dirpath, 'autoLoad.file');
  if (-w $unwanted_autoLoad_fpath) {
    unlink($unwanted_autoLoad_fpath) or
      die("ERROR ($!): unlink $unwanted_autoLoad_fpath");
  }
  my $unwanted_libtcl_dirpath = File::Spec->catdir($lib_dirpath, 'lib_tcl.dir');
  if (-w $unwanted_libtcl_dirpath) {
    rmtree($unwanted_libtcl_dirpath) or
      die("ERROR ($!): rmtree $unwanted_libtcl_dirpath");
  }

  print "...Done\n";
  
  return $lib_dirpath;

}

##############################################################################
##   clean_lib_dir
##############################################################################
sub clean_lib_dir ($) {

  my ($lib_dirpath) = @_;
  
  ### Clean & simultaneously set permissions
  ### so that pruning operation will run smoothly
  printf "Cleaning '%s' & setting file/dir permissions...\n", $lib_dirpath;

  File::Find::find({
      wanted => sub {
        my $fpath = $File::Find::name;

        ### If a directory,
        if (-d $fpath) {
          my $dname = basename($fpath);

          ### Remove .SYNC directories quietly
          if ($dname eq '.SYNC') {
            rmtree($fpath) or die("ERROR ($!): rmtree $fpath");
            $File::Find::prune = 1;

          ### Remove pcell-gen directories noisily
          } elsif ($dname =~ m/^zpcell/) {
            printf STDERR "WARNING: Temp directory '%s' found in master library.\n", $fpath;
            rmtree($fpath) or die("ERROR ($!): rmtree $fpath");
            $File::Find::prune = 1;

          ### Give everything else desired permissions
          } else {
            chmod(0750, $fpath) or die("ERROR ($!) chmod 0750 $fpath");
          }

        ### Otherwise, if a file,
        } else {
          my $fname = basename($fpath);
          my $parent_dirpath = dirname($fpath);
          my $parent_dirname = basename($parent_dirpath);

          ### Skip over .SYNC directoreis
          return if ($parent_dirname eq '.SYNC');

          ### Remove .png files quietly (since there's so many of them)
          if ($fname =~ m/\.png$/) {
            unlink($fpath) or die("ERROR ($!): unlink $fpath");
            return;
          }

          ### Report that we are removing these files, but not an error
          if (($fname =~ m/\.cdslck/)
           || ($fname =~ m/\.syncmd$/)
           || ($fname =~ m/[-%]$/)
           || ($fname =~ m/\.lock/)
           || ($fname eq '.recent_files')
          ) {
            printf "Removed '%s'\n", $fpath;
            unlink($fpath) or die("ERROR ($!): unlink $fpath");
            return;
          }

          ### Keep any of these files & set them to reasonable permissions,
          if (($fname eq '.cdslibrary')
           || ($fname eq '.oalib')
           || ($fname =~ m/\.Cat$/)
           || ($fname =~ m/\.TopCat$/)
           || ($fname eq 'cdsinfo.tag')
           || ($fname eq 'cph.lam')
           || ($fname eq 'data.dm')
           || ($fname =~ m/\.il$/)
           || ($fname =~ m/\.il[es]$/)
           || ($fname =~ m/\.cxt$/)
           || ($fname eq 'autoLoad.file')
           || ($fname =~ m/\.tcl$/)
           || ($fname =~ m/\.tbc$/)
           || ($fname =~ m/\.zip$/)
           || ($fname eq 'master.tag')
           || ($fname eq 'pc.db')
           || ($fname =~ m/\.oa$/)
           || ($fname =~ m/\.cdb$/)
          ) {
            chmod(0640, $fpath) or die("ERROR ($!) chmod 0640 $fpath");
            return;
          }

          ### Remove any other files noisily
          printf STDERR "WARNING: Unexpected file named '%s' found in master library.\n", $fpath;
          unlink($fpath) or die("ERROR ($!): unlink $fpath");

          return;

        }
      }
    },
    $lib_dirpath
  );

  print "...Done\n";

}

##############################################################################
##   prune_work_lib
##############################################################################
use constant PRUNE_STEP_ID => 'prune';
sub prune_work_lib ($$$) {

  my ($work_dirpath, $lnm, $work_lib_dirpath) = @_;

  ### Prepare work area for pruning operation
  my $prune_build_workDir = File::Spec->catdir($work_dirpath, PRUNE_STEP_ID);
  rmtree($prune_build_workDir) if (-w $prune_build_workDir);
  mkpath($prune_build_workDir) or die("ERROR ($!): mkpath $prune_build_workDir");

  printf "Preparing pruning environment for library '%s'\n", $lnm;
  printf "in work directory '%s'\n", $prune_build_workDir;

  my $old_cwd = getcwd();
  chdir($prune_build_workDir) or die("ERROR ($!): chdir $prune_build_workDir");

  ### Define quickie cds.lib file
  open(my $cdslib_fh, '>', 'cds.lib') or die("ERROR ($!): open cds.lib");
  printf $cdslib_fh "INCLUDE \$FDK_CDSLIB\n";
  printf $cdslib_fh "UNDEFINE %s\n", $lnm;
  printf $cdslib_fh "DEFINE %s %s\n", $lnm, $work_lib_dirpath;
  close($cdslib_fh) or die("ERROR ($!): close cds.lib");

  ### Execute the pruning script
  printf "Pruning library '%s'...\n", $lnm;

  my $cds_log_fpath = File::Spec->rel2abs('CDS.log', $prune_build_workDir);
  my $rv = system('virtuoso', '-nograph', '-replay', $prune_lib_scriptpath, '-log', $cds_log_fpath);
  die "ERROR ($rv): $cds_log_fpath" if ($rv != 0);

  print "...Done!\n";
  
  ### restore old working directory  
  chdir($old_cwd) or die("ERROR ($!): chdir $old_cwd");
  
  ### Report any errors that occurred
  open(my $cds_log_fh, '<', $cds_log_fpath) or die("ERROR ($!): open $cds_log_fpath");
  while (my $li = <$cds_log_fh>) {
    chomp($li);
    if ($li =~ m/^\\e ([^=]+=.*)$/) {
      printf "PRUNING ERROR: %s\n", $1;
    }
  }
  close($cds_log_fh) or die("ERROR ($!): close $cds_log_fpath");

}

##############################################################################
##   compile_context_files_to_work_lib
##############################################################################
use constant CXT_STEP_ID => 'compile_cxt';
sub compile_context_files_to_work_lib ($$$) {

  my ($work_dirpath, $lnm, $work_lib_dirpath) = @_;

  ### Prepare work area for context-compilation operation
  my $cxt_build_workDir = File::Spec->catdir($work_dirpath, CXT_STEP_ID);
  rmtree($cxt_build_workDir) if (-w $cxt_build_workDir);
  mkpath($cxt_build_workDir) or die("ERROR ($!): mkpath $cxt_build_workDir");

  printf "Preparing context-compilation environment for library '%s'\n", $lnm;
  printf "in work directory '%s'\n", $cxt_build_workDir;

  my $old_cwd = getcwd();
  chdir($cxt_build_workDir) or die("ERROR ($!): chdir $cxt_build_workDir");

  ### Create quickie cds.lib file
  open(my $cdslib_fh, '>', 'cds.lib') or die("ERROR ($!): open cds.lib");
  printf $cdslib_fh "INCLUDE \$FDK_CDSLIB\n";
  printf $cdslib_fh "UNDEFINE %s\n", $lnm;
  printf $cdslib_fh "DEFINE %s %s\n", $lnm, $work_lib_dirpath;
  close($cdslib_fh) or die("ERROR ($!): close cds.lib");
  
  ### Create context-file compilation script
  my $compile_cxt_script = 'compile_cxt.il';
  my $cxt_fname = sprintf("%s.cxt", $lnm);
  open(my $script_fh, '>', $compile_cxt_script) or die("ERROR ($!): open $compile_cxt_script");
  printf $script_fh "loadContext(cdsGetToolsPath(buildString(list(getSkillVersion() \"context\" \"skillCore.cxt\") \"/\")))\n";
  printf $script_fh "callInitProc(\"skillCore\")\n";
  printf $script_fh "loadContext(prependInstallPath(buildString(list(\"etc\" \"context\" \"cdsFuncs.cxt\") \"/\")))\n";
  printf $script_fh "callInitProc(\"cdsFuncs\")\n";
  printf $script_fh "when( !errset(load(\"%s/fdk73/oalibs/common/lib/skill/loader.il\") t) exit(1) )\n", $fdk_managed_area;
  printf $script_fh "setContext(\"%s\")\n", $lnm;
  printf $script_fh "when( !fdkCustomLoad('all) exit(1) )\n";
  printf $script_fh "when( !saveContext(\"%s\") exit(1) )\n", $cxt_fname;
  printf $script_fh "exit(0)\n";
  close($script_fh) or die("ERROR ($!): close $compile_cxt_script");

  ### Create 32-bit context file
  printf "Compiling 32-bit context files for '%s'...\n", $lnm;
  my $cds_log_fpath = sprintf("%s.32bit.CDS.log", CXT_STEP_ID);
  my $rv = system('virtuoso', '-32', '-ilLoadIL', $compile_cxt_script, '-nograph', '-log', $cds_log_fpath);
  die "ERROR ($rv): $cds_log_fpath" if ($rv != 0);
  my $lib_cxt_dirpath = File::Spec->catdir($work_lib_dirpath, 'lib.cxt');
  mkpath($lib_cxt_dirpath) or die("ERROR ($!): mkpath $lib_cxt_dirpath");
  my $cxt32_fcopy_rv = File::Copy::copy($cxt_fname, $lib_cxt_dirpath);
  my $cxt32_fcopy_syserr = $!;
  print "...Done!\n";

  ### Create 64-bit context file
  printf "Compiling 64-bit context files for '%s'...\n", $lnm;
  $cds_log_fpath = sprintf("%s.64bit.CDS.log", CXT_STEP_ID);
  $rv = system('virtuoso', '-64', '-ilLoadIL', $compile_cxt_script, '-nograph', '-log', $cds_log_fpath);
  die "ERROR ($rv): $cds_log_fpath" if ($rv != 0);
  my $lib_cxt64_dirpath = File::Spec->catdir($lib_cxt_dirpath, '64bit');
  mkpath($lib_cxt64_dirpath) or die("ERROR ($!): mkpath $lib_cxt64_dirpath");
  my $cxt64_fname = File::Spec->catfile('64bit', $cxt_fname);
  my $cxt64_fcopy_rv = File::Copy::copy($cxt64_fname, $lib_cxt64_dirpath);
  my $cxt64_fcopy_syserr = $!;
  print "...Done!\n";

  ### Report if we couldn't create either context file
  if (!$cxt32_fcopy_rv) {
    if ($cxt64_fcopy_rv) {
      printf STDERR "WARNING (%s): File::Copy::copy %s %s\n", $cxt32_fcopy_syserr, $cxt_fname, $lib_cxt_dirpath;

      ### if we couldn't compile 32-bit context file,
      ### but could 64-bit, then we're probably in environment
      ### that doesn't have 32-bit installation available
      ### Cheap kludge, create symbolic link to 64-bit context file
      ### from location where 32-bit symbolic link would normally go
      { my $old_cwd = cwd();
        chdir($lib_cxt_dirpath);
        $cxt32_fcopy_rv = symlink($cxt64_fname, $cxt_fname);
        $cxt32_fcopy_syserr = $!;
        chdir($old_cwd); }

      if (!$cxt32_fcopy_rv) {
        printf STDERR "ERROR (%s): Couldn't create symbolic link to '%s'\n", $cxt32_fcopy_syserr, $cxt64_fname;
      } else {
        printf STDERR "Created symlink from %s to %s\n", $cxt64_fname, $cxt_fname;
      }

    } else {
      printf STDERR "ERROR (%s): File::Copy::copy %s %s\n", $cxt32_fcopy_syserr, $cxt_fname, $lib_cxt_dirpath;
    }
  }
  if (!$cxt64_fcopy_rv) {
    printf STDERR "ERROR (%s): File::Copy::copy %s %s\n", $cxt64_fcopy_syserr, $cxt_fname, $lib_cxt_dirpath;
  }
  exit(1) if !$cxt32_fcopy_rv || !$cxt64_fcopy_rv;

  ### Copy our release-libInit.il file into place
  File::Copy::copy($rc_libInit_scriptpath, $work_lib_dirpath) or
    die("ERROR ($!): File::Copy::copy $rc_libInit_scriptpath $work_lib_dirpath");

  ### restore old working directory  
  chdir($old_cwd) or die("ERROR ($!): chdir $old_cwd");
  
}

##############################################################################
##   compile_tcl_callback_files
##############################################################################
use constant TCL_STEP_ID => 'compile_tcl';
sub compile_tcl_callback_files ($$$) {

  my ($work_dirpath, $lnm, $work_lib_dirpath) = @_;
  my $error_flag;

  ### Prepare work area for Tcl compilation area
  my $tcl_build_workDir = File::Spec->catdir($work_dirpath, TCL_STEP_ID);
  rmtree($tcl_build_workDir) if (-w $tcl_build_workDir);
  mkpath($tcl_build_workDir) or die("ERROR ($!): mkpath $tcl_build_workDir");

  printf "Preparing Tcl-compilation environment for library '%s'\n", $lnm;
  printf "in work directory '%s'\n", $tcl_build_workDir;

  my $old_cwd = getcwd();
  chdir($tcl_build_workDir) or die("ERROR ($!): chdir $tcl_build_workDir");

  ### Find all the files in the package subdir matching the model-select-generate naming convention
  my %msgen_script_map;
  my %msgen_csv_map;
  File::Find::find({
      wanted => sub {
        my $fpath = $File::Find::name;
        if (-d $fpath) {
          my $dname = basename($fpath);
          $File::Find::prune = 1 if ($dname =~ m/^\./);
        } else {
          my $fname = basename($fpath);
          if (($fname =~ m/^fdk73px_/) && ($fname =~ m/\.sh$/)) {
            if (!(-x $fpath)) {
              printf STDERR "WARNING: Model select script '%s' is not executable - ignoring.\n", $fpath;
              $error_flag = 1;
            } else {
              my $froot = $fname; $froot =~ s/\.sh$//;
              printf "Recognized model select script '%s' in package subdir '%s'\n", $fname, $File::Find::dir;
              push @{$msgen_script_map{$froot}}, $fpath;
            }
          }
          if (($fname =~ m/^fdk73px_/) && ($fname =~ m/\.csv$/)) {
            my $froot = $fname; $froot =~ s/\.csv$//;
            printf "Recognized model select csv file '%s' in package subdir '%s'\n", $fname, $File::Find::dir;
            push @{$msgen_csv_map{$froot}}, $fpath;
          }
        }
      }
    },
    $package_dirpath
  );

  ### copy all of the model select .csv files to work dir
  foreach my $froot (sort { $a cmp $b; } (keys %msgen_csv_map)) {
    my @csv_list = @{$msgen_csv_map{$froot}};
    if (scalar(@csv_list) != 1) {
      printf STDERR "ERROR: Multiple Model Select csv files detected matching root '%s'.\n", $froot;
      $error_flag = 1;
    } else {
      if (!File::Copy::copy($csv_list[0], $tcl_build_workDir)) {
        printf STDERR "ERROR: Couldn't copy '%s' to '%s'\n", $csv_list[0], $tcl_build_workDir;
        $error_flag = 1;
      } else {
        printf "Copied '%s' to '%s'.\n", $csv_list[0], $tcl_build_workDir;
      }
    }
  }
  
  ## execute model select scripts in work dir
  foreach my $froot (sort { $a cmp $b; } (keys %msgen_script_map)) {
    my @script_list = @{$msgen_script_map{$froot}};
    if (scalar(@script_list) != 1) {
      printf STDERR "ERROR: Multiple Model Select script files detected matching root '%s'.\n", $froot;
      $error_flag = 1;
    } else {
      my $ev = system($script_list[0]);
      if ($ev != 0) {
        printf STDERR "ERROR: Exit status %d when executing model selection script '%s'\n", ($ev >> 8), $script_list[0];
        $error_flag = 1;
      } else {
        printf "Executed script '%s'\n", $script_list[0];
      }
    }
  }

  ### Find all the files in the package subdir with .tcl extension
  my %tcl_file_map;
  File::Find::find({
      wanted => sub {
        my $fpath = $File::Find::name;
        if (-d $fpath) {
          my $dname = basename($fpath);
          $File::Find::prune = 1 if ($dname =~ m/^\./);
        } else {
          my $fname = basename($fpath);
          if ($fname =~ m/\.tcl$/) {
            printf "Recognized '%s' file in package subdir '%s'\n", $fname, $File::Find::dir;
            push @{$tcl_file_map{$fname}}, $fpath;
          }
        }
      }
    },
    $package_dirpath
  );

  ### Add any local MS.tcl files created by the model-selection-generation scripts
  File::Find::find({
      wanted => sub {
        my $fpath = $File::Find::name;
        if (-d $fpath) {
          my $dname = basename($fpath);
          $File::Find::prune = 1 if ($dname =~ m/^\./);
        } else {
          my $fname = basename($fpath);
          if ($fname =~ m/MS\.tcl$/) {
            printf "Recognized '%s' file in '%s' dir\n", $fname, $File::Find::dir;
            push @{$tcl_file_map{$fname}}, $fpath;
          }
        }
      }
    },
    $tcl_build_workDir
  );

  ### Create a clean lib_tcl.dir in our work library
  my $compiled_tcl_dirpath = File::Spec->catdir($work_lib_dirpath, 'lib_tcl.dir');
  mkpath($compiled_tcl_dirpath) or die("ERROR ($!): mkpath $compiled_tcl_dirpath");

  ### Compile each .tcl file that we found and put it into the lib_tcl.dir
  foreach my $fname (keys %tcl_file_map) {

    my @fpaths = @{$tcl_file_map{$fname}};

    if (scalar(@fpaths) != 1) {

      printf STDERR "ERROR: More than one .tcl file named '%s':\n", $fname;

      foreach my $fpath (@fpaths) {
        printf STDERR "ERROR: %s\n", $fpath;
      }

      $error_flag = 1;

    } else {

      my $log_fname = $fname;
      $log_fname =~ s/\.tcl$/.log/;
      my $log_fpath = File::Spec->catfile($tcl_build_workDir, $log_fname);

      open(my $log_fh, '>', $log_fpath) or die("ERROR ($!): open > $log_fpath");

      if (my $child_pid = open(my $cmd_fh, '-|', $tclcompiler_execpath, $fpaths[0], '-out', $compiled_tcl_dirpath)) {

        if (defined($child_pid)) {

          while (my $li = <$cmd_fh>) {
            printf $log_fh "%s", $li;
          }

          close($cmd_fh) or die("ERROR ($!): close $tclcompiler_execpath");
          
          my $ev = $?;
          if ($ev != 0) {
            printf $log_fh "ERROR: Exit value %d for command line: %s %s -out %s\n", ($ev >> 8), $tclcompiler_execpath, $fpaths[0], $compiled_tcl_dirpath;
            printf STDERR "ERROR: Exit value %d for command line: %s %s -out %s\n", ($ev >> 8), $tclcompiler_execpath, $fpaths[0], $compiled_tcl_dirpath;
            $error_flag = 1;
          } else {
            printf "Compiled Tcl file '%s'\n", $fpaths[0];
          }

        } else {
          printf $log_fh "ERROR: Couldn't execute command line: %s %s -out %s\n", $tclcompiler_execpath, $fpaths[0], $compiled_tcl_dirpath;
          printf STDERR "ERROR: Couldn't execute command line: %s %s -out %s\n", $tclcompiler_execpath, $fpaths[0], $compiled_tcl_dirpath;
          $error_flag = 1;
        }

      }

      close($log_fh) or die("ERROR ($!): close $log_fpath");

    }

  }

  if ($error_flag) {
    printf STDERR "ERROR: Check .log files in dir '%s' for Tcl compilation status.\n", $tcl_build_workDir;
    exit(1);
  }

  ### Copy our release-autoLoad.file file into place
  File::Copy::copy($rc_autoLoad_scriptpath, $work_lib_dirpath) or
    die("ERROR ($!): File::Copy::copy $rc_autoLoad_scriptpath $work_lib_dirpath");

  ### restore old working directory  
  chdir($old_cwd) or die("ERROR ($!): chdir $old_cwd");
  
}

######################################################
###   extract_cell_nm_list_from_propbag_csv_file   ###
sub extract_cell_nm_list_from_propbag_csv_file ($$) {
  my ($csv_fpath, $work_lib_dirpath) = @_;
  my @cell_nm_list;
  my $csv = Text::CSV->new();
  open(my $fh, '<', $csv_fpath) or do {
    printf STDERR "ERROR: Couldn't open '%s'\n", $csv_fpath;
    return undef;
  };
  ### read to first non-blank line
  my $ln = 0;
  while (my $l = <$fh>) {
    chomp($l);
    $ln++;
    next if ($l =~ m/^\s*$/);
    if (!$csv->parse($l)) {
      printf STDERR "ERROR: CSV parsing line '%s' (row cnt %d) in file '%s'\n", $l, $ln, $csv_fpath;
      return undef;
    }
    my @fields = $csv->fields();
    my $found_hdr_row;
    for (my $i = 1; $i < scalar(@fields); $i++) {
      $found_hdr_row = 1 if ($fields[$i] !~ m/^\s*$/);
      if (($fields[$i] =~ m/^_/) && ($fields[$i] =~ m/_$/)) {
        printf STDERR "Skipping column header '%s'\n", $fields[$i];
      } else {
        my $cell_nm = $fields[$i];
        if ( -d File::Spec->catdir($work_lib_dirpath, $cell_nm) ) {
          printf STDERR "Recognized cell name '%s'\n", $cell_nm;
          push @cell_nm_list, $cell_nm;
        } else {
          printf STDERR "Cell name '%s' does not exist in lib dir.\n", $cell_nm;
        }
      }
    }
    last if defined($found_hdr_row);
  }
  close($fh) or do {
    printf STDERR "ERROR: Couldn't finish readign '%s'\n", $csv_fpath;
    return undef;
  };
  return ((scalar(@cell_nm_list) > 0) ? @cell_nm_list : undef);
}

#############################################
###   generate_and_compile_pycell_class   ###
sub generate_and_compile_pycell_class ($$$$@) {

  my ($pkg_work_dirpath, $pkg_nm, $pycell_def_fpath, $work_lib_dirpath, @cell_list) = @_;

  if ( ! ( -r "cds.lib" ) ) {

    if ( ! ( -r "template-cds.lib" ) ) {
      open(my $cdslib_fh, '>', 'template-cds.lib');
      printf $cdslib_fh "INCLUDE \$FDK_CDSLIB\n";
      printf $cdslib_fh "UNDEFINE %s\n", $lib_nm;
      printf $cdslib_fh "DEFINE %s %s\n", $lib_nm, $work_lib_dirpath;
      close($cdslib_fh);
    }

    my $rv = system("/p/foundry/fdk-env/utils/utils/flattenCdsDotLib template-cds.lib -o cds.lib; ln -s cds.lib lib.defs");

    if ( ! ( -r "cds.lib" ) || ! ( -l "lib.defs" ) ) {
      printf STDERR "ERROR: Couldn't create flattened cds.lib file & lib.defs symbolic link\n";
      return undef;
    }

  }

  ### Copy all "common" Python files into base pkg subdir
  File::Find::find({
      wanted => sub {
        my $fpath = $File::Find::name;
        if (-d $fpath) {
          my $dname = basename($fpath);
          $File::Find::prune = 1 if ($dname =~ m/^\./);
        } else {
          my $fname = basename($fpath);
          if ($fname =~ m/\.py$/) {
            if (File::Copy::copy($fpath, $pkg_work_dirpath)) {
              printf "Copied '%s' to '%s'\n", $fpath, $pkg_work_dirpath;
            } else {
              printf STDERR "ERROR: Couldn't copy '%s' to '%s'\n", $fpath, $pkg_work_dirpath;
            }
          }
        }
      }
    },
    File::Spec->catdir($package_dirpath, $lib_nm)
  );

  ### Copy the package-specific fdkPcell .py file into base subdir
  my $base_pycell_fpath = File::Spec->catfile($pkg_work_dirpath, sprintf("%s.py", $pkg_nm));
  if (!File::Copy::copy($pycell_def_fpath, $base_pycell_fpath)) {
    printf STDERR "ERROR: Couldn't copy '%s' to '%s'\n", $pycell_def_fpath, $base_pycell_fpath;
    return undef;
  }
  printf "Copied '%s' to '%s'\n", $pycell_def_fpath, $base_pycell_fpath;

  ### Do we have a symbol pycell class defined in this .py file?
  my $sym_pycell_rv = system('grep', '-q', sprintf("^class %s_sym(DloGen):", $pkg_nm), $base_pycell_fpath);
  if ( ($sym_pycell_rv >> 8) < 0 || ($sym_pycell_rv >> 8) > 1 ) {
    printf STDER "ERROR: Non-zero exit value %d testing file '%s' for presence of symbol pycell\n", ($sym_pycell_rv >> 8), $base_pycell_fpath;
    return undef;
  }

  ### Do we have a schematic pycell class defined in this .py file?
  my $sch_pycell_rv = system('grep', '-q', sprintf("^class %s_sch(DloGen):", $pkg_nm), $base_pycell_fpath);
  if ( ($sch_pycell_rv >> 8) < 0 || ($sch_pycell_rv >> 8) > 1 ) {
    printf STDER "ERROR: Non-zero exit value %d testing file '%s' for presence of schematic pycell\n", ($sch_pycell_rv >> 8), $base_pycell_fpath;
    return undef;
  }

  ### Build the "interface" definition for Pycell wrapper
  my $fpath = File::Spec->catfile($pkg_work_dirpath, '__init__.py');
  open(my $init_fh, '>', $fpath) or do {
    printf STDERR "ERROR: Couldn't create '%s'\n", $fpath;
    return undef;
  };
  
  printf $init_fh "from cni.constants import *\n\n", $pkg_nm;
  printf $init_fh "from %s import *\n\n", $pkg_nm;

  foreach my $cn (@cell_list) {
    printf $init_fh "class %s_%s(%s):\n", $pkg_nm, $cn, $pkg_nm;
    printf $init_fh "    pass\n";
    if (!$sym_pycell_rv) {
      printf $init_fh "class %s_%s_sym(%s_sym):\n", $pkg_nm, $cn, $pkg_nm;
      printf $init_fh "    pass\n";
    }
    if (!$sch_pycell_rv) {
      printf $init_fh "class %s_%s_sch(%s_sch):\n", $pkg_nm, $cn, $pkg_nm;
      printf $init_fh "    pass\n";
    }
  }

  printf $init_fh "\ndef definePcells(lib):\n";
  foreach my $cn (@cell_list) {
    printf $init_fh "   lib.definePcell(%s_%s, '%s')\n", $pkg_nm, $cn, $cn;
    printf $init_fh "   lib.definePcell(%s_%s_sym, '%s', 'symbol', 'schematicSymbol')\n", $pkg_nm, $cn, $cn
      if !$sym_pycell_rv;
    printf $init_fh "   lib.definePcell(%s_%s_sch, '%s', 'schematic', 'schematic')\n", $pkg_nm, $cn, $cn
      if !$sch_pycell_rv;
  }
  
  close($init_fh) or do {
    printf STDERR "ERROR: Couldn't finish writing to '%s'\n", $fpath;
    return undef;
  };

  ### Make a quickie shell wrapper so we can capture log file
  my $wrapper_fpath = File::Spec->catfile($pkg_work_dirpath, sprintf("cngenlib.%s.sh", $pkg_nm));
  open(my $wrapper_fh, '>', $wrapper_fpath);
  printf $wrapper_fh "cngenlib %s 2>&1 | tee cngenlib.%s.log\n", '${@+"$@"}', $pkg_nm;
  close($wrapper_fh);

  ### Execute wrapper
  my $es = system('bash', '-v', $wrapper_fpath, '--verbose', '--update', '--bundle=encrypted_source',
                  '--no_core_dlos', sprintf("pkg:%s", $pkg_nm), $lib_nm, $work_lib_dirpath);

  if ($es != 0) {
    printf STDERR "ERROR: Non-zero exit status %d executing 'cngenlib' command line.\n", ($es >> 8);
    return undef;
  }
  printf "Executed cngenlib step for package '%s'\n", $pkg_nm;
  
  my $pkg_zip_fpath = File::Spec->catfile($work_lib_dirpath, sprintf("%s.zip", $pkg_nm));
  if ( ! -r $pkg_zip_fpath ) {
    printf STDERR "ERROR: Couldn't find %s.zip file resulting from pycell compilation.\n", $pkg_nm;
    return undef;
  }

  return 1

}

##############################################################################
##   compile_pycell_definitions
##############################################################################
use constant PYCELL_STEP_ID => 'compile_pycell';
sub compile_pycell_definitions ($$$) {

  my ($work_dirpath, $lnm, $work_lib_dirpath) = @_;

  ### Prepare work area for Tcl compilation area
  my $pycell_build_workDir = File::Spec->catdir($work_dirpath, PYCELL_STEP_ID);
  rmtree($pycell_build_workDir) if (-w $pycell_build_workDir);
  mkpath($pycell_build_workDir) or die("ERROR ($!): mkpath $pycell_build_workDir");

  printf "Preparing Pycell-compilation environment for library '%s'\n", $lnm;
  printf "in work directory '%s'\n", $pycell_build_workDir;

  my $old_cwd = getcwd();
  chdir($pycell_build_workDir) or die("ERROR ($!): chdir $pycell_build_workDir");

  ### Find all the files in the package subdir matching the
  ### property bag & Pycell naming convention
  my %propbag_csv_map;
  my %pycell_def_map;
  File::Find::find({
      wanted => sub {
        my $fpath = $File::Find::name;
        if (-d $fpath) {
          my $dname = basename($fpath);
          $File::Find::prune = 1 if ($dname =~ m/^\./);
        } else {
          my $fname = basename($fpath);
          if (($fname !~ m/^fdk73px_/) && ($fname =~ m/^([^\.]+)\.csv$/)) {
            my $pkg_nm = $1;
            printf "Recognized prop bag .csv file '%s' in package dir '%s'\n", $fname, $File::Find::dir;
            push @{$propbag_csv_map{$pkg_nm}}, $fpath;
          }
          if (($fname =~ m/^fdkPycell_([^\.]+)\.py$/)) {
            my $pkg_nm = $1;
            printf "Recognized pycell code file '%s' in package dir '%s'\n", $fname, $File::Find::dir;
            push @{$pycell_def_map{$pkg_nm}}, $fpath;
          }
        }
      }
    },
    $package_dirpath
  );

  ### For each of the Pycell packages that we find
  my $error_flag;

  foreach my $pkg_nm (sort { $a cmp $b; } (keys %pycell_def_map)) {

    my @pycell_def_list = @{$pycell_def_map{$pkg_nm}};

    if (scalar(@pycell_def_list) > 1) {
      printf STDERR "ERROR: Multiple fdkPycell_%s.py files detected in package directory.\n", $pkg_nm;
      $error_flag = 1;
      next;
    }
    my $pycell_def_fpath = $pycell_def_list[0];
    printf "Package '%s' Pycell definition file '%s'\n", $pkg_nm, $pycell_def_fpath;

    my @propbag_csv_list = @{$propbag_csv_map{$pkg_nm}};
    if (scalar(@propbag_csv_list) > 1) {
      printf STDERR "ERROR: Multiple %s.csv files detected in package directory.\n", $pkg_nm;
      $error_flag = 1;
      next;
    }
    my $propbag_csv_fpath = $propbag_csv_list[0];
    printf "Package '%s' property bag file '%s'\n", $pkg_nm, $propbag_csv_fpath;

    my $pkg_work_dirpath = File::Spec->catdir($pycell_build_workDir, $pkg_nm);
    if (!mkpath($pkg_work_dirpath)) {
      printf STDERR "ERROR: Couldn't create '%s' dir\n", $pkg_work_dirpath;
      $error_flag = 1;
      next;
    }
    printf "Created Pycell package work directory '%s'\n", $pkg_work_dirpath;

    my @cell_list = extract_cell_nm_list_from_propbag_csv_file($propbag_csv_fpath, $work_lib_dirpath);
    if (!scalar(@cell_list)) {
      $error_flag = 1;
      next;
    }
    
    if (scalar(@cell_list) > 0) {
      if (!generate_and_compile_pycell_class($pkg_work_dirpath, $pkg_nm, $pycell_def_fpath, $work_lib_dirpath, @cell_list)) {
        $error_flag = 1;
        next;
      }
    } else {
      printf STDERR "No cell names associated with package '%s'\n", $pkg_nm;
    }

  }

  if ($error_flag) {
    printf STDERR "ERROR: Check .log files in dir '%s' for Pycell compilation status.\n", $pycell_build_workDir;
    exit(1);
  }

  ### restore old working directory  
  chdir($old_cwd) or die("ERROR ($!): chdir $old_cwd");

}

##############################################################################
##   check_cdsinfo_tag_file
##############################################################################
sub check_cdsinfo_tag_file ($) {

  my ($lib_dirpath) = @_;

  my $gold_cdsinfo_tag_fpath = File::Spec->catfile($pck_utils, 'cdsinfo.tag');
  my $cmp_cdsinfo_tag_fpath = File::Spec->catfile($lib_dirpath, 'cdsinfo.tag');

  die "ERROR: File '$cmp_cdsinfo_tag_fpath' does not match gold reference '$gold_cdsinfo_tag_fpath'"
    if (File::Compare::compare_text($cmp_cdsinfo_tag_fpath, $gold_cdsinfo_tag_fpath) != 0);

  printf "File '%s' matches gold reference.\n", $cmp_cdsinfo_tag_fpath;

}

##############################################################################
##   move_work_lib_to_dest
##############################################################################
sub move_work_lib_to_dest ($$$) {

  my ($src, $dst, $lnm) = @_;
  
  # Get rid of anything existing
  my $dest_lib_dirpath = File::Spec->catdir($dst, $lnm);
  remove_lib_dir($dest_lib_dirpath) if (-d $dest_lib_dirpath);

  # Try and rename library from the work lib,
  # use recursive-move if that doesn't work.
  printf "Moving '%s' to '%s'...\n", $src, $dest_lib_dirpath;

  rename($src, $dest_lib_dirpath) or
  File::Copy::Recursive::rmove($src, $dest_lib_dirpath) or
    die("ERROR ($!): File::Copy::Recursive::rmove $src $dest_lib_dirpath");

  print "...Done\n";

}

##############################################################################
##   MAIN
##############################################################################
MAIN: {

  printf "%s - %s\n\n", $FindBin::Script, $VERSION;
  
  remove_lib_dir($work_dirpath) if (-d $work_dirpath);

  my $work_lib_dirpath = copy_master_lib_to_work_dir($master_lib_dirpath, $work_dirpath, $lib_nm);

  clean_lib_dir($work_lib_dirpath);

  prune_work_lib($work_dirpath, $lib_nm, $work_lib_dirpath) if $prune_flag;

  compile_context_files_to_work_lib($work_dirpath, $lib_nm, $work_lib_dirpath);

  if ($pycell_flag) {
    compile_tcl_callback_files($work_dirpath, $lib_nm, $work_lib_dirpath);
    compile_pycell_definitions($work_dirpath, $lib_nm, $work_lib_dirpath);
  }

  ### Clean again to handle any extra stuff
  ### that appeared while creating context files or pruning
  clean_lib_dir($work_lib_dirpath);

  check_cdsinfo_tag_file($work_lib_dirpath);

  move_work_lib_to_dest($work_lib_dirpath, $dest_dirpath, $lib_nm);

  exit(0);
}

__END__
