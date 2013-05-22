onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider driven
add wave -noupdate /booth_io_if_tb/clk
add wave -noupdate /booth_io_if_tb/sys_rst
add wave -noupdate -radix hexadecimal -childformat {{/booth_io_if_tb/port_id(7) -radix hexadecimal} {/booth_io_if_tb/port_id(6) -radix hexadecimal} {/booth_io_if_tb/port_id(5) -radix hexadecimal} {/booth_io_if_tb/port_id(4) -radix hexadecimal} {/booth_io_if_tb/port_id(3) -radix hexadecimal} {/booth_io_if_tb/port_id(2) -radix hexadecimal} {/booth_io_if_tb/port_id(1) -radix hexadecimal} {/booth_io_if_tb/port_id(0) -radix hexadecimal}} -subitemconfig {/booth_io_if_tb/port_id(7) {-height 15 -radix hexadecimal} /booth_io_if_tb/port_id(6) {-height 15 -radix hexadecimal} /booth_io_if_tb/port_id(5) {-height 15 -radix hexadecimal} /booth_io_if_tb/port_id(4) {-height 15 -radix hexadecimal} /booth_io_if_tb/port_id(3) {-height 15 -radix hexadecimal} /booth_io_if_tb/port_id(2) {-height 15 -radix hexadecimal} /booth_io_if_tb/port_id(1) {-height 15 -radix hexadecimal} /booth_io_if_tb/port_id(0) {-height 15 -radix hexadecimal}} /booth_io_if_tb/port_id
add wave -noupdate -radix hexadecimal /booth_io_if_tb/port_data_to_if
add wave -noupdate /booth_io_if_tb/read_strobe
add wave -noupdate /booth_io_if_tb/write_strobe
add wave -noupdate -divider results
add wave -noupdate -radix hexadecimal /booth_io_if_tb/UUT/curreg
add wave -noupdate -radix hexadecimal /booth_io_if_tb/port_data_from_if
add wave -noupdate /booth_io_if_tb/rst_cmd
add wave -noupdate /booth_io_if_tb/start_cmd
add wave -noupdate -radix hexadecimal /booth_io_if_tb/multiplier
add wave -noupdate -radix hexadecimal /booth_io_if_tb/multiplicand
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {12288 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 199
configure wave -valuecolwidth 53
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {789550 ps} {1130310 ps}
