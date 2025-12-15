onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /gauss_filter_tb/WIDTH
add wave -noupdate /gauss_filter_tb/HEIGHT
add wave -noupdate /gauss_filter_tb/DATA_WIDTH
add wave -noupdate /gauss_filter_tb/CLK_PERIOD
add wave -noupdate /gauss_filter_tb/clk
add wave -noupdate /gauss_filter_tb/bytes_read
add wave -noupdate /gauss_filter_tb/valid_data_count
add wave -noupdate /gauss_filter_tb/s_axis_tdata
add wave -noupdate /gauss_filter_tb/s_axis_tvalid
add wave -noupdate /gauss_filter_tb/send_data_task/row
add wave -noupdate /gauss_filter_tb/send_data_task/col
add wave -noupdate /gauss_filter_tb/send_data_task/idx
add wave -noupdate /gauss_filter_tb/s_axis_tlast
add wave -noupdate /gauss_filter_tb/s_axis_tready
add wave -noupdate /gauss_filter_tb/m_axis_tdata
add wave -noupdate /gauss_filter_tb/m_axis_tvalid
add wave -noupdate /gauss_filter_tb/m_axis_tlast
add wave -noupdate /gauss_filter_tb/m_axis_tready
add wave -noupdate /gauss_filter_tb/input_data
add wave -noupdate /gauss_filter_tb/expected_output
add wave -noupdate /gauss_filter_tb/input_ptr
add wave -noupdate /gauss_filter_tb/output_ptr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5121159700 ps} 0} {{Cursor 2} {200000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 325
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {5250210 ns}
