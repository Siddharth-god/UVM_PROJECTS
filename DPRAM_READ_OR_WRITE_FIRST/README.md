## OVERVIEW
---
This project implements and verifies a Dual Port RAM (DPRAM) 
supporting both **READ_FIRST** and **WRITE_FIRST** modes. 

The DUT allows simultaneous read and write operations. When accessing the same address, 
the output behavior is controlled by a parameterized `MODE` 
to ensure data integrity or specific architectural requirements.

A UVM-based testbench is developed to verify all functional scenarios including:
- Same-address read-write collisions.
- Independent read and write operations.
- Burst and sequential accesses.
- Reset behavior and edge-case address mapping.

### Key Features:
- **Parameterized DPRAM**: Support for custom `WIDTH`, `DEPTH`, and `MODE`.
- **Architectural Modes**: Verified READ_FIRST and WRITE_FIRST behaviors.
- **Scalable Design**: SoC-style architecture with separate read/write agents scaling dynamically.
- **Dynamic Configuration**: Uses `uvm_config_db` and `foreach` constructs for modularity.
- **Automated Flow**: Makefile-driven compilation and simulation with macro-support.

---

## Project Structure 
```bash 
    DPRAM-UVM/
    │
    ├── rtl/
    │   ├── dpram.v                 # Dual Port RAM (READ_FIRST / WRITE_FIRST)
    │   └── ram_if.sv               # Interface
    │
    ├── tb/
    │   ├── ram_top.sv              # Top module (DUT + interface + UVM run)
    │   ├── ram_env.sv              # Environment
    │   ├── ram_env_config.sv       # Env configuration
    │   └── ram_sb.sv               # Scoreboard
    │
    ├── ram_write_agent_top/
    │   ├── ram_wr_agent.sv
    │   ├── ram_wr_driver.sv
    │   ├── ram_wr_monitor.sv
    │   ├── ram_wr_sequencer.sv
    │   ├── ram_wr_agent_config.sv
    │   └── ram_write_seqs.sv
    │
    ├── ram_read_agent_top/
    │   ├── ram_rd_agent.sv
    │   ├── ram_rd_driver.sv
    │   ├── ram_rd_monitor.sv
    │   ├── ram_rd_sequencer.sv
    │   ├── ram_rd_agent_config.sv
    │   └── ram_read_seqs.sv
    │
    ├── test/
    │   ├── ram_pkg.sv              # Package (includes all components)
    │   ├── ram_test.sv             # Base test
    │   ├── ram_test1.sv            # WRITE_FIRST test
    │   └── ram_test2.sv            # READ_FIRST test
    │
    ├── sim/                        # Simulation artifacts (ignored)
    ├── Single_File/                # Temporary / debug files (ignored)
    │
    ├── Makefile                    # Compile & run automation
    ├── .gitignore
    └── README.md
```
---

## Scoreboard Logic Explaination 

### Delay 1 in Scoreboard to Mimic DUT : 
1) The Legacy/Patch-Up Approach (#1 Delay) :

- Explaination regarding #1 delay usage to make _SCOREBOARD_ behave like DUT. 

```sv 
task run_phase(uvm_phase phase); 
        fork
            forever begin
                fifo_wr.get(wr_xtn); 

                if(wr_xtn.we) begin 
                    #1; // This delay will help mimic read first mode. Read first - Write later. But hardcoded delay can cause future problems.
                    exp_data[wr_xtn.wr_adr] = wr_xtn.din;
                end
            end
            forever begin
                bit [WIDTH-1:0] exp_out; 
                fifo_rd.get(rd_xtn); 
                    
                // Comparision .........
```
#### How #1 Delay is working : 

__Simplicity__: It’s a one-line fix that visually separates the "Write" and "Read" events in time.

__Functionality__: In a simple testbench where transactions are perfectly clock-aligned, it will pass the tests and gives "0 Mismatches" log we're looking for.

__Reality__ : This is like a patch up. 

Why ? 

- The reason it feels "off" is that we are using Hardcoded Time to solve a Logic problem.

__Race Conditions__: If we ever move to a different simulator (e.g., switching from Questa to VCS) or change our timescale 
(e.g. from 1ns/1ps to 1ps/1ps), that #1 might suddenly be "too long" or "too short" relative to how the monitor samples.

__Clocking Blocks__: If our monitors use clocking blocks with input/output skews (like #1step), 
the actual time the transaction reaches the scoreboard might fluctuate. 
A _hardcoded_ delay doesn't "know" about the clock; it only knows about the wall clock.

__The "Delta Cycle" Trap__: 
In SystemVerilog, most logic happens in "delta cycles" (zero time). By adding #1, we are pushing the Scoreboard update into the next time step, while the DUT actually did the update in the current time step.

---

### Updated _Scoreboard_ logic : 
2. The Updated __"Chameleon"__ Reference Model :

The scoreboard was refactored to be _Collision-Aware_ and _Parameter-Driven_. It now uses 
logic sequencing to mirror the DUT's behavior exactly, without using physical time delays.

__Mechanism__: 
The Scoreboard retrieves the `RAM_MODE` via `uvm_config_db`. 
During a collision (Read and Write to the same address in the same cycle):

1) __WRITE_FIRST__ (Mode 1): 
The Write update is performed on the internal associative array before the comparison logic. 
The Read operation samples the newly written data.

2) __READ_FIRST__ (Mode 0): 
The comparison is performed before the internal Write update. The Read operation samples the old/existing data.
Refactored Code Snippet:Code snippet// Logic to handle Mode-Based Collisions in the Scoreboard

```sv
if (sb_mode == 1) begin : WRITE_FIRST_LOGIC
    if (wr_xtn.we) exp_data[wr_xtn.wr_adr] = wr_xtn.din; // Update Reference Model First
    check_data(rd_xtn);                                // Compare with Monitor Data Second
end 
else begin : READ_FIRST_LOGIC
    check_data(rd_xtn);                                // Compare with Monitor Data First
    if (wr_xtn.we) exp_data[wr_xtn.wr_adr] = wr_xtn.din; // Update Reference Model Second
end
```
---
## Verification Automation (Makefile)
To ensure the TB and RTL are always synchronized, the environment uses a Compiler Macro flow. 
The `MODE` variable in the Makefile determines both the hardware parameter and the scoreboard logic.

__Makefile__ command for MODE :

```bash

run_test_write_first_Questa: wclean 
		$(MAKE) sv_cmp MODE=1
		vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH2)  -wlf wave_file2.wlf -l test1.log  -sv_seed random  work.ram_top +UVM_TESTNAME=ram_test_write_first
		vcover report -html mem_cov2 -cvg -details -assert -directive
```
---

__Explaination for command Usage__ : 

```bash
--------------------------------------------------------------------------------------------
Target       |   Command                    |     Mode     |   Result                      |
-------------|------------------------------|----------------------------------------------|
Write First  |   make run_test_write_first  |     MODE=1   |   Collision returns New Data  |
Read First   |   make run_test_read_first   |     MODE=0   |   Collision returns Old Data  |
Burst Mode   |   make run_test_burst        |     MODE=1   |   Randomized sequences        |
--------------------------------------------------------------------------------------------
```
---

## Quick Start
1. Clone the repository.
2. Run the Write-First test:
```bash
make run_test_write_first
make run_test_read_first
make run_test_burst
```

## Future Updates 
1) Functional Coverage Addition 
2) Fully automated DPRAM VIP - Hugely Scalable for bigger RAM sizes. 
