# Architecture Documentation

## Overview

This document provides detailed information about the 5-stage pipelined RISC-V processor architecture, including datapath organization, control signals, and implementation details.

## Processor Architecture

### High-Level Block Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                        Pipelined Processor                          │
├────────┬──────────┬──────────┬──────────┬─────────────────────────┤
│   IF   │    ID    │    EX    │   MEM    │          WB             │
├────────┼──────────┼──────────┼──────────┼─────────────────────────┤
│ Fetch  │ Decode   │ Execute  │ Memory   │ Write                   │
│ Instr  │ Read RF  │ ALU Op   │ Load/    │ Back                    │
│        │ Gen Ctrl │ Branch   │ Store    │                         │
└────────┴──────────┴──────────┴──────────┴─────────────────────────┘
    │          │          │          │              │
    └──────────┴──────────┴──────────┴──────────────┘
                    Forwarding Paths
```

## Pipeline Stages Detail

### 1. Instruction Fetch (IF) Stage

**Module**: `stage_if.v`

**Functions**:
- Fetch instruction from instruction memory
- Increment PC by 4 (next sequential instruction)
- Handle branch/jump target updates

**Inputs**:
- `clk`, `rst`
- `PCSrc` - PC source selector (branch/jump)
- `branch_target` - Target address for branches/jumps
- `stall` - Stall signal from hazard unit

**Outputs**:
- `instruction` - 32-bit instruction
- `PC_plus_4` - Next sequential PC value

**Implementation Details**:
```verilog
// PC Update Logic
if (stall)
    PC <= PC;  // Hold PC
else if (PCSrc)
    PC <= branch_target;  // Branch taken
else
    PC <= PC + 4;  // Sequential
```

### 2. Instruction Decode (ID) Stage

**Module**: `stage_id.v`

**Functions**:
- Decode instruction fields (opcode, funct3, funct7)
- Read source registers from register file
- Generate control signals
- Extract and sign-extend immediate values
- Detect hazards

**Instruction Format Decoding**:

```
R-type: [funct7|rs2|rs1|funct3|rd|opcode]
I-type: [imm[11:0]|rs1|funct3|rd|opcode]
S-type: [imm[11:5]|rs2|rs1|funct3|imm[4:0]|opcode]
B-type: [imm[12|10:5]|rs2|rs1|funct3|imm[4:1|11]|opcode]
U-type: [imm[31:12]|rd|opcode]
J-type: [imm[20|10:1|11|19:12]|rd|opcode]
```

**Control Signals Generated**:
- `RegWrite` - Enable register write
- `MemRead` - Enable memory read
- `MemWrite` - Enable memory write
- `MemToReg` - Select write-back data source
- `ALUSrc` - Select ALU operand source
- `ALUOp` - ALU operation code
- `Branch` - Branch instruction indicator
- `Jump` - Jump instruction indicator

### 3. Execute (EX) Stage

**Module**: `stage_ex.v`

**Functions**:
- Perform ALU operations
- Calculate memory addresses
- Compute branch conditions and targets
- Select operands with forwarding

**ALU Operations**:
```verilog
case (ALUOp)
    4'b0000: result = A + B;        // ADD
    4'b0001: result = A - B;        // SUB
    4'b0010: result = A & B;        // AND
    4'b0011: result = A | B;        // OR
    4'b0100: result = A ^ B;        // XOR
    4'b0101: result = A << B[4:0];  // SLL
    4'b0110: result = A >> B[4:0];  // SRL
    4'b0111: result = $signed(A) >>> B[4:0]; // SRA
    4'b1000: result = ($signed(A) < $signed(B)) ? 1 : 0; // SLT
    4'b1001: result = (A < B) ? 1 : 0; // SLTU
endcase
```

**Forwarding Logic**:
```verilog
// Forward from EX/MEM stage
if (EX_MEM_RegWrite && EX_MEM_Rd != 0 && EX_MEM_Rd == ID_EX_Rs1)
    ForwardA = 2'b10;  // Forward from EX/MEM
    
// Forward from MEM/WB stage
else if (MEM_WB_RegWrite && MEM_WB_Rd != 0 && MEM_WB_Rd == ID_EX_Rs1)
    ForwardA = 2'b01;  // Forward from MEM/WB
    
// Similar logic for ForwardB and Rs2
```

**Branch Condition Evaluation**:
```verilog
case (Branch_Type)
    3'b000: branch_taken = (rs1_data == rs2_data);      // BEQ
    3'b001: branch_taken = (rs1_data != rs2_data);      // BNE
    3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data));  // BLT
    3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
    3'b110: branch_taken = (rs1_data < rs2_data);       // BLTU
    3'b111: branch_taken = (rs1_data >= rs2_data);      // BGEU
endcase
```

### 4. Memory (MEM) Stage

**Module**: `stage_mem.v`

**Functions**:
- Access data memory for loads/stores
- Pass through ALU results
- Forward data to earlier stages if needed

**Memory Operations**:
```verilog
// Load operations
if (MemRead) begin
    case (funct3)
        3'b000: data_out = {{24{mem_data[7]}}, mem_data[7:0]};    // LB
        3'b001: data_out = {{16{mem_data[15]}}, mem_data[15:0]};  // LH
        3'b010: data_out = mem_data;                               // LW
        3'b100: data_out = {24'b0, mem_data[7:0]};                 // LBU
        3'b101: data_out = {16'b0, mem_data[15:0]};                // LHU
    endcase
