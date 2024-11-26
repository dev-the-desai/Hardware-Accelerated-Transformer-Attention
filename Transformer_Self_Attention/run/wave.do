onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/dut/reset_n
add wave -noupdate /tb_top/dut/clk
add wave -noupdate /tb_top/dut/dut_valid
add wave -noupdate /tb_top/dut/dut_ready
add wave -noupdate -color Cyan -itemcolor Cyan /tb_top/dut/dut__tb__sram_input_write_enable
add wave -noupdate -color Cyan -itemcolor Cyan -radix decimal /tb_top/dut/dut__tb__sram_input_read_address
add wave -noupdate -color Cyan -itemcolor Cyan -radix hexadecimal /tb_top/dut/tb__dut__sram_input_read_data
add wave -noupdate -color Pink -itemcolor Pink /tb_top/dut/dut__tb__sram_weight_write_enable
add wave -noupdate -color Pink -itemcolor Pink /tb_top/dut/dut__tb__sram_weight_read_address
add wave -noupdate -color Pink -itemcolor Pink -radix hexadecimal /tb_top/dut/tb__dut__sram_weight_read_data
add wave -noupdate /tb_top/dut/dut__tb__sram_result_write_enable
add wave -noupdate -radix decimal /tb_top/dut/dut__tb__sram_result_write_address
add wave -noupdate -radix hexadecimal /tb_top/dut/dut__tb__sram_result_write_data
add wave -noupdate /tb_top/dut/dut__tb__sram_result_read_address
add wave -noupdate /tb_top/dut/tb__dut__sram_result_read_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1315 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 317
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {819 ns} {1610 ns}
