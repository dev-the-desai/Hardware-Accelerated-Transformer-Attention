export RTL_FILES=$(wildcard ../rtl/*.v) 
export RTL_SV_FILES=$(wildcard ../rtl/*.sv) 
export CLOCK_PER := 13.5


all: logs reports gl sdf 
	dc_shell -no_gui -x "source run_all.tcl"

logs:
	mkdir -p logs

reports:
	mkdir -p reports

gl:
	mkdir -p gl
	
sdf:
	mkdir -p sdf
svf:
	mkdir -p svf

clean:
	rm -rf sdf logs reports gl sdf svf alib-52 *.log clogepJIot

