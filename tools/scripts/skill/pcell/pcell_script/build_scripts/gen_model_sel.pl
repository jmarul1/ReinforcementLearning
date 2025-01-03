#!/usr/bin/env perl

##############################################################################
## Intel Top Secret                                                         ##
##############################################################################
## Copyright (C) 2014, Intel Corporation.  All rights reserved.             ##
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

use Data::Dumper;
$Data::Dumper::Indent = 2;
use FindBin;
use Getopt::Long;
use Text::CSV;

my @ordered_param_nm_list;
my @output_param_nm_list;
my $model_sel_fun_name;
my $model_sel_csv_fname;
my @model_sel_list_field_names;
my $dotprocess;

###########################
###   parse_model_sel_csv_file   ###
sub parse_model_sel_csv_file ($) {

  my ($fpath) = @_;

  my @col_hdrs;
  my %hash_tree;

  my $csv = Text::CSV->new( { binary => 1 } );
  if ( ! $csv ) {
    printf STDERR "ERROR: Couldn't initialize Text::CSV package.\n";
    exit(1);
  }
  
  open(my $fh, '<', $fpath) or do {
    printf STDERR "ERROR: Couldn't open file '%s' for reading\n", $fpath;
    exit(1);
  };

  my $ln = 0;
  LINE: while (my $li = <$fh>) {
    chomp($li);
    $ln++;

    if (!$csv->parse($li)) {
      printf STDERR "ERROR: Syntax error at line %d in file '%s'\n", $ln, $fpath;
      next;
    }
    
    if (!scalar(@col_hdrs)) {
      @col_hdrs = $csv->fields();
      printf "Column headers = %s\n", "@col_hdrs";
    } else {
      my %rec;
      my @ws = $csv->fields();
      if (scalar(@ws) != scalar(@col_hdrs)) {
        printf STDERR "ERROR: # of columns at line %d in file '%s' doesn't match # of columns from header.\n", $ln, $fpath;
        next;
      } else {
        for (my $i = 0; $i < scalar(@col_hdrs); $i++) {
          my $hdr_nm = $col_hdrs[$i];
          if ($hdr_nm eq 'status') {
            if (! $ws[$i]) {
              printf "Skipping line %d in file '%s' because status='%s'\n", $ln, $fpath, $ws[$i];
              next LINE;
            }
          } elsif ($hdr_nm =~ m/\Ap\d+\Z/) {
            if (defined($dotprocess)) {
              if (($hdr_nm =~ m/\A$dotprocess\Z/) && (! $ws[$i])) {
                printf "Skipping line %d in file '%s' because %s='%s'\n", $ln, $fpath, $hdr_nm, $ws[$i];
                next LINE;
              }
            }
          } else {
            $rec{$hdr_nm} = $ws[$i];
          }
        }
        my %v = %rec;
        my $ix_str="";
        foreach my $param_nm (@ordered_param_nm_list) {
          $ix_str .= sprintf("{'%s'}", $rec{$param_nm});
          delete $v{$param_nm};
        }
        my $cmd_line = sprintf('push @{$hash_tree%s}, \\%%v', $ix_str);
        eval $cmd_line;
      }
    }
  }
  
  close($fh) or do {
    printf STDERR "ERROR: while reading file '%s'\n", $fpath;
    exit(1);
  };
  
  return %hash_tree;

}

