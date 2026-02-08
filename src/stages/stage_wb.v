`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Arun
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Write back stage
// Module Name: WB_stage
// Project Name: RV32I 5-stage pipelined processor 
// Target Devices: 
// Tool Versions: 
// Description: Checks whether result is to be written back to a register.
//              Selects which value to propagate to Register file WD port.
//              (ALU output, DM output or PC+4 (for J-type)) 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module WB_stage(
    input [1:0] sel_ldW,                    //output select signal                        
    input [31:0] resultW, dm_rdW, PCp4W,
    output reg [31:0] rf_wdW
    );
    
    always @ (*)
        begin
            case(sel_ldW)
                2'b00: rf_wdW = resultW;    //others
                2'b01: rf_wdW = PCp4W;      //J-type 
                2'b10: rf_wdW = dm_rdW;     //load instruction
                default: rf_wdW = resultW;
            endcase
        end
endmodule
