# riscv-rv32i-pipelined-processor
5-Stage Pipelined RISC-V Processor with Data Forwarding and Hazard Detection
# 5-Stage Pipelined RISC-V Processor (RV32I)
---

## Overview

This project implements a classic 5-stage pipelined RISC-V processor based on the RV32I instruction set architecture. The design emphasizes correct hazard handling through data forwarding, stall insertion, and pipeline flushing mechanisms.

### Key Features

- **5-Stage Pipeline Architecture**: IF → ID → EX → MEM → WB
- **Data Forwarding Unit**: Resolves RAW (Read After Write) dependencies between pipeline stages
- **Hazard Detection Logic**: Automatically detects and handles data hazards
- **Stall Mechanism**: Inserts pipeline bubbles for load-use hazards
- **Branch Flushing**: Clears pipeline on branch mispredictions
- **Full RV32I Support**: All 47 base integer instructions implemented

---

## Architecture

### Pipeline Stages

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   IF    │───▶│   ID    │───▶│   EX    │───▶│   MEM   │───▶│   WB    │
│ Fetch   │    │ Decode  │    │ Execute │    │ Memory  │    │ Write   │
│ Instr   │    │ Read RF │    │ ALU Op  │    │ Access  │    │ Back    │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │
     └──────────────┴──────────────┴──────────────┴──────────────┘
                         Forwarding Paths
```

#### 1. Instruction Fetch (IF)
- Fetches instruction from instruction memory
- Updates program counter (PC + 4 or branch target)
- Handles branch target calculation

#### 2. Instruction Decode (ID)
- Decodes instruction fields (opcode, funct3, funct7, registers)
- Reads source registers from register file
- Generates all control signals
- Sign-extends immediate values

#### 3. Execute (EX)
- Performs ALU operations
- Calculates memory addresses for loads/stores
- Evaluates branch conditions
- Implements data forwarding from later stages

#### 4. Memory Access (MEM)
- Reads from or writes to data memory
- Passes through ALU results for register operations
- Supports byte, half-word, and word accesses

#### 5. Write Back (WB)
- Writes results back to register file
- Selects between ALU result and memory data
- Ensures register x0 remains hardwired to zero

### Pipeline Registers

Inter-stage registers maintain data between pipeline stages:
- **IF/ID**: Instruction, PC
- **ID/EX**: Control signals, register values, immediate, PC
- **EX/MEM**: Control signals, ALU result, store data, destination register
- **MEM/WB**: Control signals, memory data, ALU result, destination register

---

## Hazard Handling

### Data Hazards

#### EX Hazard (Back-to-Back Dependencies)
```verilog
add x1, x2, x3    // I1: Writes x1 in WB
sub x4, x1, x5    // I2: Needs x1 in EX ← Forward from EX/MEM
```
**Solution**: Forward from EX/MEM stage → 0 cycle penalty

#### MEM Hazard (One Instruction Gap)
```verilog
add x1, x2, x3    // I1
nop               // I2
sub x4, x1, x5    // I3: Needs x1 ← Forward from MEM/WB
```
**Solution**: Forward from MEM/WB stage → 0 cycle penalty

#### Load-Use Hazard
```verilog
lw  x1, 0(x2)     // I1: Loads x1
add x4, x1, x5    // I2: Needs x1 immediately ← Cannot forward in time!
```
**Solution**: Stall 1 cycle + forward from MEM/WB → 1 cycle penalty

**Hazard Detection Logic**:
```verilog
if (ID_EX.MemRead && (ID_EX.Rd == IF_ID.Rs1 || ID_EX.Rd == IF_ID.Rs2))
    Stall = 1;  // Insert bubble
```

### Control Hazards

#### Branch Misprediction
```verilog
beq x1, x2, target    // Branch resolved in EX stage
add x3, x4, x5        // Flush if branch taken
sub x6, x7, x8        // Flush if branch taken
```
**Solution**: Flush IF/ID and ID/EX stages → 2 cycle penalty

**Default Strategy**: Predict not-taken (static prediction)

### Forwarding Unit

The forwarding unit detects when a source register matches a destination register from a previous instruction still in the pipeline:

```verilog
// EX Hazard (priority)
if (EX_MEM.RegWrite && EX_MEM.Rd != 0 && EX_MEM.Rd == ID_EX.Rs1)
    ForwardA = 2'b10;  // Forward from EX/MEM

