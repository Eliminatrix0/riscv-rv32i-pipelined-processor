`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Instruction Fetch stage
// Module Name: IF_stage
// Project Name: RV32I 5-stage pipelined processor 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: instr_memory, PC_reg
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IF_stage(
    input clk, Flush_IF,
    input [31:0] pc_trgt,   //Branch target from EX unit
    input Stall_IF,         //Stalls IF if asserted, connects to PC reg enable
    input br_taken,
    output [31:0] PCF, PCp4F, instrF      
    );
    wire [31:0] pc_in, nxt_instr, pc_out;                  //PC input, output and next instr wires
    //Internal wires
    assign nxt_instr = pc_out + 'd4;                        //Next instruction is the next word location, so +4
    assign pc_in = ((br_taken)? pc_trgt : nxt_instr);      //PC value-in mux
    //output wires
    assign PCF = pc_out;
    assign PCp4F = nxt_instr;
    
    PC_reg       PC (clk, Flush_IF, Stall_IF, pc_in, pc_out);
    instr_memory IM (pc_out, instrF);
endmodule

module PC_reg(
    input clk, rst, PC_EN, 
    input [31:0] pc_in,
    output reg [31:0] pc_out
    );
    always @ (posedge clk)
        begin
            if(rst == 1'b1)
                pc_out <= 'd0;
            else if (PC_EN == 1'b1)     //active low enable
                pc_out <= pc_out;
            else
                pc_out <= pc_in;
        end
endmodule
    