###################################
###   dump_hash_tree_as_skill   ###
sub dump_hash_tree_as_skill {

  my ($fh, $hash_tree_ref, $ordered_param_nm_list_ref, $indent_str) = @_;
  
  if (scalar(@{$ordered_param_nm_list_ref}) > 0) {
    my @sub_ordered_param_nm_list = @{$ordered_param_nm_list_ref};
    my $param_nm = shift @sub_ordered_param_nm_list;
    my @hash_tree_ref_keys = sort { $a cmp $b; } (keys %{$hash_tree_ref});
    if (scalar(@hash_tree_ref_keys) > 1) {
      if ($param_nm =~ m/^cell$/i) {
        printf $fh "%scase( CELL\n", $indent_str, $param_nm;
      } else {
        printf $fh "%scase( cdfId->%s->value\n", $indent_str, $param_nm;
      }
      foreach my $key (@hash_tree_ref_keys) {
        printf $fh "%s  ( \"%s\"\n", $indent_str, $key;
        my $sub_hash_tree_ref = $hash_tree_ref->{$key};
        dump_hash_tree_as_skill($fh, $sub_hash_tree_ref, \@sub_ordered_param_nm_list, $indent_str . '    ');
        printf $fh "%s  )\n", $indent_str;
      }
      printf $fh "%s  ( 't err('%sErr) )\n", $indent_str, $model_sel_fun_name;
      printf $fh "%s)\n", $indent_str;
    } else {
      my $k = $hash_tree_ref_keys[0];
      if ($param_nm !~ m/^cell$/i) {
        printf $fh "%scdfId->%s->value = \"%s\"\n", $indent_str, $param_nm, $k;
      }
      dump_hash_tree_as_skill($fh, $hash_tree_ref->{$k}, \@sub_ordered_param_nm_list, $indent_str);
    }
  } else {
    foreach my $vtab_ref (@{$hash_tree_ref}) {
      foreach my $k (@output_param_nm_list) {   
        if (my $v = $vtab_ref->{$k}) {
          if (grep { m/\A$k\Z/; } @model_sel_list_field_names) {
            if ($v =~ m/\s+/) {
              my @ws = grep { !m/^\s*$/; } split(/\s+/, $v);
              $v = join(',', @ws);
            }
          }
          printf $fh "%scdfId->%s->value = \"%s\"\n", $indent_str, $k, $v;
        }
      }
    }
  }

}

############################################
###   generate_skill_model_select_file   ###
sub generate_skill_model_select_file ($) {

  shift @_;
  my ($out_fpath) = @_;
  
  if (!scalar(@ordered_param_nm_list)) {
    printf STDERR "ERROR: No -ordered_param_nm_list=... command line argument specified.\n";
    exit(1);
  }
  
  if (!scalar(@output_param_nm_list)) {
    printf STDERR "ERROR: No -output_param_nm_list=... command-line argument specified.\n";
    exit(1);
  }
  
  if (!$model_sel_fun_name) {
    printf STDERR "ERROR: No -model_sel_fun_name command-line argument specified.\n";
    exit(1);
  }
  
  if (!$model_sel_csv_fname) {
    printf STDERR "ERROR: No -model_sel_csv_file command-line argument specified.\n";
    exit(1);
  }
  
  my %hash_tree = parse_model_sel_csv_file($model_sel_csv_fname);
  
  open(my $fh, '>', $out_fpath) or do {
    printf STDERR "ERROR: Couldn't open file '%s' for writing\n", $out_fpath;
    exit(1);
  };
  
  printf $fh "putd( '%s nil )\n", $model_sel_fun_name;
  printf $fh "procedure( %s(LIBRARY CELL cdfId)\n\n", $model_sel_fun_name;
  
  dump_hash_tree_as_skill($fh, \%hash_tree, \@ordered_param_nm_list, '  ');

  printf $fh ") ;end procedure %s\n", $model_sel_fun_name;

  close($fh) or do {
    printf STDERR "ERROR: Couldn't finish writing to file '%s'\n", $out_fpath;
    exit(1);
  };

}