// MEM Hazard (lower priority)  
if (MEM_WB.RegWrite && MEM_WB.Rd != 0 
    && !(EX_MEM.RegWrite && EX_MEM.Rd == ID_EX.Rs1)
    && MEM_WB.Rd == ID_EX.Rs1)
    ForwardA = 2'b01;  // Forward from MEM/WB
```

---

## Project Structure

```
riscv-rv32i-pipelined-processor/
│
├── src/
│   ├── processor.v                    # Top-level processor module
│   │
│   ├── core/                          # Core functional units
│   │   ├── alu.v                      # Arithmetic Logic Unit (10 operations)
│   │   ├── control_unit.v             # Main control unit (opcode decoder)
│   │   ├── hazard_unit.v              # Hazard detection & forwarding logic
│   │   ├── branch_control.v           # Branch condition evaluation
│   │   ├── register_file.v            # 32 general-purpose registers
│   │   ├── data_memory.v              # Data memory (loads/stores)
│   │   └── immediate_generator.v      # Immediate value extraction
│   │
│   ├── stages/                        # Pipeline stage modules
│   │   ├── stage_if.v                 # Instruction Fetch
│   │   ├── stage_id.v                 # Instruction Decode
│   │   ├── stage_ex.v                 # Execute
│   │   ├── stage_mem.v                # Memory Access
│   │   └── stage_wb.v                 # Write Back
│   │
│   └── pipeline_registers/            # Inter-stage registers
│       ├── if_id_reg.v                # IF/ID pipeline register
│       ├── id_ex_reg.v                # ID/EX pipeline register
│       ├── ex_mem_reg.v               # EX/MEM pipeline register
│       └── mem_wb_reg.v               # MEM/WB pipeline register
│
├── testdata/
│   └── test_program.mem               # Sample test program
│
└── docs/
    ├── ARCHITECTURE.md                # Detailed architecture documentation
    ├── HAZARDS.md                     # Comprehensive hazard handling guide
    └── pipelined.md                   # Pipeline design overview
```

---

## Getting Started

### Prerequisites

- Verilog simulator (Icarus Verilog, ModelSim, Vivado, or Questa)
- Basic understanding of RISC-V ISA and pipelined processors
- (Optional) GTKWave for waveform viewing

### Installation & Simulation

#### Option 1: Icarus Verilog (Open Source)

**Install**:
```bash
# Ubuntu/Debian
sudo apt-get install iverilog gtkwave

# macOS
brew install icarus-verilog gtkwave

# Windows
# Download from: http://bleyer.org/icarus/
```

**Compile & Run**:
```bash
# Navigate to project directory
cd riscv-rv32i-pipelined-processor

# Compile all source files
iverilog -o processor_sim \
    src/processor.v \
    src/core/*.v \
    src/stages/*.v \
    src/pipeline_registers/*.v

# Run simulation
vvp processor_sim

# View waveforms (if VCD dump enabled)
gtkwave processor.vcd
```

#### Option 2: ModelSim/Questa

**Compile**:
```bash
# Create work library
vlib work

# Compile all files
vlog src/processor.v \
     src/core/*.v \
     src/stages/*.v \
     src/pipeline_registers/*.v

# Simulate
vsim -c processor -do "run -all; quit"

# Or with GUI
vsim processor
# Then in GUI: run -all
```

#### Option 3: Xilinx Vivado

1. **Create New Project**: File → New Project
2. **Add Sources**: Add all `.v` files from `src/`, `src/core/`, `src/stages/`, `src/pipeline_registers/`
3. **Set Top Module**: Right-click `processor.v` → Set as Top
4. **Run Simulation**: Flow Navigator → Run Simulation → Run Behavioral Simulation


