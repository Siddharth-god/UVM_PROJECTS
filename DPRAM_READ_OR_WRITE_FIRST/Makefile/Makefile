
# SIMULATOR = VCS for Synopsys's VCS

SIMULATOR = Questa

FSDB_PATH=/home/cad/eda/SYNOPSYS/VERDI_2022/verdi/T-2022.06-SP1/share/PLI/VCS/LINUX64


RTL= ../rtl/*
MODE ?= 1
work= work #library name
SVTB1= ../tb/ram_top.sv
INC = +incdir+../tb +incdir+../test +incdir+../ram_write_agent_top +incdir+../ram_read_agent_top
SVTB2 = ../test/ram_pkg.sv
VSIMOPT= -vopt -voptargs=+acc
VSIMCOV= -coverage -sva
VSIMBATCH1= -c -do  " log -r /* ;coverage save -onexit mem_cov1;run -all; exit"
VSIMBATCH2= -c -do  " log -r /* ;coverage save -onexit mem_cov2;run -all; exit"
VSIMBATCH3= -c -do  " log -r /* ;coverage save -onexit mem_cov3;run -all; exit"
VSIMBATCH4= -c -do  " log -r /* ;coverage save -onexit mem_cov4;run -all; exit"


help:
		@echo =============================================================================================================
		@echo "! USAGE          --  make target                                                                                 !"
		@echo "! clean          =>  clean the earlier log and intermediate files.                                               !"
		@echo "! sv_cmp         =>  Create library and compile the code.                                                        !"
		@echo "! run_test       =>  clean, compile & run the simulation for ram_test_base in batch mode.                !"
		@echo "! run_test_write_first      =>  clean, compile & run the simulation for ram_test_write_first in batch mode.                    !"
		@echo "! run_test_read_first      =>  clean, compile & run the simulation for ram_test_read_first in batch mode.                    !"
		@echo "! run_test_burst      =>  clean, compile & run the simulation for ram_test_burst_wr_rd in batch mode.                   !"
		@echo "! view_wave1 =>  To view the waveform of ram_signle_addr_test                                                    !"
		@echo "! view_wave2 =>  To view the waveform of ram_ten_addr_test                                                       !"
		@echo "! view_wave3 =>  To view the waveform of ram_odd_addr_test                                                       !"
		@echo "! view_wave4 =>  To view the waveform of ram_even_addr_test                                                      !"
		@echo "! regress    =>  clean, compile and run all testcases in batch mode.                                             !"
		@echo "! report     =>  To merge coverage reports for all testcases and  convert to html format.                        !"
		@echo "! cov        =>  To open merged coverage report in html format.                                                  !"
		@echo ====================================================================================================================

clean : clean_$(SIMULATOR)
wclean : wclean_$(SIMULATOR)
sv_cmp : sv_cmp_$(SIMULATOR)
run_test : run_test_$(SIMULATOR)
run_test_write_first : run_test_write_first_$(SIMULATOR)
run_test_read_first : run_test_read_first_$(SIMULATOR)
run_test_burst : run_test_burst_$(SIMULATOR)
view_wave1 : view_wave1_$(SIMULATOR)
view_wave2 : view_wave2_$(SIMULATOR)
view_wave3 : view_wave3_$(SIMULATOR)
view_wave4 : view_wave4_$(SIMULATOR)
regress : regress_$(SIMULATOR)
regress_01 : regress_01_$(SIMULATOR)
regress_012 : regress_012_$(SIMULATOR)
report : report_$(SIMULATOR)
cov : cov_$(SIMULATOR)

# ----------------------------- Start of Definitions for Mentor's Questa Specific Targets -------------------------------#

sv_cmp_Questa:
	vlib $(work)
	vmap work $(work)
# 1. Compile Package FIRST
	vlog -work $(work) $(INC) $(SVTB2) 
# 2. Compile RTL
	vlog -work $(work) $(INC) $(RTL)
# 3. Compile Top/Bench
# Pass the macro here using +define+
	vlog -work $(work) $(INC) +define+RAM_MODE_VAL=$(MODE) $(SVTB1)

run_test_Questa: wclean sv_cmp
		vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH1)  -wlf wave_file1.wlf -l test.log  -sv_seed random  work.ram_top +UVM_TESTNAME=ram_test_base
		vcover report -html mem_cov1 -cvg -details -assert -directive

run_test_write_first_Questa: wclean 
		$(MAKE) sv_cmp MODE=1
		vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH2)  -wlf wave_file2.wlf -l test1.log  -sv_seed random  work.ram_top +UVM_TESTNAME=ram_test_write_first
		vcover report -html mem_cov2 -cvg -details -assert -directive

run_test_read_first_Questa: wclean 
		$(MAKE) sv_cmp MODE=0
		vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH3)  -wlf wave_file3.wlf -l test2.log  -sv_seed random  work.ram_top +UVM_TESTNAME=ram_test_read_first
		vcover report -html mem_cov3 -cvg -details -assert -directive

run_test_burst_Questa: wclean sv_cmp
		vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH4)  -wlf wave_file4.wlf -l test3.log  -sv_seed random  work.ram_top +UVM_TESTNAME=ram_test_burst_wr_rd
		vcover report -html mem_cov4 -cvg -details -assert -directive
		
view_wave1_Questa:
		vsim -view wave_file1.wlf

view_wave2_Questa:
		vsim -view wave_file2.wlf

view_wave3_Questa:
		vsim -view wave_file3.wlf

view_wave4_Questa:
		vsim -view wave_file4.wlf

report_Questa:
		vcover merge mem_cov mem_cov1 mem_cov2 mem_cov3 mem_cov4
		vcover report -cvg -details -assert -directive -html mem_cov

regress_01_Questa: clean_Questa run_test_Questa run_test_write_first_Questa  report_Questa cov_Questa
regress_012_Questa: clean_Questa run_test_Questa run_test_write_first_Questa run_test_read_first_Questa  report_Questa cov_Questa
regress_Questa: clean_Questa run_test_Questa run_test_write_first_Questa run_test_read_first_Questa run_test_burst_Questa report_Questa cov_Questa

cov_Questa:
		firefox covhtmlreport/index.html&

clean_Questa:
		rm -rf transcript* *log* fcover* covhtml* mem_cov* *.wlf modelsim.ini work
		clear

wclean_Questa:
	del /Q *.log *.wlf
	rmdir /S /Q work


# # This will run them one after another
# run_all: clean sv_cmp
# 	@echo "Starting Test 1..."
# 	vsim -c $(VSIMOPT) $(VSIMCOV) -l test1.log -sv_seed random work.ram_top +UVM_TESTNAME=ram_test -do "run -all; quit"
# 	@echo "Starting Test 2..."
# 	vsim -c $(VSIMOPT) $(VSIMCOV) -l test2.log -sv_seed random work.ram_top +UVM_TESTNAME=ram_test_write_mode -do "run -all; quit"
# 	@echo "Starting Test 3..."
# 	vsim -c $(VSIMOPT) $(VSIMCOV) -l test3.log -sv_seed random work.ram_top +UVM_TESTNAME=ram_test_burst_wr_rd -do "run -all; quit"
# 	@echo "Starting Test 4..."
# 	vsim -c $(VSIMOPT) $(VSIMCOV) -l test4.log -sv_seed random work.ram_top +UVM_TESTNAME=ram_test3 -do "run -all; quit"

