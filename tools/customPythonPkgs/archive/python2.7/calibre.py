
## QRC functions
def copyQRCFiles(runArea,outCellName,cdl):
  import subprocess
  subprocess.call('cp $INTEL_PDK/extraction/qrc/calibre/parasitic_blocking_device_cells_file '+runArea,shell=True)  
  with open(runArea+'/qrc.tech.lib','wb') as fout: fout.write('DEFINE intelqrctech $INTEL_PDK/extraction/qrc/techfiles/\n')
  with open(runArea+'/qrc_urcl.cmd','wb') as fout: fout.write('''
### VALUE_TEMPERATURE is a temperature
###    qrc.tech.lib should contain the line
###       DEFINE intelqrctech <KIT_ROOT>/extraction/qrc/techfiles
process_technology \
	-technology_library_file qrc.tech.lib \
	-technology_corner tttt \
	-temperature 25 \
	-technology_name intelqrctech

global_nets \
    -nets "dummy_gnd"

### VALUE_TOPCELL = name of the cell
output_setup \
	 -file_name "'''+outCellName+'''" \
	 -net_name_space "SCHEMATIC" \
	 -keep_temporary_files "true" \
	 -temporary_directory_name "qrc_urcl_dir"

output_db -type dspf \
     -subtype "extended" \
	 -include_res_model "true" \
	 -add_bulk_terminal "true" \
	 -device_finger_delimiter "@" \
	 -delete_x true \
	 -hierarchy_delimiter "/" \
     -add_explicit_vias true \
	 -include_cap_model "false" \
	 -include_parasitic_cap_model "comment" \
	 -include_parasitic_res_model "comment" \
	 -include_parasitic_res_length true \
	 -include_parasitic_res_width_drawn true \
	 -sub_node_char ":" \
	 -disable_instances off \
     -merge_feedthrough_pins true \
	 -pin_order_file '''+cdl+''' \
	 -force_subcell_pin_orders true \
	 -suppress_empty_subckts true \
	 -output_xy canonical_cap canonical_res mos generic diode bipolar

### VALUE_QRC_REDUCTION_MODE=true or false
parasitic_reduction \
	-enable_reduction false \
	-reduction_level off

capacitance \
	 -ground_net 0

extract \
	 -selection all \
 	 -type rc_coupled \
	 -extract_via_cap false

## extract -selection net "vss*" -type none
## extract -selection net "vcc*" -type none
## extract -selection net "vdd*" -type none

graybox -type "layout"

log_file \
	-file_name qrc.sum \
	-dump_options true

extraction_setup \
	 -net_name_space "SCHEMATIC" \
	 -analysis em

filter_coupling_cap \
	 -total_cap_threshold 0.00 \
	 -coupling_cap_threshold_absolute 0.01 \
	 -coupling_cap_threshold_relative 0.005
filter_cap \
	 -exclude_floating_nets true \
     -exclude_self_cap true \
	 -exclude_floating_nets_limit 10000  
filter_res \
     -min_res 0.001 \
     -remove_dangling_res false \
	 -merge_parallel_res false

##hierarchical_extract -split_feedthrough_pins true -split_feedthrough_pins_distance 0.001

## Required for PCELL blocking
extraction_setup -parasitic_blocking_device_cells_file "parasitic_blocking_device_cells_file"

### Use these lines to enable CCI input, or comment them out.
input_db \
	 -type calibre \
	 -device_property_value 7 \
   -instance_property_value 6 \
	 -net_property_value 5 \
	 -directory_name "CCI"  \
	 -layer_map_file "CCI/annotated.gds.map" \
	 -hierarchy_delimiter "/" \
	 -run_name "design"
''')
