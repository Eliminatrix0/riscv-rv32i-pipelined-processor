# Pipeline Hazards & Solutions

## Overview

Pipelining introduces hazards that can cause incorrect execution or performance degradation. This document details the three types of hazards and their solutions implemented in this processor.

---

## 1. Data Hazards

### What are Data Hazards?

Data hazards occur when instructions depend on results of previous instructions still in the pipeline.

### Types of Data Hazards

#### 1.1 RAW (Read After Write) - **MOST COMMON**

**Problem**: Instruction tries to read a register before a previous instruction writes to it.

**Example**:
```assembly
ADD x1, x2, x3    # WB stage: Writes x1 in cycle 5
SUB x4, x1, x5    # EX stage: Needs x1 in cycle 3
```

**Timeline without forwarding**:
```
Cycle:    1    2    3    4    5
ADD:     IF   ID   EX   MEM  WB   ← writes x1
SUB:          IF   ID   EX   MEM  ← needs x1 (stall!)
```

**Solution**: **Data Forwarding (Bypassing)**

#### 1.2 WAW (Write After Write)

**Problem**: Two instructions write to the same register.

**Example**:
```assembly
ADD x1, x2, x3    # Writes x1
SUB x1, x4, x5    # Also writes x1
```

**Why it's not a problem in our design**:
- Instructions write in order (WB is in-order)
- Later instruction naturally overwrites earlier one
- No special handling needed

#### 1.3 WAR (Write After Read)

**Problem**: Instruction writes to register before earlier instruction reads it.

**Why it cannot occur in our design**:
- Registers are read in ID stage (stage 2)
- Registers are written in WB stage (stage 5)
- Reading always happens before writing in program order

---

## 2. Data Forwarding Implementation

### Forwarding Unit Logic

The hazard unit (`hazard_unit.v`) implements forwarding using the following logic:

#### Forward Operand A (Rs1)

```verilog
// EX Hazard (most recent result)
if (EX_MEM.RegWrite && 
    EX_MEM.Rd != 0 && 
    EX_MEM.Rd == ID_EX.Rs1)
    ForwardA = 10  // Forward from EX/MEM

// MEM Hazard (older result)
else if (MEM_WB.RegWrite && 
         MEM_WB.Rd != 0 && 
         MEM_WB.Rd == ID_EX.Rs1)
    ForwardA = 01  // Forward from MEM/WB

else
    ForwardA = 00  // No forwarding
```

#### Forward Operand B (Rs2)

```verilog
// EX Hazard
if (EX_MEM.RegWrite && 
    EX_MEM.Rd != 0 && 
    EX_MEM.Rd == ID_EX.Rs2)
    ForwardB = 10

// MEM Hazard  
else if (MEM_WB.RegWrite && 
         MEM_WB.Rd != 0 && 
         MEM_WB.Rd == ID_EX.Rs2)
    ForwardB = 01

else
    ForwardB = 00
```

### Forwarding Priority

**EX/MEM has higher priority than MEM/WB** because it contains the more recent result.

**Example**:
```assembly
ADD x1, x2, x3    # Cycle 1
SUB x1, x1, x4    # Cycle 2 - overwrites x1
AND x5, x1, x6    # Cycle 3 - needs most recent x1
```

Without priority, AND might get old value from ADD instead of SUB.

### Forwarding Paths

```
EX/MEM.ALU_result ──┐
                    ├──> MUX ──> ALU Operand A
ID/EX.Rs1_data    ──┤
MEM/WB.WB_data    ──┘

EX/MEM.ALU_result ──┐
                    ├──> MUX ──> ALU Operand B
ID/EX.Rs2_data    ──┤
MEM/WB.WB_data    ──┘
```

### Example: RAW Hazard Resolved by Forwarding

```assembly
ADD x1, x2, x3    # x1 = x2 + x3
SUB x4, x1, x5    # x4 = x1 - x5  (needs x1)
```

**Timeline with forwarding**:
```
Cycle:    1    2    3    4    5
ADD:     IF   ID   EX   MEM  WB
SUB:          IF   ID   EX   MEM
                         ↑
                    Forward x1 from ADD's EX/MEM
```

