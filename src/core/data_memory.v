`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 18:04:12
// Design Name: Data memory module
// Module Name: data_memory
// Project Name: RV32I 5-stage pipelined processor 
// Target Devices: 
// Tool Versions: 
// Description: The reads are combinational. Writes happen at +ve clock edge if WE is 1.
//              Mis-aligned word addressing not supported. DM is byte addressible, but
//              the processor is word-oriented.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_memory(
    input clk, rst, we,     //write enable; high during store instruction only
    input [31:0] ad, wd,    //address bus and write in data bus
    output reg [31:0] rd    //read out bus
    );
    integer i;
    reg [31:0] dmem [0:100];  //100 locations, one word in each location; models aligned addressing
    
    initial
    begin
        for (i = 0; i <=20; i = i+1)
            dmem[i] = 0;
        dmem[1] = 'h111;
        //dmem[8] = 'd50;
    end
    
    always @ (posedge clk)
        begin
            if(rst == 1'b1) begin
                for(i = 0; i < 100; i = i + 1)
                    dmem[i] <= 'd0;
            end
            else
                begin
                    if (we == 1'b1) begin  //write enable asserted
                        dmem[ad] <= wd;     //write at clk edge
                    end  
                end
        end
        
        always @ (*)     
        begin
            rd = dmem[ad];
        end 
endmodule
