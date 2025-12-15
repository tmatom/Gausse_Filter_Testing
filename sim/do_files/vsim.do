
vlog -reportprogress 300 -64  $env(XILINX_VIVADO)/data/verilog/src/glbl.v

vlib work
vmap work work


set path_icnl   ../../rtl


vlog  +incdir+$path_icnl  -reportprogress 300 -work work ../verilog/test.sv
vlog  +define+__XILINX_SIMULATOR__ +incdir+$path_icnl  -reportprogress 300 -work work ../../rtl/gausse_filter_axis.sv

vsim -voptargs=+acc=lprn -L unisims_ver  -t 100pS work.gauss_filter_tb glbl

view wave																					 
view structure
view signals 
do wave.do

run -all
#run 430000 ns

wave zoom full



