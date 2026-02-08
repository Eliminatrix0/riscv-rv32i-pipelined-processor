`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Me
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Pipeline registers stage 3
// Module Name: EX_MEM_registers
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


module EX_MEM_registers(
    input clk, rst,
    input RF_WENE, DM_WENE,                             //write enables to RF and DM
    input [1:0] sel_ldE,                                //RF write-in (load) source select signal
    input [4:0] rdE,                                    //Dest reg name, for use by hazard unit
    input [31:0] alu_outE, dm_wdE,                      //EX ALU out, store instr data line
    input [31:0] PCp4E,                                 //PC+4 value of EX instr
    output reg RF_WENM, DM_WENM,
    output reg [1:0] sel_ldM,                                //RF write (load) in source select signal
    output reg [4:0] rdM,                                    //Dest Register name of current MEM instruction, for use by hazard unit
    output reg [31:0] alu_outM, dm_wdM,                      //EX ALU out, store instr data line
    output reg [31:0] PCp4M                                  //PC+4 value of current MEM instr        
    );
    
    always @ (posedge clk)
        begin
            if (rst ==1'b1) //reset condition
                begin
                    RF_WENM <= 1'd0;
                    DM_WENM <= 1'd0;
                    sel_ldM <= 2'd0;
                    rdM <= 5'd0;
                    alu_outM <= 32'd0;
                    dm_wdM <= 32'd0;
                    PCp4M <= 32'd0;  
                end
            else        //normal operations
                begin
                    RF_WENM <= RF_WENE;
                    DM_WENM <= DM_WENE;
                    sel_ldM <= sel_ldE;
                    rdM <= rdE;
                    alu_outM <= alu_outE;
                    dm_wdM <= dm_wdE;
                    PCp4M <= PCp4E;   
                end
        end
endmodule
