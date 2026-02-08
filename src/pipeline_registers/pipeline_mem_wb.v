`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Me
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Pipeline registers stage 4
// Module Name: MEM_WB_registers
// Project Name: RV32I 5-stage pipelined processor 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MEM_WB_registers(
    input clk, rst,
    input RF_WENM,                  //RF write enable of instruction of instr currently in WB
    input [1:0] sel_ldM,            //select lines to RF_WD mux
    input [31:0] resultM, dm_rdM,   //ALU output of M
    input [4:0] rdM,                //Dest register field of MEM instr
    input [31:0] PCp4M,             //PC+4 value of MEM instr
    
    output reg RF_WENW,                  //RF write enable of instruction of instr currently in WB
    output reg [1:0] sel_ldW,            //select lines to RF_WD mux
    output reg [31:0] resultW, dm_rdW,   //ALU output of M
    output reg [4:0] rdW,                //Dest register field of current WB instr
    output reg [31:0] PCp4W              //PC+4 value of current WB instr
    );
    
    always @ (posedge clk)
        begin
            if (rst == 1'b1)    //reset condition
                begin
                    RF_WENW <= 1'd0;
                    sel_ldW <= 1'd0;
                    resultW <= 32'd0;
                    dm_rdW <= 32'd0;
                    rdW <= 5'd0;
                    PCp4W <= 32'd0;  
                end
            else                //normal operations
                begin
                    RF_WENW <= RF_WENM;
                    sel_ldW <= sel_ldM;
                    resultW <= resultM;
                    dm_rdW <= dm_rdM;
                    rdW <= rdM;
                    PCp4W <= PCp4M;
                end
        end
endmodule
