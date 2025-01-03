#!/usr/bin/env tcl

## assign the input
set inGds [lindex $argv 0] 
## open the layout
set layoutIn [layout create $inGds] 
## flatten the layout by copying to a new variable
layout copy $layoutIn outLayout 
## assign the outLayout handle to a variable
set out outLayout 
## replace the file with flatten layout
$out gdsout $inGds 
