`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 18:04:12
// Design Name: ALU for RV32I ISA
// Module Name: ALU
// Project Name: RV32I 5-stage pipelined processor
// Target Devices: 
// Tool Versions: 
// Description: ALU for supporting RV32I ISA instructions.   
//              Performs +/-/shift/logical operations.
// Dependencies: 32-bit adder/subtractor module, 32-bit Barallel shifter,
//               32-bit logical operations module 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU(
    input [31:0] srcA, srcB,            //Two 32-bit inputs to the ALU
    input sel_a, sel_comp,              //add/sub & slt/sltu operation select
    input [1:0] sel_s, sel_l,           //shift type and logical operation select
    input [1:0] sel_alu_out,            //selecting ALU output (Mux sel)
    output z, c, n,                     //Zero, carry, negative flags
    output reg [31:0] alu_out           //ALU final output, selects one of the 3 units' outputs
    );
    
    wire [31:0] res_a, res_s, res_l;    //result of arith, shift and logical operations 
    reg [31:0]  res_comp;               //res_comp is the result of SLT/SLTU operation
    
    adder_subtractor_32bit add_sub (srcA, srcB, sel_a, res_a, c);
    shifter shi1 (srcA, srcB, sel_s, res_s);    //operand, shamt, type, o/p
    logical logic1 (srcA, srcB, sel_l, res_l);
    
    assign z = !(|res_a);
    assign n = res_a[31];              //MSB of add/sub result; can't tell b/w signed or unsigned operands
    
    always @ (*)
        begin
            case(sel_comp)
                1'b0: res_comp = {{31{1 'b0}}, {c}};   //SLTU
                1'b1: res_comp = {{31{1 'b0}}, {(srcA[31] != srcB[31]) ? srcA[31] : c}};    //SLT
                default: res_comp = {{31{1 'b0}}, {c}};   //SLTU
            endcase
        end
    
    always @ (*)                        //final output selection mux
        begin
            case(sel_alu_out)
                2'b00: alu_out = res_a;
                2'b01: alu_out = res_comp;
                2'b10: alu_out = res_l;
                2'b11: alu_out = res_s;
                default: alu_out = res_a;
            endcase
        end
endmodule

//logical operations module
module logical(
    input [31 : 0] a, b,
    input [1:0] type,
    output reg [31:0] result
    );
    always @ (*)
        begin
            case (type)     // data logic function unit operation
                2 'b00: result = a ^ b;     //XOR function
                2 'b01: result = a | b;     //OR function
                2 'b10: result = a & b;     //AND function
                default: result = a ^ b;    //XOR function is default
            endcase
        end
 endmodule
 
//Barrel shifter, taken from a previous project
module shifter (a, b, c, z);
    input [31 : 0] a;		//32-bit operand
    input [4 : 0] b;		//5-bit shift amount
    input [1 : 0] c;		//shift type
    output reg [31 : 0] z;  //final shifted output register
    
    reg [31 : 0]  z4, z3, z2, z1;	//intermediate results of cascaded shift stages 
    reg [1 : 0] sel4, sel3, sel2, sel1, sel0;	//mux controls for the 5-stages of muxes
    
always @ (*)
// setting up control signals (sel4, sel3, sel2, sel1, sel0) for the five stages of 4:1 muxes 
//based on the shift type and the shift amount to be performed by each stage
    begin
        casex ({c, b[4]})               //MSB set; 16-bit shift to be done
            3 'bxx0 : sel4 = 2 'b11;
            3 'b0x1 : sel4 = 2 'b10;
            3 'b111 : sel4 = 2 'b01;
            3 'b101 : sel4 = 2 'b00;
            default: sel4 = 2'd0;
        endcase 
        
        casex ({c, b[3]})               //set; 8-bit shift to be done
            3 'bxx0 : sel3 = 2 'b11;
            3 'b0x1 : sel3 = 2 'b10;
            3 'b111 : sel3 = 2 'b01;
            3 'b101 : sel3 = 2 'b00;
            default: sel3 = 2'd0;
        endcase
        
        casex ({c, b[2]})               //set; 4-bit shift to be done
            3 'bxx0 : sel2 = 2 'b11;
            3 'b0x1 : sel2 = 2 'b10;
            3 'b111 : sel2 = 2 'b01;
            3 'b101 : sel2 = 2 'b00;
            default: sel2 = 2'd0;
        endcase
        
        casex ({c, b[1]})               //set; 2-bit shift to be done
            3 'bxx0 : sel1 = 2 'b11;
            3 'b0x1 : sel1 = 2 'b10;
            3 'b111 : sel1 = 2 'b01;
            3 'b101 : sel1 = 2 'b00;
            default: sel1 = 2'd0;
        endcase
        
        casex ({c, b[0]})               //set; 1-bit shift to be done
            3 'bxx0 : sel0 = 2 'b11;        //no shift if bit is not active
            3 'b0x1 : sel0 = 2 'b10;        //left shift
            3 'b111 : sel0 = 2 'b01;        //asr
            3 'b101 : sel0 = 2 'b00;        //right shift
            default: sel0 = 2'd0;
        endcase
        
//SHIFTING        
//shift stage 4: performs 16/0-bit shift of the specified type on the input a
         case (sel4)
            2 'b11 : z4 = a;                        //no shift
            2 'b10 : z4 = {a[15 : 0], {16{1 'b0}}}; //Left shift
            2 'b01 : z4 = {{16{a[31]}}, a[31 : 16]};//arithmetic right shift
            2 'b00 : z4 = {{16{1 'b0}}, a[31 : 16]};//logical right shift
        endcase
//shift stage 3: performs 8/0-bit shift of the specified type on its input z4
        case (sel3)
            2 'b11 : z3 = z4;                       //no shift
            2 'b10 : z3 = {z4[23 : 0], {8{1 'b0}}}; //Left shift
            2 'b01 : z3 = {{8{z4[31]}}, z4[31 : 8]};//arithmetic right shift
            2 'b00 : z3 = {{8{1 'b0}}, z4[31 : 8]}; //logical right shift
        endcase
//shift stage 3: performs 4/0-bit shift of the specified type on its input z3
        case (sel2)
            2 'b11 : z2 = z3; //no shift
            2 'b10 : z2 = {z3[27 : 0], {4{1 'b0}}};//Left
            2 'b01 : z2 = {{4{z3[31]}}, z3[31 : 4]};//arithmethic right shift
            2 'b00 : z2 = {{4{1 'b0}}, z3[31 : 4]};
        endcase
//shift stage 3: performs 2/0-bit shift of the specified type on its input z2        
        case (sel1)
            2 'b11 : z1 = z2; //no shift
            2 'b10 : z1 = {z2[29 : 0], {2{1 'b0}}}; //Left
            2 'b01 : z1 = {{2{z2[31]}}, z2[31 : 2]};//arithmethic right shift
            2 'b00 : z1 = {{2{1 'b0}}, z2[31 : 2]}; //logical right shift
        endcase
//shift stage 3: performs 1/0-bit shift of the specified type on its input z1    
        case (sel0)
            2 'b11 : z = z1;                        //no shift
            2 'b10 : z = {z1[30 : 0], 1 'b0};       //left shift
            2 'b01 : z = {{z1[31]}, z1[31 : 1]};    //arithmethic right shift
            2 'b00 : z = {1 'b0, z1[31 : 1]};       //logical right shift
        endcase
end             //always block end
endmodule


//Add/sub module
module adder_subtractor_32bit(
    input [31:0] a,
    input [31:0] b,
    input sub,          // Control: 0 = addition, 1 = subtraction
    output [31:0] result,
    output cout
    //output overflow
    );
    wire [31:0] b_modified;
    wire [32:0] carry;
    
    // XOR gates for 2's complement conversion
    assign b_modified = b ^ {32{sub}};
    assign carry[0] = sub;  // Carry-in for 2's complement
    
    // Generate 32 full adders
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : adder_stage
            full_adder fa(
                .a(a[i]),
                .b(b_modified[i]),
                .cin(carry[i]),
                .sum(result[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate
    
    assign cout = (sub ? (~carry[32]): carry[32]);
    
    // Overflow detection for signed arithmetic
    //assign overflow = carry[31] ^ carry[32];
    
endmodule

module full_adder(              //full adder module
    input a, b, cin,
    output sum, cout
    );
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule