`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Arun
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Execute stage
// Module Name: EX_stage
// Project Name: RV32I 5-stage pipelined processor
// Target Devices: 
// Tool Versions: 
// Description: Contains ALU and branch target adder. 
// 
// Dependencies: ALU
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module EX_stage(
    input sel_srcBE,                                    //srcB select signal
    input [1:0] sel_sE, sel_lE, sel_alu_outE,           //Exec_unit operation & output select signals
    input sel_aE, sel_compE,
    input [1:0] fwdAE, fwdBE,                           //forward to srcA & srcB control signals
    input [31:0] rs1valE, rs2valE, immE, PCE,           //register values and immediate value
    input [31:0] resultM, resultW,                    //ALU outputs of MEM and WB stages (data forwarding lines)
    output zE, cE, nE,                                  //ALU flags goinig to branch control unit
    output [31:0] alu_outE, dm_wdE, pc_trgtE            //ALU output of EX, DM write data and PC target value
    );
    reg [31:0] srcA, srcB_data;                         //srcB_data is the wire from the forwarding mux
    wire [31:0] srcB;
    
    assign srcB = ((sel_srcBE)? immE : srcB_data);      //final srcB select mux b/w data and imm
    assign pc_trgtE = PCE + immE;                       //Branch target value
    assign dm_wdE = srcB_data;                          //Data line in to DM, used by store instr
    
    always @ (*)            //forwarding muxes
        begin
            case(fwdAE)     //srcA source control mux
                2'b00: srcA = rs1valE;
                2'b01: srcA = resultM;
                2'b10: srcA = resultW;
                default: srcA = rs1valE;
            endcase
            
            case(fwdBE)     //srcB_data source control mux
                2'b00: srcB_data = rs2valE;
                2'b01: srcB_data = resultM;
                2'b10: srcB_data = resultW;
                default: srcB_data = rs2valE;
            endcase
        end
    ALU exec_unit (srcA, srcB, sel_aE, sel_compE, sel_sE, sel_lE, sel_alu_outE, zE,cE,nE, alu_outE);
endmodule
