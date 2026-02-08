`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 21:55:20
// Design Name: Immediate value sign extend module 
// Module Name: imm_sign_extend
// Project Name: RV32I 5-stage pipelined processor 
// Target Devices: 
// Tool Versions: 
// Description: Selects the required bits from the instruction, arranges them as 
//              per the instr (select signals from contrl path) and sign extends it 
//              to full 32-bit value readu to be sent to ALU.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Takes input direct from IR. This module is technically a part of ID.
// 
//////////////////////////////////////////////////////////////////////////////////


module imm_sign_extend(
    input [1:0] imm_src,        //control path output that selects the required fields as per instr.
    input [31:0] instr,         //instruction from IR
    output reg [31:0] imm       //sign extended immediate value
    );
    
    always @ (*)
        begin
            case (imm_src)
                2'b00: imm = {{20{instr[31]}}, instr[31:20]};                               //I-type instr
                2'b01: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};                  //S-type instr
                2'b10: imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};  //B-type instr
                2'b11: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};//J-type instr
                default: imm = 'd0;
            endcase
        end
endmodule