# Pipelined Processor Documentation

## Overview

The 5-stage pipelined processor divides instruction execution into five stages, allowing multiple instructions to be in different stages of execution simultaneously.

## Pipeline Stages

### 1. IF (Instruction Fetch)
- Fetch instruction from memory
- Update PC for next instruction
- **Module**: `stage_if.v`
- **Pipeline Register**: `pipeline_if_id.v`

### 2. ID (Instruction Decode)
- Decode instruction
- Read register file
- Generate control signals
- Extract immediate values
- **Module**: `stage_id.v`
- **Pipeline Register**: `pipeline_id_ex.v`

### 3. EX (Execute)
- Perform ALU operations
- Calculate branch target
- Resolve data hazards via forwarding
- **Module**: `stage_ex.v`
- **Pipeline Register**: `pipeline_ex_mem.v`

### 4. MEM (Memory Access)
- Access data memory for loads/stores
- Finalize branch decisions
- **Module**: `stage_mem.v`
- **Pipeline Register**: `pipeline_mem_wb.v`

### 5. WB (Write Back)
- Write results back to register file
- Complete instruction execution
- **Module**: `stage_wb.v`

## Hazard Handling

### Data Hazards

**Types**:
1. **RAW (Read After Write)**: Most common
2. **WAW (Write After Write)**: Handled by register file
3. **WAR (Write After Read)**: Cannot occur in this design

**Solutions**:
- **Forwarding**: Forward data from later stages to earlier stages
  - EX/MEM → EX stage
  - MEM/WB → EX stage
- **Stalling**: Insert bubbles when forwarding cannot resolve hazard
  - Load-use hazards require 1-cycle stall

### Control Hazards (Branches)

**Solutions**:
1. **Branch prediction**: Predict not-taken by default
2. **Early branch resolution**: Resolve in EX stage
3. **Flush pipeline**: Clear instructions on misprediction

**Branch Penalty**: 2 cycles on misprediction (with early resolution)

### Structural Hazards

Avoided by design:
- Separate instruction and data memory
- Register file with dual read ports and one write port

## Hazard Unit

The hazard unit (`hazard_unit.v`) handles:

### Forwarding Logic
```
if (EX/MEM.RegWrite && EX/MEM.Rd == ID/EX.Rs1)
    Forward operand A from EX/MEM
if (MEM/WB.RegWrite && MEM/WB.Rd == ID/EX.Rs1)
    Forward operand A from MEM/WB
```

### Stall Detection
```
if (ID/EX.MemRead && (ID/EX.Rd == IF/ID.Rs1 || ID/EX.Rd == IF/ID.Rs2))
    Stall pipeline (insert bubble)
```

## Performance Metrics

### Ideal CPI
- CPI = 1 (without hazards)

### Actual CPI
- CPI = 1 + (stall cycles + branch penalty cycles) / total instructions

### Speedup vs Single-Cycle
- Theoretical: ~5x (with no hazards)
- Actual: ~3-4x (with hazards)

## Pipeline Register Contents

### IF/ID
- Instruction
- PC value

### ID/EX
- Control signals
- Register values (Rs1, Rs2)
- Immediate value
- Register addresses
- PC value

### EX/MEM
- Control signals (MemRead, MemWrite, RegWrite)
- ALU result
- Register value (for stores)
- Destination register address

### MEM/WB
- Control signals (RegWrite, MemToReg)
- Memory read data
- ALU result
- Destination register address

## Testing

Test program (`testdata/test_program.mem`) includes:
- R-type instructions
- I-type instructions
- Load/store operations
- Branch instructions
- Mix of hazardous and non-hazardous sequences

## Optimization Opportunities

1. **Branch Prediction**: Implement better prediction (taken/not-taken)
2. **Branch Target Buffer**: Cache branch targets
3. **Multiple Issue**: Superscalar execution
4. **Out-of-Order Execution**: Dynamic scheduling
5. **Deeper Pipeline**: More stages for higher frequency

## Common Issues

### Load-Use Hazard
```assembly
lw  x1, 0(x2)    # Load data
add x3, x1, x4   # Use loaded data immediately
```
**Solution**: 1-cycle stall

### Branch Hazard
```assembly
beq x1, x2, label
add x3, x4, x5   # May be flushed
```
**Solution**: Flush on misprediction

### Write-Back Hazard
```assembly
add x1, x2, x3
sub x5, x1, x4   # Forwarding from MEM/WB
```
**Solution**: Forwarding unit handles this

## Debugging Tips

1. Check pipeline register contents
2. Verify hazard unit signals
3. Monitor forwarding paths
4. Watch for correct stall insertion
5. Verify branch prediction logic
