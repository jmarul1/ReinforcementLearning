#!/usr/bin/env tcl
# Procedure to open a .lnf file, optionally flatten it, and write out .stm
# Writes to the default Genesys .stm output directory, unless stmdir is given
#
proc lnf2stm {cell_list smash clean_shorts merge_polygons {stmdir ""}} {

    set file [open $cell_list]
    while {![eof $file]} {
        set line [gets $file]
        lappend cells $line
    }

    # remove epmty set at the end of list
    set cells [lreplace $cells end end]
    close $file

    foreach cell $cells {
        puts "-I-lnf2stm- READING $cell.lnf"
        Read -cellname $cell -viewname lnf -noask

        # call the clean_shorted_routes flow if user wants to clean shorts
        # during LNF to STM
        if {$clean_shorts} {
            ::reconnect_routes_flow::clean_shorted_routes  -cellname "$cell" -viewname "lnf" -microns -debug -stats_mode "none" -stats_type "unresolved"  -nets "all"  -fixed_nets ""  -priority_nets ""  -exclude_nets "*UDM_INTERNAL_NULL*"  -layers "all"  -alt_regions ""  -group_name "reconnect_shorts"  -hier_chk_depth "99"  -hier_del_depth "99"  -hier_del_inst_limit "999"  -fixed_cells ""  -deeper_hier_del_ok -highlight_color "yellow"
        }

        # smash hierarchical cells
        if {$smash} {
            if {[llength [udm_utils_get_hierarchy [get_active_cell] 1]] > 1} {
                udm_utils_smash_all [get_active_cell]
                puts "-I-lnf2stm- FLATTENING [get_active_cellname]"

                # remap hier net names from smashing back to flat name
                set lay_objs [cell_get_layout_objs [get_active_cell]]
                foreach obj $lay_objs {
                    set hier_net [layout_obj_get_net $obj]
                    set net [lindex [split $hier_net "/"] end]
                    # net may already be a top-level net, no need to rename
                    if {$hier_net == $net} {
                        continue
                    }
                    # check if net already has been created
                    if {[cell_get_net [get_active_cell] $net] == ""} {
                        set cell_net [cell_create_net [get_active_cell] $net]
                    } else {
                        set cell_net [cell_get_net [get_active_cell] $net]
                    }
                    layout_obj_set_net $obj $cell_net
                }

                set geo_plygs [cell_get_geo_polygons [get_active_cell] 1]
                foreach plyg $geo_plygs {
                    set hier_net [geo_polygon_get_net $plyg]
                    set net [lindex [split $hier_net "/"] end]
                    if {$hier_net == $net} {
                        continue
                    }
                    # net should already exist
                    set cell_net [cell_get_net [get_active_cell] $net]
                    geo_polygon_set_net $plyg $cell_net
                }

            }
        }

        # if stmdir not set, set it to default write location
        if {$stmdir eq ""} {
            set stmdir [lindex [[::boo::CellViewMgr_getCellViewMgr] getRWPaths stm] 0]
        }

        # merge polygons on output to stm
        if {$merge_polygons} {
            stm mergepolygons 1
        }
        #Added for drc_HVdirectsim problem w/ stm files in A0/E0
        stm forcedTermInstLabels 1
        puts "-I-lnf2stm- WRITING ${stmdir}/${cell}.stm"
        SaveAs -cellname $cell -viewname lnf:stm -noask -path ${stmdir}/${cell}.stm

        DiscardAll -noask
    }
}


# This procedure prints out the ITEG information for all UDM
# terms in the top of the cell.
proc write_iteg_for_nets {cellname filename} {
    set DEFAULT_ITEG_VALUE 0
    set FILEID [open $filename w]

    puts "-I-lnf2stm- READING $cellname.lnf"
    lnf UnSet Interface
    lnf open $cellname
    set cellMgr [cell_mgr_get_mgr]
    set cell [cell_mgr_get_cell $cellMgr $cellname "lnf"]

    if {$cell == ""} {
        puts stderr "error: Could not find cell $cellname"
        return
    }

    foreach net [cell_get_nets $cell] {
        set netName [net_get_name $net]
        foreach pin [net_get_pins $net] {
            foreach term [pin_get_terms $pin] {
                set poly       [term_get_polygon $term]
                set bbox       [gig_figure_get_bbox $poly]
                set center     [bbox_get_center $bbox]
                set layer      [term_get_layer $term]
                set layer_name [layer_get_name $layer]
                set maskLayer  [layer_get_mask_layer $layer]
                set maskName   [mask_layer_get_name $maskLayer]

                set xcoord     [point_get_x $center]
                set ycoord     [point_get_y $center]
                set tech       [cell_get_tech $cell]
                set x          [tech_udm_to_micron $tech $xcoord]
                set y          [tech_udm_to_micron $tech $ycoord]

                # Do all the itegs on the term
                foreach iteg [term_get_intended_teg $term] {

                    # All terminals have the default iteg of 0 (zero) -- don't report these.
                    # Really want to use $UdmTerm::DEFAULT_ITEG (it's value is zero)
                    #   to distinquish default from assigned iteg values but this
                    #   constant does not seem to be exported to Tcl.
                    puts $FILEID "   $netName \t $iteg \t $x,$y \t $maskName ($layer_name)"
                }
            }
        }
    }
    close $FILEID
    DiscardAll -noask
}
