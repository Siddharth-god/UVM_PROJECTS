# UVM-Based Verification of a Parameterized FIFO

---

## OVERVIEW
This project implements and verifies a **parameterized synchronous FIFO** using **SystemVerilog RTL** and **UVM**.

The goal of this project is to:
- Design a configurable FIFO
- Build a structured UVM testbench
- Validate functionality under multiple traffic scenarios
- Implement a timing-aware scoreboard for accurate verification

The verification environment follows an **industry-style UVM architecture** with clear separation of stimulus generation, driving, monitoring, and checking.

---

## FIFO DESIGN

The FIFO is a **synchronous, parameterized design** supporting configurable data width and depth.

### Key Features
- Parameterized DATA WIDTH
- Parameterized ADDR (pointer size)
- Configurable FIFO DEPTH
- Separate read pointer and write pointer
- Counter-based tracking of FIFO occupancy
- Full flag generation
- Empty flag generation
- Modularization of UVM components into packages/files

### Protection against invalid operations
- Write operation is blocked when FIFO is **FULL**
- Read operation is blocked when FIFO is **EMPTY**

---

## VERIFICATION METHODOLOGY

The verification environment is implemented using **SystemVerilog UVM** with a modular and scalable architecture.

## PROJECT STRUCTURE
The environment is modularized into a standard UVM directory structure:
```bash
    ├── rtl/               # FIFO SystemVerilog RTL & Interface & SVA
    ├── tb/                # Top-level Testbench & Environment, Scoreboard, and Virtual Sequencer
    ├── tests/             # UVM Test Library & Package
    ├── write_agent/       # Write Agent (Sequencer, Driver, Monitor)
    ├── read_agent/        # Read Agent (Sequencer, Driver, Monitor)
    └── sim/               # Simulation scripts and logs
```
---

### UVM Components Implemented
- Transaction (Sequence Item)
- Sequences
- Sequencers
- Drivers
- Monitors
- Write Agent
- Read Agent
- Virtual Sequencer
- Virtual Sequence
- Scoreboard
- Environment
- Test
- Interface

### Architecture Highlights
- Separate **READ and WRITE agents** for independent stimulus and monitoring
- Virtual sequencer coordinates activity between both agents
- Constrained-random stimulus generation for better coverage
- Passive monitors capture DUT behavior
- Scoreboard validates functional correctness

---

## VERIFICATION ARCHITECTURE

```bash
Test
  |
  +-- Environment
       |
       +-- Write Agent
       |     +-- Driver
       |     +-- Sequencer
       |     +-- Monitor
       |
       +-- Read Agent
       |     +-- Driver
       |     +-- Sequencer
       |     +-- Monitor
       |
       +-- Virtual Sequencer
       |
       +-- Scoreboard
```

---


## TEST SCENARIOS IMPLEMENTED

### 1. Burst Write
- Multiple consecutive write operations used to fill the FIFO

### 2. Burst Read
- Multiple consecutive read operations used to drain the FIFO

### 3. Simultaneous Read and Write
- Read and write operations occur in the same clock cycle

### 4. Constrained Random Traffic
- Randomized stimulus using SystemVerilog constraints to explore different FIFO states

---


## SCOREBOARD

A **queue-based reference model** is implemented in the scoreboard.

### Functional Model
- Write operation → push_back() into reference queue (only when **not full**)
- Read operation → pop_front() from reference queue (only when **not empty**)
- DUT output is compared with expected reference output

### Comparison
- Comparison is performed **only for valid read operations**
- Match → Info message
- Mismatch → Error reported

---

## TIMING ALIGNMENT (IMPORTANT LEARNING) - WORKING METHODS

A key issue observed during verification was **data misalignment due to clocking block sampling skew**.

### Root Cause
- Default sampling uses input #1step
- This introduces a delta-cycle delay
- Scoreboard assumed zero-cycle latency
- Result → mismatch between expected and actual data

### Fix Applied
- Proper clocking block alignment ensured monitor samples synchronized data
- Scoreboard updated to reflect actual DUT behavior

---

### Method 1 (Recommended - Timing-Aware Scoreboard)
- Keep input #1step
- Delay comparison by 1 clock cycle

READ (cycle N) → DATA_OUT compared at (cycle N+1)

Reason:
- Matches real hardware behavior
- Works for pipelined and complex designs
- Scalable and robust

---

### Method 2 (Workable - Compare-Then-Update Alignment)

- Perform comparison first
- Then update the expected reference (pop from queue)

#### Idea
Instead of updating expected data immediately on read,  
we compare using the **previous expected value**, then update it.

This naturally aligns with the fact that **data_out corresponds to a previous read**.

#### Behavior
READ (cycle N) → DATA_OUT corresponds to previous expected value  
After comparison → update expected for next cycle

#### Why it works
- Avoids delta-cycle misalignment
- Keeps scoreboard simple
- No need to modify clocking block skew
- Matches observed DUT behavior without extra delay handling

#### Example

```bash
# exp_data holds previous expected value (initialized to 0)

# Key Observation:
DUT output is effectively 1 cycle behind inputs

#Timeline:
    @100 → Inputs applied
         Output corresponds to @90 inputs

    @110 → Inputs applied
         Output corresponds to @100 inputs

# So:
    Current output = result of previous cycle input
    Therefore:
    Compare with previous expected, then update expected

# First comparison:
    exp_data = 0 (default)
    DUT also outputs 0 initially
    → Match

# Compare first
    if(exp_data != rd_xtn.data_out)
        `uvm_error("SB", $sformatf("EXP=%0d ACT=%0d", exp_data, rd_xtn.data_out));

