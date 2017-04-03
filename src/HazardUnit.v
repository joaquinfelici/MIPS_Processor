`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:23:47 02/19/2017 
// Design Name: 
// Module Name:    HazardUnit 
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
module HazardUnit
(
    input [4:0] DE_Rs,
	 input [4:0] DE_Rt,
	 input [4:0] EX_Rs,
	 input [4:0] EX_Rt,
	 input [4:0] EX_RDest,
	 input [4:0] ME_RDest,
	 input [4:0] WB_RDest,
	 
	 input DE_C_Branch,
	 input EX_C_Load,
	 input EX_C_WriteReg,
	 input ME_C_Load,
	 input ME_C_WriteReg,
	 input WB_C_WriteReg,
	 
	 output wire IF_C_StallPC,
	 output wire IF_C_StallOutput,
	 output wire [1:0] DE_C_ForwardA,
	 output wire [1:0] DE_C_ForwardB,
	 output wire DE_C_FlushOutput,
	 output wire [1:0] EX_C_ForwardA,
	 output wire [1:0] EX_C_ForwardB
);
	/*
		Wires to calculate when to stall and flush inputs (for load and branch hazard)
	*/
	wire LWStall;
	wire BranchStall;
	
	assign LWStall = ((EX_C_Load == 1'b1) & ((DE_Rs == EX_RDest) | (DE_Rt == EX_RDest))) ? 1'b1 : 1'b0;
	
	assign BranchStall = (((DE_C_Branch == 1'b1) & (EX_C_WriteReg == 1'b1) & ((DE_Rs == EX_RDest) | (DE_Rt == EX_RDest))) | 
								 ((DE_C_Branch == 1'b1) & (ME_C_Load == 1'b1) & ((DE_Rs == ME_RDest) | (DE_Rt == ME_RDest)))) ? 1'b1 : 1'b0;
	
	/*
		Signal to stall PC (for load and branch hazard)
	*/
	assign IF_C_StallPC = (LWStall | BranchStall) ? 1'b1 : 1'b0;
	
	/*
		Signal to stall IF input (for load and branch hazard)
	*/
	assign IF_C_StallOutput = (LWStall | BranchStall) ? 1'b1 : 1'b0;
   
	/*
		Signals to forward inputs (for branch hazard)	*/
	//assign DE_C_ForwardA = ((ME_C_WriteReg == 1'b1) & (DE_Rs == ME_RDest)) ? 1'b1 : 1'b0;
	//assign DE_C_ForwardB = ((ME_C_WriteReg == 1'b1) & (DE_Rt == ME_RDest)) ? 1'b1 : 1'b0;
	
	assign DE_C_ForwardA = ((ME_C_WriteReg == 1'b1) & (DE_Rs == ME_RDest)) ? 2'b10 : 
								  (((WB_C_WriteReg == 1'b1) & (DE_Rs == WB_RDest)) ? 2'b01 : 2'b00);
	assign DE_C_ForwardB = ((ME_C_WriteReg == 1'b1) & (DE_Rt == ME_RDest)) ? 2'b10 : 
								  (((WB_C_WriteReg == 1'b1) & (DE_Rt == WB_RDest)) ? 2'b01 : 2'b00);
	
	/*
		Signal to flush DE input (for load and branch hazard)
	*/
	assign DE_C_FlushOutput = (LWStall | BranchStall) ? 1'b1 : 1'b0;
	
	/*
		Signals to forward inputs (for R-type and load hazard)	*/
	assign EX_C_ForwardA = ((ME_C_WriteReg == 1'b1) & (EX_Rs == ME_RDest)) ? 2'b10 : 
								  (((WB_C_WriteReg == 1'b1) & (EX_Rs == WB_RDest)) ? 2'b01 : 2'b00);
	assign EX_C_ForwardB = ((ME_C_WriteReg == 1'b1) & (EX_Rt == ME_RDest)) ? 2'b10 : 
								  (((WB_C_WriteReg == 1'b1) & (EX_Rt == WB_RDest)) ? 2'b01 : 2'b00);

endmodule
