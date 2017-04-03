`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:50:22 01/07/2017 
// Design Name: 
// Module Name:    ME 
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
module ME
(
	input clk,
	input [31:0] ME_ALUOut,
	input [31:0] ME_DataToWrite,
	input [4:0] ME_RegToWrite,
	input [31:0] ME_PCPlus4,
	input [31:0] ME_DirMem_DB,
	
	input ME_C_RegWrite,
	input ME_C_DataSource,
	input ME_C_MemWrite,
	input [1:0] ME_C_Jump,
	input ME_C_StoreLoad,
	input [1:0] ME_C_Extend,
	input ME_C_Halt,
	input ME_C_Stall_DB,
	input ME_C_Lector_DB,
	
	output reg [31:0] ME_ALUOut_O = 32'b00000000000000000000000000000000,
	output reg [31:0] ME_ReadData = 32'b00000000000000000000000000000000,
	output reg [4:0] ME_RegToWrite_O = 5'b00000,
	output reg [31:0] ME_PCPlus4_O = 32'b00000000000000000000000000000000,
	output wire [31:0] ME_ALUOut_O_W,
	output wire [4:0] ME_RegDest,
	output wire [31:0] ME_MemoryData,
	
	output reg ME_C_RegWrite_O = 1'b0,
	output reg ME_C_DataSource_O = 1'b0,
	output reg [1:0] ME_C_Jump_O = 2'b00,
	output reg ME_C_StoreLoad_O = 1'b0,
	output reg [1:0] ME_C_Extend_O = 2'b00,
	output reg ME_C_Halt_O = 1'b0,
	output wire ME_C_Load_HZ,
	output wire ME_C_WriteReg_HZ
);

	reg [31:0] DATA_MEMORY [0:63];
	wire [31:0] PosData_DB;
	reg [31:0] Data = 32'b00000000000000000000000000000000;
	wire [31:0] ReadData;
	wire [31:0] TrimData;
	wire [31:0] WriteData;
	wire write;
	
	initial begin
	DATA_MEMORY[4] = 32'b00000000000000000000000000001100;
	end
	
	assign PosData_DB = (ME_C_Lector_DB == 1'b1) ? ME_DirMem_DB : ME_ALUOut;
	assign write = (ME_C_Lector_DB == 1'b1) ? 1'b0 : ME_C_MemWrite;
	
	assign ReadData = Data;
	
	assign TrimData = (ME_C_Extend == 2'b00) ? 
															{24'b000000000000000000000000, {ME_DataToWrite[7:0]}} : 
						  ((ME_C_Extend == 2'b01) ? 
															{16'b0000000000000000, {ME_DataToWrite[15:0]}} : 
						  ((ME_C_Extend == 2'b10) ? 
															{((ME_DataToWrite[7] == 1'b1) ? 24'b111111111111111111111111 : 24'b000000000000000000000000), {ME_DataToWrite[7:0]}} : 
															{((ME_DataToWrite[15] == 1'b1) ? 16'b1111111111111111 : 16'b0000000000000000), {ME_DataToWrite[15:0]}}));
															 														 
	assign WriteData = (ME_C_StoreLoad == 1'b0) ? ME_DataToWrite : TrimData;
	
	/*
		Write to memory if MemWrite is 1, read otherwise
	*/
	always @(negedge clk)
	begin
		if (write)
		begin
			DATA_MEMORY[ME_ALUOut] <= WriteData;
		end
		//else
		//begin
			Data <= DATA_MEMORY[PosData_DB];
		//end
	end
	

	/*
		Outputs setting
	*/
	
	assign ME_ALUOut_O_W = ME_ALUOut;
	assign ME_RegDest = ME_RegToWrite;
	
	assign ME_MemoryData = Data;
	
	always @(posedge clk)
	begin
		if(ME_C_Stall_DB == 1'b0)
		begin
			ME_ALUOut_O <= ME_ALUOut;
			ME_ReadData <= ReadData;
			ME_RegToWrite_O <= ME_RegToWrite;
			ME_PCPlus4_O <= ME_PCPlus4;
		end
	end
	
	///////////////////////////////////////////////////////
	
	/* 
		Control unit
	*/
	
	assign ME_C_Load_HZ = ME_C_DataSource;
	assign ME_C_WriteReg_HZ = ME_C_RegWrite;
	
	always @(posedge clk)
	begin
		if(ME_C_Stall_DB == 1'b0)
		begin
			ME_C_RegWrite_O <= ME_C_RegWrite;
			ME_C_DataSource_O <= ME_C_DataSource;
			ME_C_Jump_O <= ME_C_Jump;
			ME_C_StoreLoad_O <= ME_C_StoreLoad;
			ME_C_Extend_O <= ME_C_Extend;
			ME_C_Halt_O <= ME_C_Halt;
		end
	end
	
endmodule
