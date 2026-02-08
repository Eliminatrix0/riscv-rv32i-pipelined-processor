`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.06.2025 11:59:43
// Design Name: 
// Module Name: hazard_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Generating forwarding muxes control signals. Since it handles the reset signals
// to the pipeline regs, I'm adding reset handling part to this unit as well to avoid multi-driver issues.
//              Implementing static branch prediction
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module hazard_and_reset_unit(
    input program_rst, processor_rst,   //Pipeline regs rst and full processor rst signals   
    input [4:0] rs1D, rs2D, rs1E, rs2E,
    input [4:0] rdE, rdM, rdW,
    input RF_WENM, RF_WENW,
    input br_taken, sel_ldE_1,          //Branch decision & MSB of sel_ldE( to check if lw or not)
    output reg [1:0] fwdAE, fwdBE,
    output Stall_IF, Stall_ID,
    output Flush_IF, Flush_ID, Flush_EX, Flush_MEM, Flush_WB
    );
    wire ld_stall;
    assign ld_stall = ((rs1D == rdE) || (rs2D == rdE)) && (sel_ldE_1 == 1'b1);  //asserted if lw hazard detected
    //Flush signals
    assign Flush_IF = program_rst | processor_rst;
    assign Flush_ID = br_taken | program_rst | processor_rst;
    assign Flush_EX = br_taken | ld_stall | program_rst | processor_rst;
    assign Flush_MEM = program_rst | processor_rst;
    assign Flush_WB = program_rst | processor_rst;
    //Stall signals
    assign Stall_IF = ld_stall;
    assign Stall_ID = ld_stall; 
    
    always @ (*)        //srcA forwarding mux
        begin
            //If both MEM & WB conditions match, priority to be given to latest MEM instr
            //Thus modelled using if-else (priority based selection) and not case
            if ((rs1E == rdM) && (RF_WENM == 1'b1) && (rs1E != 'd0))         //MEM stage match
                begin
                fwdAE = 2'b01;
                end
            else if ((rs1E == rdW) && (RF_WENW == 1'b1) && (rs1E != 'd0))    //WB stage match
                fwdAE = 2'b10;
            else                                            //No RAW hazard, no forwarding
                fwdAE = 2'b00;     
        end
    
    always @ (*)        //srcB forwarding mux
        begin
            //If both MEM & WB conditions match, priority to be given to latest MEM instr
            //Thus modelled using if-else (priority based selection) and not case
            if ((rs2E == rdM) && (RF_WENM == 1'b1) && (rs2E != 'd0))         //MEM stage match
                fwdBE = 2'b01;
            else if ((rs2E == rdW) && (RF_WENW == 1'b1) && (rs2E != 'd0))    //WB stage match
                fwdBE = 2'b10;
            else                                            //No RAW hazard, no forwarding
                fwdBE = 2'b00;                    
        end
endmodule