**Result**: No stall needed! ✅

---

## 3. Load-Use Hazard (Cannot be Forwarded)

### The Problem

Load instructions don't produce their result until **MEM stage**, but the next instruction needs the data in **EX stage**.

**Example**:
```assembly
LW  x1, 0(x2)     # Load data into x1
ADD x3, x1, x4    # Immediately use x1
```

**Timeline**:
```
Cycle:    1    2    3    4    5
LW:      IF   ID   EX   MEM  WB   ← x1 available in MEM
ADD:          IF   ID   EX   MEM  ← needs x1 in EX (too early!)
```

**Problem**: ADD needs x1 in cycle 3, but LW only produces it in cycle 4!

### Solution: Pipeline Stall (Insert Bubble)

**Stall detection**:
```verilog
if (ID_EX.MemRead &&  // Previous instruction is a load
    (ID_EX.Rd == IF_ID.Rs1 || ID_EX.Rd == IF_ID.Rs2))  // Dependency
    Stall = 1  // Insert 1-cycle bubble
```

**Stall implementation**:
1. Freeze PC (don't fetch next instruction)
2. Freeze IF/ID register (keep current instruction)
3. Insert NOP in ID/EX (bubble in pipeline)

**Timeline with stall**:
```
Cycle:    1    2    3    4    5    6
LW:      IF   ID   EX   MEM  WB
ADD:          IF   ID  [STALL] EX   MEM
                              ↑
                         Forward from MEM/WB
```

**Penalty**: 1 cycle per load-use hazard

### Code Scheduling to Avoid Stalls

**Bad (causes stall)**:
```assembly
LW  x1, 0(x2)     # Load x1
ADD x3, x1, x4    # Immediate use - STALL!
```

**Good (no stall)**:
```assembly
LW  x1, 0(x2)     # Load x1
ADD x5, x6, x7    # Independent instruction
ADD x3, x1, x4    # Use x1 - no stall needed
```

Compiler can reorder independent instructions to avoid stalls!

---

## 4. Control Hazards (Branch Hazards)

### The Problem

Branch outcome is not known until **EX stage**, but PC needs to be updated in **IF stage**.

**Example**:
```assembly
BEQ x1, x2, target    # Branch decision in EX
ADD x3, x4, x5        # Fetched but might be wrong
SUB x6, x7, x8        # Also fetched
target: ...
```

**Timeline**:
```
Cycle:    1    2    3    4
BEQ:     IF   ID   EX   MEM   ← branch decision here
ADD:          IF   ID   EX    ← might need to be flushed
SUB:               IF   ID    ← might need to be flushed
```

### Solution 1: Branch Prediction

**Strategy**: **Predict Not-Taken**
- Assume branch will not be taken
- Continue fetching sequential instructions
- If prediction wrong, flush and restart

**Advantages**:
- Simple implementation
- No additional hardware
- Works well for loops (most iterations don't branch out)

**Disadvantages**:
- Only ~50% accuracy for taken branches
- 2-cycle penalty on misprediction

### Solution 2: Early Branch Resolution

**Move branch decision from MEM to EX stage**:
- Calculate branch target in EX
- Evaluate branch condition in EX
- Reduces penalty from 3 cycles to 2 cycles

**Implementation**:
```verilog
// In EX stage
branch_target = PC + immediate
branch_taken = (condition == true) && Branch_signal
```

### Solution 3: Pipeline Flush

**When branch is taken** (misprediction):
1. Flush IF/ID register (discard fetched instruction)
2. Flush ID/EX register (discard decoded instruction)
3. Update PC to branch target
4. Restart fetching from target

**Implementation**:
```verilog
if (branch_taken) begin
    Flush_IF_ID = 1;   // Clear IF/ID
    Flush_ID_EX = 1;   // Clear ID/EX
    PC = branch_target; // Jump to target
end
```

**Timeline with flush**:
```
Cycle:    1    2    3    4    5
BEQ:     IF   ID   EX   MEM  WB
ADD:          IF   ID  [FLUSH]
SUB:               IF  [FLUSH]
Target:                 IF    ID   EX   ← restart here
```

**Penalty**: 2 cycles on taken branch (with early resolution)

### Branch Penalty Calculation

```
Branch_Penalty = (Taken_Branches × Misprediction_Rate × Cycles_Per_Misprediction)
```

**Example**:
- 20% of instructions are branches
- 50% of branches are taken (worst case for predict not-taken)
- 2 cycles per misprediction
- **Penalty**: 0.20 × 0.50 × 2 = **0.20 extra cycles per instruction**

---

## 5. Structural Hazards

### What are Structural Hazards?

Hardware resource conflicts when multiple instructions need the same hardware simultaneously.

### Why They Don't Occur in Our Design

#### Register File
- **2 read ports**: Can read Rs1 and Rs2 simultaneously
- **1 write port**: Write happens in WB stage (different from read stages)
- **Solution**: Multiple ports eliminate conflicts

#### Memory
- **Separate instruction and data memory** (Harvard architecture)
- IF stage uses instruction memory
- MEM stage uses data memory
- **Solution**: No conflict possible

#### ALU
- Only used in EX stage
- One instruction in EX at a time
- **Solution**: No conflict possible

---

## 6. Hazard Summary Table

| Hazard Type | Frequency | Solution | Penalty |
|-------------|-----------|----------|---------|
| **RAW (no load)** | High (~30%) | Data forwarding | 0 cycles ✅ |
| **Load-use RAW** | Medium (~5-10%) | Stall + Forward | 1 cycle |
| **Branch (not taken)** | Low (~10%) | Predict not-taken | 0 cycles ✅ |
| **Branch (taken)** | Low (~10%) | Flush pipeline | 2 cycles |
| **WAW** | N/A | In-order WB | 0 cycles ✅ |
| **WAR** | N/A | Cannot occur | 0 cycles ✅ |
| **Structural** | N/A | Design prevents | 0 cycles ✅ |

---

## 7. Performance Impact

### Without Hazard Handling
- CPI → ∞ (incorrect execution)
- Program produces wrong results

### With Stall-Only (No Forwarding)
- CPI ≈ 1.5 - 2.0
- Every RAW hazard causes stall

### With Forwarding + Stalling
- CPI ≈ 1.1 - 1.3
- Most hazards resolved by forwarding
- Only load-use and branches cause stalls

**Forwarding Impact**:
```
Speedup = CPI_stall_only / CPI_with_forwarding
        ≈ 1.7 / 1.2 = 1.42x faster! 🚀
```

---

## 8. Testing Hazard Handling

### Test Cases

#### Test 1: Back-to-Back RAW
```assembly
ADD x1, x2, x3
SUB x4, x1, x5    # Forwarding from EX/MEM
AND x6, x4, x7    # Forwarding from EX/MEM
```

#### Test 2: Load-Use Hazard
```assembly
LW  x1, 0(x2)
ADD x3, x1, x4    # Stall required
```

#### Test 3: Multiple Forwarding
```assembly
ADD x1, x2, x3
SUB x1, x1, x4    # Forward x1 from EX/MEM
OR  x5, x1, x6    # Forward x1 from EX/MEM (priority)
```

#### Test 4: Branch Hazard
```assembly
BEQ x1, x2, label
ADD x3, x4, x5    # Might be flushed
SUB x6, x7, x8    # Might be flushed
label: XOR x9, x10, x11
```

### Verification
- Check forwarding signals (ForwardA, ForwardB)
- Verify stall insertion for load-use
- Confirm pipeline flush on taken branch
- Validate correct final register values

---

## 9. Advanced Topics

### Dynamic Branch Prediction
- **2-bit saturating counter**
- **Branch History Table (BHT)**
- **Branch Target Buffer (BTB)**

### Speculative Execution
- Execute both paths
- Commit correct one
- Higher IPC but more complex

### Out-of-Order Execution
- Scoreboarding
- Tomasulo's algorithm
- Eliminates many stalls

---

## Conclusion

Effective hazard handling is critical for pipelined processor performance:
- **Forwarding** eliminates most data hazards (0 penalty)
- **Stalling** handles unavoidable load-use hazards (1 cycle)
- **Flushing** handles control hazards (2 cycles)

Result: ~3-4x speedup over single-cycle design! 🎉
