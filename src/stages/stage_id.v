`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Arun
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Instruction decode stage
// Module Name: ID_stage
// Project Name: RV32I 5-stage pipelined processor
// Target Devices: 
// Tool Versions: 
// Description: Decodes instruction word and generates control signals for the current instruction.
//              Immediate value from instruction is extracted.
// Dependencies: reg_file, Imm_sign_ext
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ID_stage(
    input clk, rst, RF_WENW, 
    input [1:0] sel_immD,                    //comes from control unit
    input [4:0] rdW,                         //RD field from WB stage
    input [31:0] instrD, rf_wdW,            //Instruction and write back data from WB
    output [31:0] rs1valD, rs2valD, immD,   //Data values from rs1 & rs2 registers and imm fields
    output [4:0] rs1D, rs2D, rdD            //Register names of current ID instruction, for use by hazard unit 
    );
    //wire [4:0] rs1, rs2, rd;        //Reg file address fields from IR
    
    assign rs1D = instrD[19:15];
    assign rs2D = instrD[24:20];
    assign rdD = instrD[11:7];
    
    reg_file RF (.clk(clk), .rst(rst), .we3(RF_WENW), .ad1(rs1D), .ad2(rs2D), .ad3(rdW), .wd3(rf_wdW), .rd1(rs1valD), .rd2(rs2valD));
    imm_sign_extend sign_ext (.imm_src(sel_immD), .instr(instrD), .imm(immD));
endmodule
