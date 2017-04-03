`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:06:34 01/06/2017 
// Design Name: 
// Module Name:    IF 
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
module IF
(
	input clk,
	input [31:0] IF_PCBranch,		// For BEQ and BNE instructions
	input [31:0] IF_PCJump,			// For J and JAL instructions (address saved in register)
	input [25:0] IF_PCImmediate,	// For JR and JALR instructions (address in immediate)
	
	input IF_C_PCSrc,		// For selecting between Plus4 and PCBranch
	input [1:0] IF_C_Jump,		// For selecting between the signal above and the other two
	input IF_C_Halt,
	input IF_C_StallPC_HZ,
	input IF_C_StallOutput_HZ,
	input IF_C_Stall_DB,
	
	output reg [31:0] IF_Instr = 32'b00000000000000000000000000000000, 
	output reg [31:0] IF_PCPlus4 = 32'b00000000000000000000000000000000,
	output wire [31:0] IF_PC
);

	reg [31:0] PC = 32'b00000000000000000000000000000000;	// Actual clock
	wire [31:0] wire_PC;
	reg [31:0] PCPlus4 = 32'b00000000000000000000000000000000;	// Output of the adder
	wire [31:0] PCFromImmediate;	// PC shifted from the PCImmediate input
	wire [31:0] PCAfterMux1;	// Output of the first multiplex
	wire [31:0] PCAfterMux2;	// Output of the second multiplex
	reg [31:0] PROGRAM_MEMORY [0:4095];	// Memory declaration
	
	initial begin
	$readmemb("instructions.bin",PROGRAM_MEMORY);
	end
	
	/*
		PC immediate needs to be extended
	*/
	assign PCFromImmediate = {6'b000000, IF_PCImmediate};
	
	/*
		Multiplex for choosing the next PC (see inputs for more information)
	*/
	assign PCAfterMux1 = (IF_C_PCSrc) ? IF_PCBranch : PCPlus4;
	assign PCAfterMux2 = (IF_C_Jump == 2'b00) ? PCAfterMux1 : ((IF_C_Jump == 2'b01) ? PCFromImmediate : IF_PCJump);
	
	/*
		Adder
	*/
	always @*
	begin
		PCPlus4 = PC + 1'b1;
	end
	
	/*
		Sequencial for updating the PC when clock rising edge happens
	*/
	assign wire_PC = (IF_C_Stall_DB == 1'b1) ? 32'b00000000000000000000000000000000 : PC;
	
	always @(posedge clk)
	begin
		if(IF_C_Stall_DB == 1'b0)
		begin
			if(IF_C_StallPC_HZ == 1'b0 && IF_C_Halt == 1'b0)
			begin
				PC <= PCAfterMux2;
			end
		end
	end
	
	/*
		Outputs setting
	*/	
	assign IF_PC = PC;
	
	always @(posedge clk)
	begin
		if(IF_C_Stall_DB == 1'b0 && IF_C_StallOutput_HZ == 1'b0)
		begin
			if(IF_C_PCSrc | (IF_C_Jump[1] | IF_C_Jump[0]))
			begin
				IF_Instr <= 32'b00000000000000000000000000000000;
			end
			else if(IF_C_Halt)
			begin
				IF_Instr <= 32'b11111100000000000000000000000000;
			end
			else
			begin
				IF_Instr <= PROGRAM_MEMORY[wire_PC];
			end
			IF_PCPlus4 <= PCPlus4;
		end
	end

endmodule