###################################
###   dump_hash_tree_as_tcl   ###
sub dump_hash_tree_as_tcl {

  my ($fh, $hash_tree_ref, $ordered_param_nm_list_ref, $indent_str) = @_;
  
  if (scalar(@{$ordered_param_nm_list_ref}) > 0) {
    my @sub_ordered_param_nm_list = @{$ordered_param_nm_list_ref};
    my $param_nm = shift @sub_ordered_param_nm_list;
    my @hash_tree_ref_keys = sort { $a cmp $b; } (keys %{$hash_tree_ref});
    if (scalar(@hash_tree_ref_keys) > 1) {
      if ($param_nm =~ m/^cell$/i) {
        printf $fh "%sswitch -exact -- \$CELL {\n", $indent_str, $param_nm;
      } else {
        printf $fh "%sswitch -exact -- [iPDK_getParamValue %s \$inst] {\n", $indent_str, $param_nm;
      }
      foreach my $key (@hash_tree_ref_keys) {
        printf $fh "%s  \"%s\" {\n", $indent_str, $key;
        my $sub_hash_tree_ref = $hash_tree_ref->{$key};
        dump_hash_tree_as_tcl($fh, $sub_hash_tree_ref, \@sub_ordered_param_nm_list, $indent_str . '    ');
        printf $fh "%s  }\n", $indent_str;
      }
      printf $fh "%s  default { return -code error {%sErr} }\n", $indent_str, $model_sel_fun_name;
      printf $fh "%s}\n", $indent_str;
    } else {
      my $k = $hash_tree_ref_keys[0];
      if ($param_nm !~ m/^cell$/i) {
        printf $fh "%siPDK_setParamValue %s \"%s\" \$inst 0\n", $indent_str, $param_nm, $k;
      }
      dump_hash_tree_as_tcl($fh, $hash_tree_ref->{$k}, \@sub_ordered_param_nm_list, $indent_str);
    }
  } else {
    foreach my $vtab_ref (@{$hash_tree_ref}) {
      foreach my $k (@output_param_nm_list) {
        if (my $v = $vtab_ref->{$k}) {
          if (grep { m/\A$k\Z/; } @model_sel_list_field_names) {
            if ($v =~ m/\s+/) {
              my @ws = grep { !m/^\s*$/; } split(/\s+/, $v);
              $v = join(',', @ws);
            }
          }
          printf $fh "%siPDK_setParamValue %s \"%s\" \$inst 0\n", $indent_str, $k, $v;
        }
      }
    }
  }

}

############################################
###   generate_tcl_model_select_file   ###
sub generate_tcl_model_select_file ($) {

  shift @_;
  my ($out_fpath) = @_;
  
  if (!scalar(@ordered_param_nm_list)) {
    printf STDERR "ERROR: No -ordered_param_nm_list=... command line argument specified.\n";
    exit(1);
  }
  
  if (!scalar(@output_param_nm_list)) {
    printf STDERR "ERROR: No -output_param_nm_list=... command-line argument specified.\n";
    exit(1);
  }
  
  if (!$model_sel_fun_name) {
    printf STDERR "ERROR: No -model_sel_fun_name command-line argument specified.\n";
    exit(1);
  }
  
  if (!$model_sel_csv_fname) {
    printf STDERR "ERROR: No -model_sel_csv_file command-line argument specified.\n";
    exit(1);
  }
  
  my %hash_tree = parse_model_sel_csv_file($model_sel_csv_fname);
  
  open(my $fh, '>', $out_fpath) or do {
    printf STDERR "ERROR: Couldn't open file '%s' for writing\n", $out_fpath;
    exit(1);
  };

  printf $fh "package require gExt 1\n\n";

  printf $fh "proc %s {LIBRARY CELL inst} {\n", $model_sel_fun_name;
  dump_hash_tree_as_tcl($fh, \%hash_tree, \@ordered_param_nm_list, '  ');
  printf $fh "}\n";

  close($fh) or do {
    printf STDERR "ERROR: Couldn't finish writing to file '%s'\n", $out_fpath;
    exit(1);
  };

}

################
###   MAIN   ###
MAIN: {

  GetOptions(
    'dotprocess=s' => \$dotprocess,
    'ordered_param_nm_list=s@' => sub {
      shift @_;
      @ordered_param_nm_list = split(/\s*,\s*/, join(',', @_));
    },
    'output_param_nm_list=s@' => sub {
      shift @_;
      @output_param_nm_list = split(/\s*,\s*/, join(',', @_));
    },
    'model_sel_fun_name=s' => \$model_sel_fun_name,
    'model_sel_csv_file=s' => \$model_sel_csv_fname,
    'model_sel_list_field_names=s@' => sub {
      shift @_;
      @model_sel_list_field_names = split(/\s*,\s*/, join(',', @_));
    },
    'generate_skill_model_select_file=s' => \&generate_skill_model_select_file,
    'generate_tcl_model_select_file=s' => \&generate_tcl_model_select_file
  ) or do {
    printf STDERR "ERROR: Syntax error parsing '%s' command line.\n", $FindBin::Script;
    exit(1);
  };

  1;

}