end

// Store operations
if (MemWrite) begin
    case (funct3)
        3'b000: memory[address] = rs2_data[7:0];      // SB
        3'b001: memory[address] = rs2_data[15:0];     // SH
        3'b010: memory[address] = rs2_data;           // SW
    endcase
end
```

### 5. Write Back (WB) Stage

**Module**: `stage_wb.v`

**Functions**:
- Select data to write to register file
- Perform actual register write

**Write-Back Multiplexer**:
```verilog
assign WriteData = MemToReg ? MemData : ALUResult;

// Register file write
if (RegWrite && Rd != 0)
    registers[Rd] <= WriteData;
```

## Pipeline Registers

### IF/ID Pipeline Register

**Module**: `if_id_reg.v`

**Stored Data**:
- `instruction` [31:0]
- `PC` [31:0]
- `PC_plus_4` [31:0]

**Control**:
- Stall: Hold current values
- Flush: Clear to NOPs (bubbles)

### ID/EX Pipeline Register

**Module**: `id_ex_reg.v`

**Stored Data**:
- Control signals (RegWrite, MemRead, MemWrite, etc.)
- Register data (Rs1_data, Rs2_data)
- Immediate value
- Register addresses (Rs1, Rs2, Rd)
- PC value
- PC_plus_4

### EX/MEM Pipeline Register

**Module**: `ex_mem_reg.v`

**Stored Data**:
- Control signals (MemRead, MemWrite, RegWrite, MemToReg)
- ALU result
- Rs2 data (for stores)
- Destination register (Rd)
- Branch information

### MEM/WB Pipeline Register

**Module**: `mem_wb_reg.v`

**Stored Data**:
- Control signals (RegWrite, MemToReg)
- Memory read data
- ALU result
- Destination register (Rd)

## Hazard Unit

**Module**: `hazard_unit.v`

### Forwarding Detection

**EX Hazard (EX/MEM → EX)**:
```verilog
if (EX_MEM.RegWrite 
    && EX_MEM.Rd != 0 
    && EX_MEM.Rd == ID_EX.Rs1)
    ForwardA = 2'b10;
```

**MEM Hazard (MEM/WB → EX)**:
```verilog
if (MEM_WB.RegWrite 
    && MEM_WB.Rd != 0 
    && !(EX_MEM.RegWrite && EX_MEM.Rd == ID_EX.Rs1)
    && MEM_WB.Rd == ID_EX.Rs1)
    ForwardA = 2'b01;
```

### Stall Detection

**Load-Use Hazard**:
```verilog
if (ID_EX.MemRead 
    && (ID_EX.Rd == IF_ID.Rs1 || ID_EX.Rd == IF_ID.Rs2))
    Stall = 1;
```

### Branch Flush

**Control Hazard**:
```verilog
if (Branch_Taken)
    Flush_IF_ID = 1;
    Flush_ID_EX = 1;
```

## Control Unit

**Module**: `control_unit.v`

### Opcode Decoding

| Opcode   | Type | Description |
|----------|------|-------------|
| 0110011  | R    | Register-register ops |
| 0010011  | I    | Immediate ops |
| 0000011  | I    | Load instructions |
| 0100011  | S    | Store instructions |
| 1100011  | B    | Branch instructions |
| 1101111  | J    | JAL |
| 1100111  | I    | JALR |
| 0110111  | U    | LUI |
| 0010111  | U    | AUIPC |

### Control Signal Generation

Example for R-type:
```verilog
RegWrite  = 1;
MemRead   = 0;
MemWrite  = 0;
MemToReg  = 0;
ALUSrc    = 0;
ALUOp     = {funct7[5], funct3};
Branch    = 0;
```

## Register File

**Module**: `register_file.v`

**Specifications**:
- 32 registers (x0-x31)
- x0 hardwired to 0
- 2 read ports (simultaneous)
- 1 write port
- Write on clock edge

**Implementation**:
```verilog
// Read (combinational)
assign rs1_data = (rs1 == 0) ? 32'b0 : registers[rs1];
assign rs2_data = (rs2 == 0) ? 32'b0 : registers[rs2];

// Write (sequential)
always @(posedge clk) begin
    if (RegWrite && rd != 0)
        registers[rd] <= write_data;
end
```

## Performance Considerations

### Critical Path Analysis

**Longest Path**: IF → ID → EX → MEM → WB

**Stage Delays** (approximate):
- IF: Instruction memory access
- ID: Register file read + Control decode
- EX: ALU operation + Forwarding mux
- MEM: Data memory access
- WB: Register file write

**Optimization**: Balance stage delays for maximum clock frequency

### Hazard Impact

**Forwarding Only**: 0 cycle penalty
**Stall**: 1 cycle penalty (load-use)
**Flush**: 2 cycle penalty (branch misprediction)

## Testing Strategy

1. **Unit Testing**: Test each module independently
2. **Integration Testing**: Test stage combinations
3. **Instruction Testing**: Test each instruction type
4. **Hazard Testing**: Test all hazard scenarios
5. **Corner Cases**: Edge cases and special conditions

## Verification Checklist

- [ ] All RV32I instructions execute correctly
- [ ] Data forwarding works for all combinations
- [ ] Stalls inserted correctly for load-use hazards
- [ ] Branches flush pipeline correctly
- [ ] Register x0 always reads 0
- [ ] Pipeline stages isolated properly
- [ ] No timing violations
- [ ] Memory operations aligned correctly
