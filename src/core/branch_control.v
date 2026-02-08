`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Arun
// 
// Create Date: 27.06.2025 13:19:01
// Design Name: 
// Module Name: branch_control
// Project Name: RV32I 5-stage pipelined processor
// Target Devices: 
// Tool Versions: 
// Description: Checks only and only whether a branch is to be taken or not. It only has direct control over PC source
//              Flushing of IF and ID stages is done by the Hazard unit.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module branch_control(
    input [1:0] br_instr,       //B-type(11) or J-type(01) or other type(00) info indicator; comes from ID_EX regs, originates from CU
    input [2:0] func3,          //to decide which B-type instr
    input z,c,n,                //ALU flags
    output reg br_taken         //Branch decision flag
    );
    
    always @ (*)
        begin
            if (br_instr[0] == 'b0)
                br_taken = 1'b0;        //Don't take branch if instruction is not a branch instr.
            else
                begin
                    if (br_instr[1] == 'b0) //Indicates J-type instr, unconditional branch
                        br_taken = 1'b1;
                    else                    //Indicates B-type instr, conditional branch
                        begin
                            case(func3)
                                3'b000: br_taken = z;       //BEQ; depends on zero flag
                                default: br_taken = z;      //default BEQ
                            endcase
                        end
                end
        end        
endmodule
