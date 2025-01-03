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
## get all the layers and merge them
set layoutIn [layout create $inGds]
foreach ii [$layoutIn layers] {
  puts $ii
  $layoutIn create layer 65000
  $layoutIn OR $ii 65000 65000.1
  $layoutIn delete layer $ii
  $layoutIn COPY 65000.1 $ii
  $layoutIn delete layer 65000.1
}
$layoutIn gdsout $inGds
