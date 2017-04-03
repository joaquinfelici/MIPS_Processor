`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:08:03 01/06/2017 
// Design Name: 
// Module Name:    DE 
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
module DE
(
	input clk,
	input [31:0] DE_Instr, 
	input [31:0] DE_PCPlus4,
	input [4:0] DE_RegToWrite,
	input [31:0] DE_Result,
	input [31:0] DE_ALUOut,
	input [4:0] DE_DirReg_DB,
	
	input DE_C_RegWrite,
	input [1:0] DE_C_ForwardA_HZ,
	input [1:0] DE_C_ForwardB_HZ,
	input DE_C_FlushOutput_HZ,
	input DE_C_Stall_DB,
	input DE_C_Lector_DB,
	
	output reg [31:0] DE_AOperand = 32'b00000000000000000000000000000000,
	output reg [31:0] DE_BOperand = 32'b00000000000000000000000000000000,
	output reg [31:0] DE_ExtendedImmediate = 32'b00000000000000000000000000000000,
	output reg [4:0] DE_DestRegAlu = 5'b00000,
	output reg [4:0] DE_DestRegLoad = 5'b00000,
	output reg [31:0] DE_PCPlus4_O = 32'b00000000000000000000000000000000,
	output wire [25:0] DE_PCImmediate, // For J and JAL instructions (where address is within immediate)
	output wire [31:0] DE_PCBranch, // For BNE and BEQ instructions
	output wire [31:0] DE_PCJump, 
	output wire [4:0] DE_RegS_W,
	output reg [4:0] DE_RegS = 5'b00000,
	output wire [4:0] DE_RegT,
	output wire [31:0] DE_RegisterA,
	
	output reg DE_C_RegWrite_O = 1'b0,
	output reg DE_C_DataSource = 1'b0,
	output reg DE_C_MemWrite = 1'b0,
	output wire DE_C_PCSrc,	// Branch decision
	output wire [1:0] DE_C_Jump_W,
	output reg [1:0] DE_C_Jump = 2'b00,
	output reg DE_C_RegDest = 1'b0,
	output reg DE_C_AluSource = 1'b0,
	output reg [3:0] DE_C_ALUSel = 4'b0000,
	output reg DE_C_StoreLoad = 1'b0,
	output reg [1:0] DE_C_Extend = 2'b00,
	output reg DE_C_Halt = 1'b0,
	output wire DE_C_Halt_W,
	output wire DE_C_Branch_HZ
);

	reg [31:0] REGISTERS [0:31];
	wire [4:0] REG_A;
	wire [4:0] REG_B;
	wire [4:0] REG_A_DB;
	wire [31:0] AOperand;
	wire [31:0] BOperand;
	reg [31:0] RD1 = 32'b00000000000000000000000000000000;
	reg [31:0] RD2 = 32'b00000000000000000000000000000000;
	wire [4:0] DestRegAlu;
	wire [4:0] DestRegLoad;
	wire [4:0] RegisterS;
	wire [15:0] Immediate;
	wire [31:0] ExtendedImmediate;
	wire write;
	
	initial begin
	REGISTERS[2] = 32'b00000000000000000000000000000010;
	end
	
	/*
		Extract bits from instruction
	*/
	assign REG_A = {DE_Instr[25:21]};
	assign REG_A_DB = (DE_C_Lector_DB == 1'b1) ? DE_DirReg_DB : REG_A;
	assign REG_B = {DE_Instr[20:16]};
	assign RegisterS = {DE_Instr[25:21]};
	assign DestRegLoad = {DE_Instr[20:16]};
	assign DestRegAlu = {DE_Instr[15:11]};
	assign Immediate = {DE_Instr[15:0]};
	assign write = (DE_C_Lector_DB == 1'b1) ? 1'b0 : DE_C_RegWrite;
	
	/*
		Extend the inmediate value 16 bits
	*/
	assign ExtendedImmediate = {((Immediate[15] == 1'b1) ? 16'b1111111111111111 : 16'b0000000000000000), Immediate};
	
	/*
		Read and write registers
	*/
	always @(posedge clk)
	begin
		if (write)
		begin
			REGISTERS[DE_RegToWrite] <= DE_Result;
		end
	end
	
	always @(negedge clk)
	begin
		RD1 <= REGISTERS[REG_A_DB];
		RD2 <= REGISTERS[REG_B];
	end

	/*
		Wires that contain the output values (not set yet)
	*/
	assign AOperand = RD1;
	assign BOperand = RD2;
	
	/*
		Multiplexors for hazard
	*/
	wire [31:0] OpA;
	wire [31:0] OpB;
	
	//assign OpA = (DE_C_ForwardA_HZ == 1'b1) ? DE_ALUOut : AOperand;
	//assign OpB = (DE_C_ForwardB_HZ == 1'b1) ? DE_ALUOut : BOperand;
	
	assign OpA = (DE_C_ForwardA_HZ == 2'b00) ? AOperand : ((DE_C_ForwardA_HZ == 2'b01) ? DE_Result : DE_ALUOut);
	assign OpB = (DE_C_ForwardB_HZ == 2'b00) ? BOperand : ((DE_C_ForwardB_HZ == 2'b01) ? DE_Result : DE_ALUOut);
	
	/*
		Predict next branch address
	*/
	reg [31:0] CalculatedBranch;
	reg Z = 1'b0;
	wire Zero;
	wire BNE;
	wire BEQ;
	
	always @*
	begin
		CalculatedBranch = DE_PCPlus4 + ExtendedImmediate; //<< 2
		Z = (OpA == OpB);
	end
	
	/*
		Assign wire outputs that go into IF 
	*/
	assign DE_PCBranch = CalculatedBranch;	
	assign DE_PCJump = OpA;
	assign DE_PCImmediate = {DE_Instr[25:0]}; 
	
	/*
		Outputs setting
	*/
	
	assign DE_RegS_W = RegisterS;
	assign DE_RegT = DestRegLoad;
	
	assign DE_RegisterA = RD1;
	
	always @(posedge clk)
	begin
		if(DE_C_Stall_DB == 1'b0)
		begin
			DE_AOperand <= OpA;
			DE_BOperand <= OpB;
			DE_ExtendedImmediate <= ExtendedImmediate;
			DE_DestRegAlu <= DestRegAlu;
			DE_DestRegLoad <= DestRegLoad;
			DE_PCPlus4_O <= DE_PCPlus4;
			DE_RegS <= RegisterS;
		end
	end
	
	
	///////////////////////////////////////////////////////
	
	/* 
		Control unit
	*/
	
	wire [5:0] Op;
	wire [5:0] Funct;
	
	assign Op = {DE_Instr[31:26]};
	assign Funct =  {DE_Instr[5:0]};
	
	reg RegWrite = 1'b0;
	reg DataSource = 1'b0;
	reg MemWrite = 1'b0;
	reg BranchEq = 1'b0;
	reg BranchNe = 1'b0;
	reg [1:0] Jump = 2'b00;
	reg RegDest = 1'b0;
	reg AluSource = 1'b0;
	reg [3:0] ALUSel = 4'b0000;
	reg StoreLoad = 1'b0;
	reg [1:0] Extend = 2'b00;
	reg Halt = 1'b0;
	
	wire C_RegWrite_O;
	wire C_DataSource;
	wire C_MemWrite;
	wire C_BranchEq;
	wire C_BranchNe;
	wire [1:0] C_Jump;
	wire C_RegDest;
	wire C_AluSource;
	wire [3:0] C_ALUSel;
	wire C_StoreLoad;
	wire [1:0] C_Extend;
	wire C_Halt;
	
	assign C_RegWrite_O = RegWrite;
	assign C_DataSource = DataSource;
	assign C_MemWrite = MemWrite;
	assign C_BranchEq = BranchEq;
	assign C_BranchNe = BranchNe;
	assign C_Jump = Jump;
	assign C_RegDest = RegDest;
	assign C_AluSource = AluSource;
	assign C_ALUSel =  ALUSel;
	assign C_StoreLoad = StoreLoad;
	assign C_Extend = Extend;
	assign C_Halt = Halt;
	
	/*
		Implementation
	*/
	always @*
	begin
		case (Op)
			6'b000000:	// Tipo R
			begin
				RegDest = 1'b1;
				AluSource = 1'b0;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				DataSource = 1'b0;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
				case (Funct)
					6'b000000:	// SLL
					begin
						ALUSel = 4'b0000;	// 0
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b000010:	// SRL
					begin
						ALUSel = 4'b0001;	// 1
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b000011:	// SRA
					begin
						ALUSel = 4'b0010;	// 2
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b000100:	// SLLV
					begin
						ALUSel = 4'b0011;	// 3
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b000110:	// SRLV
					begin
						ALUSel = 4'b0100;	// 4
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b000111:	// SRAV
					begin
						ALUSel = 4'b0101;	// 5
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b100001:	// ADDU
					begin
						ALUSel = 4'b0110;	// 6
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b100011:	// SUBU
					begin
						ALUSel = 4'b0111;	// 7
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b100100:	// AND
					begin
						ALUSel = 4'b1000;	// 8
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b100101:	// OR
					begin
						ALUSel = 4'b1001;	// 9
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b100110:	// XOR
					begin
						ALUSel = 4'b1010;	// 10
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b100111:	// NOR
					begin
						ALUSel = 4'b1011;	// 11
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b101010:	// SLT
					begin
						ALUSel = 4'b1100;	// 12
						Jump = 2'b00;
						RegWrite = 1'b1;
					end
					6'b001000:	// JR
					begin
						ALUSel = 4'b1111;	// x
						Jump = 2'b10;
						RegWrite = 1'b0;
					end
					6'b001001:	// JALR
					begin
						ALUSel = 4'b1110;
						Jump = 2'b10;
						RegWrite = 1'b1;
					end
					default:
					begin
						ALUSel = 4'b1111;	// x
						Jump = 2'b00;     // x
						RegWrite = 1'b0;  // x
					end
				endcase
			end
			6'b100000:	// LB
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b1;
				StoreLoad = 1'b1;
				Extend = 2'b10;
				Halt = 1'b0;
			end
			6'b100001:	// LH
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b1;
				StoreLoad = 1'b1;
				Extend = 2'b11;
				Halt = 1'b0;
			end
			6'b100011:	// LW
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b1;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b100100:	// LBU
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b1;
				StoreLoad = 1'b1;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b100101:	// LHU
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b1;
				StoreLoad = 1'b1;
				Extend = 2'b01;
				Halt = 1'b0;
			end
			6'b100111:	// LWU
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b1;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b101000:	// SB
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;	// x
				AluSource = 1'b1;
				MemWrite = 1'b1;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b0;
				DataSource = 1'b0; //x
				StoreLoad = 1'b1;
				Extend = 2'b10;
				Halt = 1'b0;
			end
			6'b101001:	// SH
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;	// x
				AluSource = 1'b1;
				MemWrite = 1'b1;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b0;
				DataSource = 1'b0; //x
				StoreLoad = 1'b1;
				Extend = 2'b11;
				Halt = 1'b0;
			end
			6'b101011:	// SW
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;	// x
				AluSource = 1'b1;
				MemWrite = 1'b1;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b0;
				DataSource = 1'b0; //x
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b001000:	// ADDI
			begin
				ALUSel = 4'b0110;	// 6
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b0;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b001100:	// ANDI
			begin
				ALUSel = 4'b1000;	// 8
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b0;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b001101:	// ORI
			begin
				ALUSel = 4'b1001;	// 9
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b0;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b001110:	// XORI
			begin
				ALUSel = 4'b1010;	// 10
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b0;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b001111:	// LUI
			begin
				ALUSel = 4'b1101;	// 0
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b0;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b001010:	// SLTI
			begin
				ALUSel = 4'b1100;	// 12
				RegDest = 1'b0;
				AluSource = 1'b1;
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b1;
				DataSource = 1'b0;
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b000100:	// BEQ
			begin
				ALUSel = 4'b1111;	// xxxx
				RegDest = 1'b0;	// x
				AluSource = 1'b0;	// x
				MemWrite = 1'b0;	
				BranchEq = 1'b1;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b0;
				DataSource = 1'b0;// x
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b000101:	// BNE
			begin
				ALUSel = 4'b1111;	// xxxx
				RegDest = 1'b0;	// x
				AluSource = 1'b0;	// x
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b1;
				Jump = 2'b00;
				RegWrite = 1'b0;
				DataSource = 1'b0;// x
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b000010:	// J
			begin
				ALUSel = 4'b1111;	// xxxx
				RegDest = 1'b0;	// x
				AluSource = 1'b0;	// x
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b01;
				RegWrite = 1'b0;
				DataSource = 1'b0;// x
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b000011:	// JAL
			begin
				ALUSel = 4'b1110;	
				RegDest = 1'b0;	// x
				AluSource = 1'b0;	// x
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b01;
				RegWrite = 1'b1;
				DataSource = 1'b0;// x
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b0;
			end
			6'b111111:	// HALT
			begin
				ALUSel = 4'b1111;	
				RegDest = 1'b0;	// x
				AluSource = 1'b0;	// x
				MemWrite = 1'b0;
				BranchEq = 1'b0;
				BranchNe = 1'b0;
				Jump = 2'b00;
				RegWrite = 1'b0;
				DataSource = 1'b0;// x
				StoreLoad = 1'b0;
				Extend = 2'b00;
				Halt = 1'b1;
			end
			default:
			begin
				ALUSel = 4'b1111;	// xxxx
				RegDest = 1'b0;	// x
				AluSource = 1'b0;	// x
				MemWrite = 1'b0;  // x
				BranchEq = 1'b0;  // x
				BranchNe = 1'b0;  // x
				Jump = 2'b00;     // x
				RegWrite = 1'b0;  // x
				DataSource = 1'b0;// x
				StoreLoad = 1'b0; // x
				Extend = 2'b00;   // x
				Halt = 1'b1;      // x
			end
		endcase
	end
	
	/*
		Branch decision
	*/
	assign Zero = Z;
	assign BEQ = C_BranchEq & Zero;
	assign BNE = C_BranchNe & ~Zero;
	assign DE_C_PCSrc = BEQ | BNE;	// Wire output
	assign DE_C_Jump_W = C_Jump; // Wire output
	
	/*
		Control unit outputs setting
	*/
	
	assign DE_C_Branch_HZ = ((C_BranchEq == 1'b1) | (C_BranchNe == 1'b1) | (C_Jump == 2'b10)) ? 1'b1 : 1'b0; //(C_Jump == 2'b10) | 
	
	assign DE_C_Halt_W = C_Halt;
	
	always @(posedge clk)
	begin
		if(DE_C_Stall_DB == 1'b0)
		begin
			if(DE_C_FlushOutput_HZ)
			begin
				DE_C_RegWrite_O <= 1'b0;
				DE_C_DataSource <= 1'b0;
				DE_C_MemWrite <= 1'b0;
				DE_C_Jump <= 2'b00;
				DE_C_RegDest <= 1'b0;
				DE_C_AluSource <= 1'b0;
				DE_C_ALUSel <= 4'b0000;
				DE_C_StoreLoad <= 1'b0;
				DE_C_Extend <= 2'b00;
				DE_C_Halt <= 1'b0;
			end
			else
			begin
				DE_C_RegWrite_O <= C_RegWrite_O;
				DE_C_DataSource <= C_DataSource;
				DE_C_MemWrite <= C_MemWrite;
				DE_C_Jump <= C_Jump;
				DE_C_RegDest <= C_RegDest;
				DE_C_AluSource <= C_AluSource;
				DE_C_ALUSel <= C_ALUSel;
				DE_C_StoreLoad <= C_StoreLoad;
				DE_C_Extend <= C_Extend;
				DE_C_Halt <= C_Halt;
			end
		end
	end
	
endmodule
