`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Arun
// 
// Create Date: 25.06.2025 18:04:12
// Design Name: Register file
// Module Name: reg_file
// Project Name: RV32I 5-stage pipelined processor
// Target Devices: 
// Tool Versions: 
// Description: 32 32-bit register space. Two read ports (1 & 2) and one write port (port3).
//              Writes at posedge clk and reads are combinational.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Writes happen at negative edge. This helps reduce the RAW hazard window.
// Writes occur in the first half cycle and reading data in ID stage occurs in the later half.
//////////////////////////////////////////////////////////////////////////////////


module reg_file(
    input clk, rst,
    input we3,                      //write enable for port 3
    input [4:0] ad1, ad2, ad3,      //address lines to the 3 ports
    input [31:0] wd3,               //write in data line
    output reg [31:0] rd1, rd2      //read out data lines from port 1 and 2  
    );
    integer i;
    reg [31:0] RF [0:31];           //32 registers
    
    initial
        begin
            for (i = 0; i <=32; i = i+1)
                RF[i] = 0;
        end
    
    always @ (negedge clk)
        begin
            if(rst == 1'b1) begin
                for(i = 0; i < 32; i = i + 1)
                    RF[i] <= 'd0;
            end
            else    
                begin
                    if (we3 == 1'b1) begin  //write enable asserted
                        RF[ad3] <= wd3;     //write at clk edge
                        RF[0] <= 0;         //x0 is always 0
                    end  
                end
        end  
    
    always @ (*)     
        begin
            rd1 = RF[ad1];
            rd2 = RF[ad2];
        end 
endmodule
