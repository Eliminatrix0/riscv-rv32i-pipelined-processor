`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Pipelinne registers stage 1
// Module Name: IF_ID_registers
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


module IF_ID_registers(
    input clk, Flush_ID, Stall_ID,           //clk rst(flush) and ID stall signal
    input [31:0] instrF, PCF, PCp4F,     //inputs from IF
    output [31:0] instrD, PCD, PCp4D           //outpus to ID
    );
    
    reg [31:0] IR, PCval, PCp4val;  //Instr reg, PC value reg and PC+4 value reg
    //output wire assignments, driven by the registers
    assign instrD = IR;
    assign PCD = PCval;
    assign PCp4D = PCp4val;
    
    always @ (posedge clk)
        begin
            if(Flush_ID == 1'b1)                 //Full reset
                begin
                    IR <= 'd0;
                    PCval <= 'd0;
                    PCp4val <= 'd0;
                end
            else if (Stall_ID == 1'b1)      //hold values if stalled
                begin
                    IR <= IR;
                    PCval <= PCval;
                    PCp4val <= PCp4val;
                end
            else                            //mormal operation
                begin
                    IR <= instrF;
                    PCval <= PCF;
                    PCp4val <= PCp4F;
                end       
        end
endmodule
