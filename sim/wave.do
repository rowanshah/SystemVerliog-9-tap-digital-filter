onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_fir/inst_fir/y
add wave -noupdate -radix unsigned /tb_fir/inst_fir/x
add wave -noupdate -radix unsigned /tb_fir/inst_fir/c
add wave -noupdate -radix unsigned /tb_fir/inst_fir/thresh
add wave -noupdate /tb_fir/inst_fir/rst
add wave -noupdate /tb_fir/inst_fir/clk
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 175
configure wave -valuecolwidth 78
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
configure wave -timelineunits ps
update
WaveRestoreZoom {126722394 ps} {128136144 ps}
