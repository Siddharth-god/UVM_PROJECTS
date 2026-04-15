
# SIMULATOR = VCS for Synopsys's VCS

SIMULATOR = Questa

FSDB_PATH=/home/cad/eda/SYNOPSYS/VERDI_2022/verdi/T-2022.06-SP1/share/PLI/VCS/LINUX64


RTL= ../rtl/*
work= work #library name
SVTB1= ../tb/udm12_top.sv
INC = +incdir+../tb +incdir+../test +incdir+../in_agent_top +incdir+../out_agent_top
SVTB2 = ../test/udm12_pkg.sv
VSIMOPT= -vopt -voptargs=+acc
VSIMCOV= -coverage -sva
VSIMBATCH1= -c -do  " log -r /* ;coverage save -onexit mem_cov1;run -all; exit"


help:
		@echo =============================================================================================================
		@echo "! USAGE          --  make target                                                                                 !"
		@echo "! clean          =>  clean the earlier log and intermediate files.                                               !"
		@echo "! sv_cmp         =>  Create library and compile the code.                                                        !"
		@echo "! run_test       =>  clean, compile & run the simulation for    udm_test in batch mode.                 			!"
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
view_wave1 : view_wave1_$(SIMULATOR)
report : report_$(SIMULATOR)
cov : cov_$(SIMULATOR)
wcov : wcov_$(SIMULATOR)

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
	vlog -work $(work) $(INC) $(SVTB1)

run_test_Questa: sv_cmp 
		vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH1)  -wlf wave_file1.wlf -l test.log  -sv_seed random  work.udm_top +UVM_TESTNAME=udm_test
		vcover report -html mem_cov1 -cvg -details -assert -directive
		
view_wave1_Questa:
		vsim -view wave_file1.wlf

report_Questa:
		vcover merge mem_cov mem_cov1
		vcover report -cvg -details -assert -directive -html mem_cov

cov_Questa:
		firefox covhtmlreport/index.html&

wcov_Questa:
		cmd /c start covhtmlreport/index.html&

clean_Questa:
		rm -rf transcript* *log* fcover* covhtml* mem_cov* *.wlf modelsim.ini work
		clear

wclean_Questa:
	del /Q *.log *.wlf
	rmdir /S /Q work