# Then update expected for next cycle
    if(ref_q.size() > 0)
        exp_data = ref_q.pop_front();
```

---

### Method 3 (Workable - Sampling Alignment)
- Use input #0 in clocking block
- Compare immediately after popping data out from the queue

READ (cycle N) → DATA_OUT compared at (cycle N)

Reason:
- Aligns sampling with scoreboard assumption
- Works well for simple synchronous designs

---

## CLOCKING BLOCK UNDERSTANDING

### Default Behavior
- input skew = #1step
- output skew = #0

### Important Clarification Learned
Sampling always happens after posedge.

- input #0 → sample immediately after clock edge  
- input #1step → sample slightly after clock edge (delta delay)  
- input #1 → sample later (time unit delay)  

### Key Learning
Even a small delta delay can cause misalignment if scoreboard assumptions are incorrect.

---

## DEBUGGING THE SCOREBOARD LOGIC – FINAL FIX

During random stress testing, multiple issues were identified and resolved:

### Issues Faced & fixed
1. Initial Issue – Synchronization
```
At the beginning, the primary issue was misalignment between driver and monitor sampling.
    - The monitor was not sampling signals in sync with DUT updates
    - This caused incorrect transactions being observed

This was resolved using clocking block alignment, specifically:
    - using proper sampling skew (#0 → corrected approach)

After fixing this, the environment became cycle-consistent, and basic sequences started working correctly.
```

2. False Confidence – Limited Testing
```
Initially, the FIFO appeared correct because:
    - Only small sequences were used
    - No stress or randomness was applied

Once random sequences with higher repeat count and weighted read/write were introduced:
    - Multiple bugs started appearing
```

3. Scoreboard Modeling Issues
```
The next set of issues came from the scoreboard (reference model):
    - Incorrect conditions for push/pop
    - Misalignment with DUT behavior
    - Improper handling of full and empty

These were fixed by aligning the model strictly with DUT rules:
    - Push only when: write && !full
    - Pop only when: read && !empty
```

4. Critical Bug – Invalid Read Handling
```
The most difficult issue was:
    - Reading when FIFO is empty

This caused mismatches because:
    - DUT does nothing when read && empty
    - But scoreboard was still trying to pop and compare
Attempts made:
    - Tracking stale/previous data
    - Using additional flags (stale_data, counters)

# These approaches failed because they tried to predict behavior instead of modeling it
```

5. Final Fix – Correct Modeling Philosophy
```
The solution was to separate:

# Observation (for coverage)

Capture all scenarios:
    - read && empty
    - write && full

# Modeling (for correctness)

Only model valid operations:
    - Push → write && !full
    - Pop → read && !empty

# Comparison

Compare only when valid pop occurs
    - Invalid operations were removed from comparison logic
    - Kept only for coverage

This eliminated all mismatches cleanly.
```

6. Coverage Refinement
```
A final issue was incorrect coverage intent:

Earlier: checking read × full (not meaningful)
    - Corrected to:
    - write × full
    - read × empty

This aligned coverage with actual FIFO behavior and enabled 100% closure.
```

7. Final Result
```
The FIFO verification environment now ensures:

1) Correct data ordering
2) Proper handling of boundary conditions (full/empty)
3) No false mismatches from invalid operations
4) Robust behavior under random stress
5) Clean and meaningful coverage
```

### Final Resolution
- Scoreboard strictly follows DUT rules:
  - Push → write && !full
  - Pop → read && !empty
- Comparison is done only for valid reads
- Invalid operations are ignored in comparison and used only for coverage

### Key Learning
Not every observed operation should be compared. Only valid state transitions should be verified.

---

## FUNCTIONAL COVERAGE

- Write-side coverage includes:
  - write, full, and their interaction  
- Read-side coverage includes:
  - read, empty, and their interaction  

### Coverage Insight
- full is meaningful for write operations  
- empty is meaningful for read operations  
- Invalid scenarios are captured for coverage, not comparison  

### Result
- Achieved 100% functional coverage

---

## TOOLS AND LANGUAGES USED
- SystemVerilog
- UVM (Universal Verification Methodology)
- QuestaSim

---

## ADDED ASSERTIONS USING _BIND_ METHOD 

### Assertions checked are : 
- RESET
- FIFO_FULL
- FIFO_EMPTY
- READ_CHECK
- WRITE_CHECK
- NO_FULL_EMPTY
- FULL_DEASSERT
- SIMULTANEOUS READ & WRITE
- IF_READ_COUNT_MINUS 
- IF_WRITE_COUNT_PLUS

---

## FUTURE IMPROVEMENTS
- Add overflow and underflow detection
- Extend assertions for error conditions
- Implement an Asynchronous FIFO to handle multi-clock domain (CDC) verification.
- Enhance repository structure

---

## LEARNING OBJECTIVES
- SystemVerilog RTL design
- UVM testbench architecture
- Virtual sequencer coordination
- Constrained random verification
- Scoreboard-based checking and synchronization
- Debugging timing mismatches
- Understanding clocking block skew
- Understanding Binding Method for Assertions 
- Achieving 100% functional coverage

---

## FINAL NOTE
Correct verification depends not only on logic,  
but on aligning observation, modeling, and comparison with actual DUT behavior.