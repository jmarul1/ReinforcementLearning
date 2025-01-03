# $Revision: 1.6 $
# $KeysEnd$

package require gExt 1

proc _fdkCdf_mimcap_sclCB { lib cell inst stacked } {

  fdkCdfDebug 3 ">> ENTERING fdkCdfMimcap_sclCB <<\n"

  set libdd      [oa::LibFind $lib]
  oa::getAccess  $libdd read 1
  set tfId       [oa::TechOpen $libdd "r"]
  set mfgGrid    [expr {[techGetParam $tfId "mfgGrid"]*1e-6}]

  ## Get all cdf defaults and property bag values (assume PB/default are real numbers)
  set model [iPDK_getParamValue model $inst]
  set celldd [oa::DMDataOpen [oa::CellFind [oa::LibFind $lib] $cell] r]
  fdkGetPropTable drTable $celldd "designRules"
  set Crmimcap	     [expr [db::engToSci $drTable(Crmimcap) -precision 12] * 1e-3]
  set Rmimcap	     [db::engToSci $drTable(Rmimcap) -precision 12]
  set L1scale	     [db::engToSci $drTable(L1scale) -precision 12]
  set L2L3scale      [db::engToSci $drTable(L2L3scale) -precision 12]
  set mimViaOffset   [expr {[db::engToSci $drTable(MIMSpaceVia)  -precision 12] * 1e-6}]
  set um_ovlp        [expr {[db::engToSci $drTable(upperMetal:overlap) -precision 12] * 1e-6}]
  set um_space       [expr {[db::engToSci $drTable(upperMetal:space) -precision 12] * 1e-6}]
  set mimMinWidth    [expr {[db::engToSci $drTable(MIMMinWidth) -precision 12] * 1e-6}]
  set mimSpaceVia    [expr {[db::engToSci $drTable(MIMSpaceVia) -precision 12] * 1e-6}]
  set modelLimit     [db::engToSci $drTable(modelLimit) -precision 12]

  ## parameter boundary check and evaluation
  set mmin  	     [expr {round($drTable(mmin))}]
  set mmax  	     [expr {round($drTable(mmax))}]
  set m              [iPDK_getParamValue m $inst]
  if { [string is double -strict $m ] == 0 } {
    set m              [iPDK_getDefValue m $inst]
  }
  if { $m <= $mmin } {
    set m $mmin
  } elseif { $m >= $mmax } {
    set m $mmax
  } else {
    set m [expr {round($m)}]
  }

  ## check the width and change if its not within the limits wmin - wmax
  set wmin           [db::engToSci [iPDK_getDefValue w $inst] -precision 12]
  set wmax           [expr {[db::engToSci $drTable(wmax) -precision 12]*1e-6}]
  set w              [db::engToSci [iPDK_getParamValue w $inst] -precision 12]
  if { [string is double -strict $w] == 0 } {
    set w              [db::engToSci [iPDK_getDefValue w $inst] -precision 12]
  }
  if { $w <= $wmin } {
    set w $wmin
  } elseif { $w >= $wmax } {
    set w $wmax
  } else {
    set w [fdkSnapGrid $mfgGrid $w]
  }

  ## ldrawn viaOffsetR viaOffsetL are Strings right now - make them numbers, use and then change back to String.
  set ldmin 	     [db::engToSci [iPDK_getDefValue ldrawn $inst] -precision 12]
  set ldmax 	     [expr {[db::engToSci $drTable(ldmax) -precision 12]*1e-6}]
  ## check the length and change if its not within the limits lmin - lmax
  set ldrawn         [db::engToSci [iPDK_getParamValue ldrawn $inst] -precision 12]
  if { [string is double -strict $ldrawn] == 0 } {
    set ldrawn         [db::engToSci [iPDK_getDefValue ldrawn $inst] -precision 12]
  }
  if { $ldrawn <= $ldmin } {
    set ldrawn $ldmin
  } elseif { $ldrawn >= $ldmax } {
    set ldrawn $ldmax
  } else {
    set ldrawn [fdkSnapGrid $mfgGrid $ldrawn]
  }

  ## get new viaLeftMax based on current L and minimumViaRightOffset (give priority to Length)
  set viaType [iPDK_getParamValue viaType $inst]
  set viaWidth [expr [db::engToSci $drTable(viaType:${viaType}:width) -precision 12] * 1e-6]
  set viaLength [expr [db::engToSci $drTable(viaType:${viaType}:length) -precision 12] * 1e-6]
  set MIMgap [expr [db::engToSci $drTable(MIMBspace) -precision 12] * 1e-6]

  set minViaOffsetL [db::engToSci [iPDK_getDefValue viaOffsetL $inst] -precision 12]
  set minViaOffsetR [db::engToSci [iPDK_getDefValue viaOffsetR $inst] -precision 12]

  set maxViaOffsetL [expr {$ldrawn-$minViaOffsetR-2*($viaLength/2.0+$um_ovlp)+$um_space}]
  set temp [expr {$ldrawn/(1+$modelLimit)+2*($viaLength/2+$mimSpaceVia)-$minViaOffsetR}]
  if { $temp <= $maxViaOffsetL } { set maxViaOffsetL $temp }

  if { $stacked != 0 } {
    set temp [expr {$ldrawn/2 - ($MIMgap/2.0+$mimMinWidth+$mimSpaceVia+$viaLength/2.0)}]
    if { $temp <= $maxViaOffsetL } { set maxViaOffsetL $temp }
    set temp [expr {($viaLength/2+$mimSpaceVia) + $ldrawn/(2*($modelLimit + 1))}]
    if { $temp <= $maxViaOffsetL } { set maxViaOffsetL $temp }
  }
  
  set maxViaOffsetL [expr {floor($maxViaOffsetL/$mfgGrid+1e-12)*$mfgGrid}]

  set viaOffsetL [db::engToSci [iPDK_getParamValue viaOffsetL $inst] -precision 12]
  if { [string is double -strict $viaOffsetL] == 0 } {
    set viaOffsetL [db::engToSci [iPDK_getDefValue viaOffsetL $inst] -precision 12]
  }
  if { $viaOffsetL <= $minViaOffsetL } {
    set viaOffsetL $minViaOffsetL
  } elseif { $viaOffsetL >= $maxViaOffsetL } {
    set viaOffsetL $maxViaOffsetL
  } else {
    set viaOffsetL [fdkSnapGrid $mfgGrid $viaOffsetL]
  }

  ## get new viaRightMax based on current L and ViaLeftOffset (give priority to Length and viaLeftOffset)
  set maxViaOffsetR [expr {$ldrawn - $viaOffsetL - (2*($viaLength/2.0+$um_ovlp)+$um_space)}]
  set temp [expr {$ldrawn/(1+$modelLimit) + 2*($viaLength/2+$mimSpaceVia)-$viaOffsetL}]
  if { $temp <= $maxViaOffsetR } { set maxViaOffsetR $temp }

  if { $stacked != 0 } {
    set temp [expr {($ldrawn/2 - ($MIMgap/2.0+$mimMinWidth+$mimSpaceVia+$viaLength/2.0))}]
    if { $temp <= $maxViaOffsetR } { set maxViaOffsetR $temp }
    set temp [expr {($viaLength/2+$mimSpaceVia)+$ldrawn/(2*($modelLimit+1))}]
    if { $temp <= $maxViaOffsetR } { set maxViaOffsetR $temp }
  }
  
  set maxViaOffsetR [expr {floor($maxViaOffsetR/$mfgGrid+1e-12)*$mfgGrid}]

  set viaOffsetR [db::engToSci [iPDK_getParamValue viaOffsetR $inst] -precision 12]
  if { [string is double -strict $viaOffsetR] == 0 } {
    set viaOffsetR [db::engToSci [iPDK_getDefValue viaOffsetR $inst] -precision 12]
  }
  if { $viaOffsetR <= $minViaOffsetR } {
    set viaOffsetR $minViaOffsetR
  } elseif { $viaOffsetR >= $maxViaOffsetR } {
    set viaOffsetR $maxViaOffsetR
  } else {
    set viaOffsetR [fdkSnapGrid $mfgGrid $viaOffsetR]
  }

  ## for mimcap_stk set the viaOffset the the same
  if { $stacked != 0 } { set viaOffsetR $viaOffsetL }

  ##**************************************************
  ## Calculate l1,l2,l3 variables
  ##**************************************************

  ## calculate values
  set l3 [expr {$viaOffsetL - $viaLength/2.0 - $mimViaOffset}]
  if { $l3 <= 0 } { set l3 0 }
  set l2 [expr {$viaOffsetR - $viaLength/2.0 - $mimViaOffset}]
  if { $l2 <= 0 } { set l2 0 }
  set l1 [expr {$ldrawn - $l2 - $l3}]
  if { $l1 <= 0 } { set l1 0 }
  set wh [expr {$viaWidth + 2 * $mimViaOffset}]
  if { $wh <= 0 } { set wh 0 }
  set lh [expr {$viaLength + 2 * $mimViaOffset}]
  if { $lh <= 0 } { set lh 0 }

  ## calculate number of holes in PGD direction
  set nh [expr {round(floor(($w - $mimMinWidth)/($viaWidth+2*$mimSpaceVia+$mimMinWidth)))}]
  if { $nh <= 1 } {
    set nh 1
  }

  ## calculate the effective area and length model
  if { $stacked != 0 } {
    set Area [expr [format "(%s)*(%s+%s+%s-%s)/2.0" $w $l1 $l2 $l3 $MIMgap]]
    set Aholes [expr [format "(%s)*(%s)*(%s)" $nh $wh $lh]]
    set Aeff [expr [format "((%s)-(%s))/2" $Area $Aholes]]
    set lmodel [expr [format "(%s)*(%s) + (%s)*(%s+%s)" $L1scale $l1 $L2L3scale $l2 $l3]]
  } else {
    set Area [expr [format "(%s)*(%s+%s+%s)" $w $l1 $l2 $l3]]
    set Aholes [expr [format "2*(%s)*(%s)*(%s)" $nh $wh $lh]]
    set Aeff [expr [format "(%s)-(%s)" $Area $Aholes]]
    set lmodel [expr [format "(2/3.0)*((%s)*(%s) + (%s)*(%s+%s))" $L1scale $l1 $L2L3scale $l2 $l3]]
  }

  ## calculate caps and resistances (Crmimcap is in fF/um^2)
  set Cest [expr {$Aeff*$Crmimcap}]
  set Rest [expr {$Rmimcap*$lmodel/$w}]

  ## Update CDF with any new values
  if { [info exists m] != 0 } {
    if { [string is integer -strict $m] != 0 } {
      set m [format "%d" $m]
    }
    if { $m ne [iPDK_getParamValue m $inst] } {
      iPDK_setParamValue m $m $inst 0
    }
  }

  foreach param_nm {w ldrawn viaOffsetL viaOffsetR Cest Rest l1 l2 l3 wh lh nh} {
    if { [info exists $param_nm] != 0 } {
      if { [string is double -strict [set $param_nm]] != 0 } {
        set $param_nm [db::sciToEng [set $param_nm] -precision 12]
      }
      if { [set $param_nm] ne [iPDK_getParamValue $param_nm $inst] } {
        iPDK_setParamValue $param_nm [set $param_nm] $inst 0
      }
    }
  }

}

proc fdkCdf_mimcap_sclCB { lib cell cdfId } {
  set inst [db::getCurrentRef]
  _fdkCdf_mimcap_sclCB $lib $cell $inst 0
}

proc fdkCdf_mimcap_scl_doneProc { inst } {
  set lib  [iPDK_getInstLibName $inst]
  set cell [iPDK_getInstCellName $inst]
  _fdkCdf_mimcap_sclCB $lib $cell $inst 0
}

proc fdkCdf_mimcap_stk_sclCB { lib cell cdfId } {
  set inst [db::getCurrentRef]
  _fdkCdf_mimcap_sclCB $lib $cell $inst 1
}

proc fdkCdf_mimcap_stk_scl_doneProc { inst } {
  set lib  [iPDK_getInstLibName $inst]
  set cell [iPDK_getInstCellName $inst]
  _fdkCdf_mimcap_sclCB $lib $cell $inst 1
}
