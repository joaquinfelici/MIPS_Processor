`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:43:55 01/07/2017 
// Design Name: 
// Module Name:    WB 
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
module WB
(
	input [31:0] WB_ALUOut,
	input [31:0] WB_ReadData,
	input [4:0] WB_RegToWrite,
	input [31:0] WB_PCPlus4,
	
	input WB_C_RegWrite,
	input WB_C_DataSource,
	input [1:0] WB_C_Jump,
	input WB_C_StoreLoad,
	input [1:0] WB_C_Extend,
	input WB_C_Halt,
	
	output wire [31:0] WB_Result,
	output wire [4:0] WB_RegToWrite_O,
	
	output wire WB_C_RegWrite_O,
	output wire WB_C_Halt_O
);

	wire [31:0] Result;
	wire Jump_A;
	wire Jump_B;
	wire [31:0] TrimData;
	wire [31:0] ReadData;
	
	assign TrimData = (WB_C_Extend == 2'b00) ? 
															{24'b000000000000000000000000, {WB_ReadData[7:0]}} : 
						  ((WB_C_Extend == 2'b01) ? 
															{16'b0000000000000000, {WB_ReadData[15:0]}} : 
						  ((WB_C_Extend == 2'b10) ? 
															{((WB_ReadData[7] == 1'b1) ? 24'b111111111111111111111111 : 24'b000000000000000000000000), {WB_ReadData[7:0]}} : 
															{((WB_ReadData[15] == 1'b1) ? 16'b1111111111111111 : 16'b0000000000000000), {WB_ReadData[15:0]}}));
	
	assign ReadData = (WB_C_StoreLoad == 1'b0) ? WB_ReadData : TrimData;
	
	assign Result = (WB_C_DataSource) ? ReadData : WB_ALUOut;
	assign Jump_A = {WB_C_Jump[1]};
	assign Jump_B = {WB_C_Jump[0]};
	
	/* 
		Wire output assign (no clk needed)
	*/
	assign WB_Result = (Jump_A | Jump_B) ? WB_PCPlus4 : Result;
	assign WB_RegToWrite_O = WB_RegToWrite;
	
	///////////////////////////////////////////////////////
	
	/* 
		Control unit
	*/
	
	assign WB_C_RegWrite_O = WB_C_RegWrite;
	assign WB_C_Halt_O = WB_C_Halt;

endmodule
