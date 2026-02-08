`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 22:02:42
// Design Name: Pipeline registers stage 2
// Module Name: ID_EX_registers
// Project Name: RV32I 5-stage pipelined processor
// Target Devices: 
// Tool Versions: 
// Description: Registers ID stage outputs and ALL control signals for the current ID instruction at posedge
//              clk and drives EX stage logic
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ID_EX_registers(
    input clk, rst,                                     //clock and reset(flush) signals
    input RF_WEND, DM_WEND,                             //write enables to RF and DM
    input sel_srcBD,                                    //srcB select signal
    input [1:0] sel_ldD,                                //RF write (load) in source select signal
    //input br_takenD,                                    //Branch target(PC source) select signal
    //input [1:0] sel_immD,                               //immediate field select signals
    input [1:0] sel_sD, sel_lD, sel_alu_outD,           //Exec_unit operation select signals
    input sel_aD, sel_compD,
    
    input [1:0] br_instrD,                               //Indicates whether current instr is B-type/J-type or not
    input [2:0] func3D,                                  //func3 field, needs to be passed on for use by branch control unit
    input [4:0] rs1D, rs2D, rdD,                         //Register names of current ID instruction, for use by hazard unit   
    input [31:0] rs1valD, rs2valD, immD,                 //register values and immediate value
    input [31:0] PCD, PCp4D,                             //PC and PC+4 
    
    output reg RF_WENE, DM_WENE,                             //write enables to RF and DM
    output reg sel_srcBE,                                    //srcB select signal
    output reg [1:0] sel_ldE,                                //RF write (load) in source select signal
    //output reg br_takenE,                                    //Branch target(PC source) select signal
    //output reg [1:0] sel_immE,                               //immediate field select signals
    output reg [1:0] sel_sE, sel_lE, sel_alu_outE,           //Exec_unit operation select signals
    output reg sel_aE, sel_compE,
    output reg [1:0] br_instrE,                              //Indicates whether current instr is B-type/J-type or not
    output reg [2:0] func3E,                                 //func3 field, needs to be passed on for use by branch control unit
    output reg [4:0] rs1E, rs2E, rdE,                        //Register names of current EX instruction, for use by hazard unit   
    output reg [31:0] rs1valE, rs2valE, immE,                //register values and immediate value 
    output reg [31:0] PCE, PCp4E                             //PC and PC+4 value of current EX instr   
    );
    
    always @ (posedge clk)
        begin
            if(rst ==1'b1)
                begin   //reset all regs, used when flushing
                    RF_WENE <= 1'd0;
                    DM_WENE <= 1'd0;
                    sel_srcBE <= 1'd0;
                    sel_ldE <= 2'd0;
                    //br_takenE <= 1'd0;
                    //sel_immE <= 2'd0;
                    sel_sE <= 2'd0;
                    sel_lE <= 2'd0;
                    sel_alu_outE <= 2'd0;
                    sel_aE <= 1'd0;
                    sel_compE <= 1'd0;
                    br_instrE <= 2'd0;
                    func3E <= 3'd0;
                    rs1E <= 5'd0;
                    rs2E <= 5'd0;
                    rdE <= 5'd0;
                    rs1valE <= 32'd0;
                    rs2valE <= 32'd0;
                    immE <= 32'd0;
                    PCE <= 32'd0;
                    PCp4E <= 32'd0;   
                end
            else    //else capture ID values; normal operation
                begin
                    RF_WENE <= RF_WEND;
                    DM_WENE <= DM_WEND;
                    sel_srcBE <= sel_srcBD;
                    sel_ldE <= sel_ldD;
                    //br_takenE <= br_takenD;
                    //sel_immE <= sel_immD;
                    sel_sE <= sel_sD;
                    sel_lE <= sel_lD;
                    sel_alu_outE <= sel_alu_outD;
                    sel_aE <= sel_aD;
                    sel_compE <= sel_compD;
                    br_instrE <= br_instrD;
                    func3E <= func3D;
                    rs1E <= rs1D;
                    rs2E <= rs2D;
                    rdE <= rdD;
                    rs1valE <= rs1valD;
                    rs2valE <= rs2valD;
                    immE <= immD;
                    PCE <= PCD;
                    PCp4E <= PCp4D; 
                end
        end
endmodule
