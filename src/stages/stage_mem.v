`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Arun
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Memory stage
// Module Name: MEM_stage
// Project Name: RV32I 5-stage pipelined processor
// Target Devices: 
// Tool Versions: 
// Description: Data memory read/write stage
// 
// Dependencies: data_memory
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MEM_stage(
    input clk, rst, DM_WENM,
    input [31:0] alu_outM, dm_wdM,
    output [31:0] resultM, dm_rdM
    );
    assign resultM = alu_outM;                  //had to use different name to avoid inout usage
    data_memory DM (clk, rst, DM_WENM, alu_outM, dm_wdM, dm_rdM);
endmodule
