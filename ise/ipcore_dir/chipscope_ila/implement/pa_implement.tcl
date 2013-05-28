add_files -norecurse {../example_design/example_chipscope_ila.vhd}
add_files -norecurse {../example_design/example_chipscope_ila.ucf}
import_ip -file {chipscope_icon.xco} -name chipscope_icon
set_property top example_chipscope_ila [get_filesets sources_1]
reset_run -run synth_1
launch_runs synth_1
