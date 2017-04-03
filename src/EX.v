`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:55:36 01/07/2017 
// Design Name: 
// Module Name:    EX 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module EX
(
	input clk,
	input [31:0] EX_AOperand,
	input [31:0] EX_BOperand,
	input [4:0] EX_DestRegAlu,
	input [4:0] EX_DestRegLoad,
	input [31:0] EX_ExtendedImmediate,
	input [31:0] EX_PCPlus4,
	input [31:0] EX_ALUOut_I,
	input [31:0] EX_Result,
	input [4:0] EX_RegS,
	
	input EX_C_RegWrite,
	input EX_C_DataSource,
	input EX_C_MemWrite,
	input [1:0] EX_C_Jump,
	input EX_C_RegDest,
	input EX_C_AluSource,
	input [3:0] EX_C_ALUSel,
	input EX_C_StoreLoad,
	input [1:0] EX_C_Extend,
	input EX_C_Halt,
	input [1:0] EX_C_ForwardA_HZ,
	input [1:0] EX_C_ForwardB_HZ,
	input EX_C_Stall_DB,
	
	output reg [31:0] EX_ALUOut = 32'b00000000000000000000000000000000,
	output reg [31:0] EX_DataToWrite = 32'b00000000000000000000000000000000,
	output reg [4:0] EX_RegToWrite = 5'b00000,
	output reg [31:0] EX_PCPlus4_O = 32'b00000000000000000000000000000000,
	output wire [4:0] EX_RegS_O,
	output wire [4:0] EX_RegT,
	output wire [4:0] EX_RegDest,
	
	output reg EX_C_RegWrite_O = 1'b0,
	output reg EX_C_DataSource_O = 1'b0,
	output reg EX_C_MemWrite_O = 1'b0,
	output reg [1:0] EX_C_Jump_O = 2'b00,
	output reg EX_C_StoreLoad_O = 1'b0,
	output reg [1:0] EX_C_Extend_O = 2'b00,
	output reg EX_C_Halt_O = 1'b0,
	output wire EX_C_Load_HZ,
	output wire EX_C_WriteReg_HZ
 );
 
   wire [31:0] BOperand;
	wire [4:0] RegToWrite;
	reg [31:0] ALURes = 32'b00000000000000000000000000000000;
	wire [31:0] ALUOut;
	
	/*
		Multiplexors for hazard
	*/
	wire [31:0] SrcA;
	wire [31:0] SrcB;
	
	assign SrcA = (EX_C_ForwardA_HZ == 2'b00) ? EX_AOperand : ((EX_C_ForwardA_HZ == 2'b01) ? EX_Result : EX_ALUOut_I);
	assign SrcB = (EX_C_ForwardB_HZ == 2'b00) ? EX_BOperand : ((EX_C_ForwardB_HZ == 2'b01) ? EX_Result : EX_ALUOut_I);
	
	/*
		Bits from the immediate to solve shift(such as SRL)
	*/
	wire [4:0] Shamt;
	
	assign ALUOut = ALURes;
	
	/*
		Choose source B between register or immediate
	*/
	assign BOperand = (EX_C_AluSource) ? EX_ExtendedImmediate : SrcB;
	
	/*
		Save the destination register (depending whether it's an R/I operation)
	*/
	//reg JALRegWrite = 5'b11111;	// Register 31
	assign RegToWrite = (EX_C_ALUSel == 4'b1110) ? 5'b11111 : ((EX_C_RegDest)  ? EX_DestRegAlu :  EX_DestRegLoad);

	/*
		Shift operand from immediate
	*/
	assign Shamt = {EX_ExtendedImmediate[10:6]};
	
	/*
		Compute ALU result
	*/
	always @*
	begin
		case(EX_C_ALUSel)
			4'b0000: ALURes = BOperand <<  Shamt;							// SLL
			4'b0001: ALURes = BOperand >>  Shamt;							// SRL
			4'b0010: ALURes = BOperand >>>  Shamt;							// SRA
			4'b0011: ALURes = BOperand <<  SrcA;							// SLLV			
			4'b0100: ALURes = BOperand >>  SrcA;							// SRLV			
			4'b0101: ALURes = BOperand >>>  SrcA;							// SRAV					
			4'b0110: ALURes = SrcA + BOperand;								// ADD						
			4'b0111: ALURes = SrcA - BOperand;								// SUB							
			4'b1000: ALURes = SrcA & BOperand;								// AND
			4'b1001: ALURes = SrcA | BOperand;								// OR
			4'b1010: ALURes = SrcA ^ BOperand;								// XOR
			4'b1011: ALURes = ~(SrcA | BOperand);							// NOR
			4'b1100: ALURes = SrcA < BOperand;	  							// SLT
			4'b1101: ALURes = BOperand << 16;								// LUI
			default: ALURes = 32'b00000000000000000000000000000000;	// DEFAULT
		endcase	
	end
	
	assign EX_RegS_O = EX_RegS;
	assign EX_RegT = EX_DestRegLoad;
	assign EX_RegDest = RegToWrite;
	
	always @(posedge clk)
	begin
		if(EX_C_Stall_DB == 1'b0)
		begin
			EX_ALUOut <= ALUOut;
			EX_DataToWrite <= SrcB;
			EX_RegToWrite <= RegToWrite;
			EX_PCPlus4_O <= EX_PCPlus4;
		end
	end
	
	///////////////////////////////////////////////////////
	
	/* 
		Control unit
	*/
	
	assign EX_C_Load_HZ = EX_C_DataSource;
	assign EX_C_WriteReg_HZ = EX_C_RegWrite;
	
	always @(posedge clk)
	begin
		if(EX_C_Stall_DB == 1'b0)
		begin
			EX_C_RegWrite_O <= EX_C_RegWrite;
			EX_C_DataSource_O <= EX_C_DataSource;
			EX_C_MemWrite_O <= EX_C_MemWrite;
			EX_C_Jump_O <= EX_C_Jump;
			EX_C_StoreLoad_O <= EX_C_StoreLoad;
			EX_C_Extend_O <= EX_C_Extend;
			EX_C_Halt_O <= EX_C_Halt;
		end
	end
	
endmodule
