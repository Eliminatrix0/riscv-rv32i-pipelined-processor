`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Arun
// 
// Create Date: 27.06.2025 20:06:34
// Design Name: Processor top module
// Module Name: processor
// Project Name: RV32I 5-stage pipelined processor
// Target Devices: 
// Tool Versions: 
// Description: Integration of all stages, pipeline registers and control modules
// 
// Dependencies: IF, ID, EX, MEM, WB stages
//               IF_ID, ID_EX, EX_MEM, MEM_WB registers
//               control_unit, branch_control, hazard_unit
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module processor(
    input clk, processor_rst, program_rst
    );
    //Hazard unit control signals
    wire Stall_IF, Stall_ID;
    wire Flush_IF, Flush_ID, Flush_EX, Flush_MEM, Flush_WB;
    //Branch unit control signals
    wire [1:0] br_instrD, br_instrE;
    wire [2:0] func3D, func3E;
    wire br_takenE; //goes to IF and HU
    //ID control signals
    wire [1:0] sel_immD;
    //Exec/ALU control signals
    wire sel_srcBD, sel_srcBE;
    wire [1:0] sel_sD, sel_sE;
    wire [1:0] sel_lD, sel_lE;
    wire sel_aD, sel_aE;
    wire sel_compD, sel_compE;
    wire [1:0] sel_alu_outD, sel_alu_outE;
    //ALU forwarding muxes select lines
    wire [1:0] fwdAE, fwdBE;    //srcA & srcB source select lines respectively
    //MEM & WB control signals
    wire [1:0] sel_ldD, sel_ldE, sel_ldM, sel_ldW;
    //Memory write enables
    wire RF_WEND, RF_WENE, RF_WENM, RF_WENW;    //RF write enables
    wire DM_WEND, DM_WENE, DM_WENM, DM_WENW;    //DM write enables
    //Other inputs to control modules                
    wire [31:0] instrF, instrD;
    wire [4:0] rs1D, rs1E;
    wire [4:0] rs2D, rs2E;
    wire [4:0] rdD, rdE, rdM, rdW;
       
    //PC related lines
    wire [31:0] PCF, PCD, PCE;
    wire [31:0] PCp4F, PCp4D, PCp4E, PCp4M, PCp4W;
    //Other wires
    wire zE, cE, nE;                            //ALU condition codes/flags
    wire [31:0] pc_trgtE;
    wire [31:0] rs1valD, rs1valE;
    wire [31:0] rs2valD, rs2valE;
    wire [31:0] immD, immE;
    wire [31:0] alu_outE, alu_outM;
    wire [31:0] resultM, resultW;
    wire [31:0] dm_wdE, dm_wdM;
    wire [31:0] dm_rdM, dm_rdW;
    wire [31:0] rf_wdW; //Data coming in to RF from WB
    

    
    IF_stage IF(
        clk, Flush_IF,
        pc_trgtE,                   //Branch target from EX unit
        Stall_IF,                   //Stalls IF if asserted, connects to PC reg enable
        br_takenE,
        PCF, PCp4F, instrF      
    );
    
    IF_ID_registers reg1 (
        clk, Flush_ID, Stall_ID,    //clk rst(flush) and ID stall signal
        instrF, PCF, PCp4F,         //inputs from IF
        instrD, PCD, PCp4D          //outputs to ID
    );
    
    ID_stage ID(
        clk, processor_rst, RF_WENW, 
        sel_immD,                   //comes from control unit
        rdW,                        //RD field from WB stage
        instrD, rf_wdW,             //Instruction and write back data from WB
        rs1valD, rs2valD, immD,     //Data values from rs1 & rs2 registers and imm fields
        rs1D, rs2D, rdD             //Register names of current ID instruction, for use by hazard unit 
    );
    
    control_unit CU (
        instrD,                                 //full instruction from IM, not needed as only a few bits needed by CU
        //input z, c, n,                        //ALU status flags, not needed here as hazard unit takes care of branch control
        RF_WEND, DM_WEND,                       //write enables to RF and DM
        sel_srcBD,                              //srcB select signal
        sel_ldD,                                //RF write (load) in source select signal
        //output reg br_taken,                  //Branch target(PC source) select signal
        sel_immD,                               //immediate field select signals
        sel_sD, sel_lD, sel_alu_outD,           //Exec_unit operation select signals
        sel_aD, sel_compD,
        br_instrD,                              //Indicates whether current instr is B-type/J-type or not
        func3D                                  //func3 field, needs to be passed on for use by branch control unit
    );
    
    ID_EX_registers reg2 (
        clk, Flush_EX,                          //clock and reset(flush) signals
        RF_WEND, DM_WEND,                       //write enables to RF and DM
        sel_srcBD,                              //srcB select signal
        sel_ldD,                                //RF write (load) in source select signal
        //br_takenD,                            //Branch target(PC source) select signal
        //input [1:0] sel_immD,                 //immediate field select signals
        sel_sD, sel_lD, sel_alu_outD,           //Exec_unit operation select signals
        sel_aD, sel_compD,
        br_instrD,                              //Indicates whether current instr is B-type/J-type or not
        func3D,                                 //func3 field, needs to be passed on for use by branch control unit
        rs1D, rs2D, rdD,                        //Register names of current ID instruction, for use by hazard unit   
        rs1valD, rs2valD, immD,                 //register values and immediate value
        PCD, PCp4D,                             //PC and PC+4 
        
        RF_WENE, DM_WENE,                       //write enables to RF and DM
        sel_srcBE,                              //srcB select signal
        sel_ldE,                                //RF write (load) in source select signal
        //output reg br_takenE,                 //Branch target(PC source) select signal
        //output reg [1:0] sel_immE,            //immediate field select signals
        sel_sE, sel_lE, sel_alu_outE,           //Exec_unit operation select signals
        sel_aE, sel_compE,
        br_instrE,                              //Indicates whether current instr is B-type/J-type or not
        func3E,                                 //func3 field, needs to be passed on for use by branch control unit
        rs1E, rs2E, rdE,                        //Register names of current EX instruction, for use by hazard unit   
        rs1valE, rs2valE, immE,                 //register values and immediate value 
        PCE, PCp4E                              //PC and PC+4 value of current EX instr   
    );
    
    branch_control BCU (
        br_instrE,                               //B-type(11) or J-type(01) or other type(00) info indicator; comes from ID_EX regs, originates from CU
        func3E,                                  //to decide which B-type instr
        zE, cE, nE,                              //ALU flags
        br_takenE                                //Branch decision flag
        );
    
    EX_stage EX (
        sel_srcBE,                              //srcB select signal
        sel_sE, sel_lE, sel_alu_outE,           //Exec_unit operation & output select signals
        sel_aE, sel_compE,
        fwdAE, fwdBE,                           //forward to srcA & srcB control signals
        rs1valE, rs2valE, immE, PCE,            //register values and immediate value
        alu_outM, rf_wdW,                      //ALU outputs of MEM and WB stages (data forwarding lines)
        zE, cE, nE,                             //ALU flags goinig to branch control unit
        alu_outE, dm_wdE, pc_trgtE              //ALU output of EX, DM write data and PC target value
    );
    
    EX_MEM_registers reg3 (
        clk, Flush_MEM,
        RF_WENE, DM_WENE,                       //write enables to RF and DM
        sel_ldE,                                //RF write-in (load) source select signal
        rdE,                                    //Dest reg name, for use by hazard unit
        alu_outE, dm_wdE,                       //EX ALU out, store instr data line
        PCp4E,                                  //PC+4 value of EX instr
        RF_WENM, DM_WENM,
        sel_ldM,                                //RF write (load) in source select signal
        rdM,                                    //Dest Register name of current MEM instruction, for use by hazard unit
        alu_outM, dm_wdM,                       //EX ALU out, store instr data line
        PCp4M                                   //PC+4 value of current MEM instr        
        );
        
    MEM_stage MEM (
        clk, processor_rst, 
        DM_WENM,                                //DM write enable of current MEM instr
        alu_outM, dm_wdM,                       //ALU output and DM read in
        resultM, dm_rdM                         //resultM = alu_outM and DM read out
        );
        
    MEM_WB_registers reg4 (
        clk, Flush_WB,
        RF_WENM,                                //RF write enable of instruction of instr currently in WB
        sel_ldM,                                //select lines to RF_WD mux
        resultM, dm_rdM,                        //ALU output of M
        rdM,                                    //Dest register field of MEM instr
        PCp4M,                                  //PC+4 value of MEM instr
        
        RF_WENW,                                //RF write enable of instruction of instr currently in WB, goes to ID
        sel_ldW,                                //select lines to RF_WD mux
        resultW, dm_rdW,                        //ALU output of M
        rdW,                                    //Dest register field of current WB instr
        PCp4W                                   //PC+4 value of current WB instr
        );
        
    WB_stage WB (
        sel_ldW,                                //output select signal                        
        resultW, dm_rdW, PCp4W,                 //ALU output line, DM read out and PC+4 of of current WB instr
        rf_wdW                                  //RF write data of current WB instr
        );
        
    hazard_and_reset_unit HRU(
        program_rst, processor_rst,             //Pipeline regs rst and full processor rst signals   
        rs1D, rs2D, rs1E, rs2E,
        rdE, rdM, rdW,
        RF_WENM, RF_WENW,
        br_takenE, sel_ldE[1],                  //Branch decision & MSB of sel_ldE( to check if lw or not)
        fwdAE, fwdBE,
        Stall_IF, Stall_ID,
        Flush_IF, Flush_ID, Flush_EX, Flush_MEM, Flush_WB
        );
endmodule
