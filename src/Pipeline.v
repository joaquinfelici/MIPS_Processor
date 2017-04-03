`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:49:10 02/08/2017 
// Design Name: 
// Module Name:    Pipeline 
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
module Pipeline
(
	input Clk,
	input serial_in,
	output serial_out
);
 
	wire [31:0] PCBranch_DE;	
	wire [31:0] PCJump_DE;
	wire [25:0] PCImmediate_DE;
	wire [31:0] Instr_IF;
	wire [31:0] PCPlus4_IF;
	wire [31:0] PC_IF;
	wire [4:0] RegToWrite_WB;
	wire [31:0] Result_WB;
	wire [31:0] AOperand_DE;
	wire [31:0] BOperand_DE;
	wire [31:0] ExtendedImmediate_DE;
	wire [4:0] DestRegAlu_DE;
	wire [4:0] DestRegLoad_DE;
	wire [31:0] PCPlus4_DE;
	wire [4:0] RegS_DE;
	wire [31:0] RegisterA_DE;
	wire [31:0] ALUOut_EX;
	wire [31:0] DataToWrite_EX;
	wire [4:0] RegToWrite_EX;
	wire [31:0] PCPlus4_EX;
	wire [31:0] ALUOut_ME;
	wire [31:0] ReadData_ME;
	wire [4:0] RegToWrite_ME;
	wire [31:0] PCPlus4_ME;
	wire [31:0] ALUOut_W_ME;
	wire [31:0] MemoryData_ME;

	wire C_PCSrc_DE;	
	wire [1:0] C_Jump_W_DE;
	wire C_RegWrite_WB;
	wire C_RegWrite_DE;
	wire C_DataSource_DE;
	wire C_MemWrite_DE;
	wire C_RegDest_DE;
	wire [1:0] C_Jump_DE;
	wire C_AluSource_DE;
	wire [3:0] C_ALUSel_DE;
	wire C_StoreLoad_DE;
	wire [1:0] C_Extend_DE;
	wire C_RegWrite_EX;
	wire C_DataSource_EX;
	wire C_MemWrite_EX;
	wire [1:0] C_Jump_EX;
	wire C_StoreLoad_EX;
	wire [1:0] C_Extend_EX;
	wire C_RegWrite_ME;
	wire C_DataSource_ME;
	wire [1:0] C_Jump_ME;
	wire C_StoreLoad_ME;
	wire [1:0] C_Extend_ME;
	wire C_Halt_DE_W;
	wire C_Halt_DE;
	wire C_Halt_EX;
	wire C_Halt_ME;
	wire C_Halt_WB;
	  
	  
	wire [4:0] HZ_Rs_DE;
	wire [4:0] HZ_Rt_DE;
	wire [4:0] HZ_Rs_EX;
	wire [4:0] HZ_Rt_EX;
	wire [4:0] HZ_RDest_EX;
	wire [4:0] HZ_RDest_ME;
	
	wire HZ_C_Branch_DE;
	wire HZ_C_Load_EX;
	wire HZ_C_WriteReg_EX;
	wire HZ_C_Load_ME;
	wire HZ_C_WriteReg_ME;
	
	wire HZ_C_StallPC_IF;
	wire HZ_C_StallOutput_IF;
	wire [1:0] HZ_C_ForwardA_DE;
	wire [1:0] HZ_C_ForwardB_DE;
	wire HZ_C_FlushOutput_DE;
	wire [1:0] HZ_C_ForwardA_EX;
	wire [1:0] HZ_C_ForwardB_EX;
	  
	wire DB_Stall;
	wire DB_Lector;
	wire [4:0] DB_DirReg;
	wire [31:0] DB_DirMem;
	wire DB_DataStart;
	wire DB_DataReady;
	wire [31:0] DB_Data;
	
	wire [31:0] DB_Latches [0:15];
	assign DB_Latches[0] = Instr_IF;             										//Instruction IF
	assign DB_Latches[1] = PCPlus4_IF;			   										//PCPlus4 IF
	assign DB_Latches[2] = AOperand_DE;														//Operand A DE
	assign DB_Latches[3] = BOperand_DE;														//Operand B DE
	assign DB_Latches[4] = ExtendedImmediate_DE; 										//Immediate DE
	assign DB_Latches[5] = {27'b000000000000000000000000000,{DestRegAlu_DE}};	//RegWriteAlu DE
	assign DB_Latches[6] = {27'b000000000000000000000000000,{DestRegLoad_DE}};	//RegWriteMem DE 
	assign DB_Latches[7] = PCPlus4_DE;														//PCPlus4 DE
	assign DB_Latches[8] = ALUOut_EX;														//ALUResult EX
	assign DB_Latches[9] = DataToWrite_EX;													//DataStore EX
	assign DB_Latches[10] = {27'b000000000000000000000000000,{RegToWrite_EX}};	//RegWrite EX 
	assign DB_Latches[11] = PCPlus4_EX;														//PCPlus4 EX
	assign DB_Latches[12] = ALUOut_ME;														//ALUResult ME
	assign DB_Latches[13] = ReadData_ME;													//DataLoad ME
	assign DB_Latches[14] = {27'b000000000000000000000000000,{RegToWrite_ME}};	//RegWrite ME 
	assign DB_Latches[15] = PCPlus4_ME;														//PCPlus4 ME
	
	wire [31:0] DB_Latch;
	wire [3:0] DB_DirLatch;
	assign DB_Latch = DB_Latches[DB_DirLatch];
	
	  
	wire t; 					//tick
	wire[7:0] res_rx; 	//salida del rx
	wire d; 					//señal de rx finalizado
	wire[7:0] res_tx; 	//dato para tx
	wire j; 					//cuando empezar a transmitir
	wire k; 					//señal de tx finalizado

	
	IF instruction_fetch
	(
		.clk(Clk),
		.IF_PCBranch(PCBranch_DE),
		.IF_PCJump(PCJump_DE), 
		.IF_PCImmediate(PCImmediate_DE),
		.IF_C_PCSrc(C_PCSrc_DE),
		.IF_C_Jump(C_Jump_W_DE),
		.IF_C_Halt(C_Halt_DE_W),
		.IF_C_StallPC_HZ(HZ_C_StallPC_IF),
		.IF_C_StallOutput_HZ(HZ_C_StallOutput_IF),
		.IF_C_Stall_DB(DB_Stall),
		.IF_Instr(Instr_IF),
		.IF_PCPlus4(PCPlus4_IF),
		.IF_PC(PC_IF)
	);
	
	DE decoder
	(
		.clk(Clk),
		.DE_Instr(Instr_IF),
		.DE_PCPlus4(PCPlus4_IF),
		.DE_RegToWrite(RegToWrite_WB),
		.DE_Result(Result_WB),
		.DE_ALUOut(ALUOut_W_ME),
		.DE_DirReg_DB(DB_DirReg),
		.DE_C_RegWrite(C_RegWrite_WB),
		.DE_C_ForwardA_HZ(HZ_C_ForwardA_DE),
		.DE_C_ForwardB_HZ(HZ_C_ForwardB_DE),
		.DE_C_FlushOutput_HZ(HZ_C_FlushOutput_DE),
		.DE_C_Stall_DB(DB_Stall),
		.DE_C_Lector_DB(DB_Lector),
		.DE_AOperand(AOperand_DE),
		.DE_BOperand(BOperand_DE),
		.DE_ExtendedImmediate(ExtendedImmediate_DE),
		.DE_DestRegAlu(DestRegAlu_DE),
		.DE_DestRegLoad(DestRegLoad_DE),
		.DE_PCPlus4_O(PCPlus4_DE),
		.DE_PCImmediate(PCImmediate_DE),
		.DE_PCBranch(PCBranch_DE),
		.DE_PCJump(PCJump_DE),
		.DE_RegS_W(HZ_Rs_DE),
		.DE_RegS(RegS_DE),
		.DE_RegT(HZ_Rt_DE),
		.DE_RegisterA(RegisterA_DE),
		.DE_C_RegWrite_O(C_RegWrite_DE),
		.DE_C_DataSource(C_DataSource_DE),
		.DE_C_MemWrite(C_MemWrite_DE),
		.DE_C_PCSrc(C_PCSrc_DE),
		.DE_C_Jump_W(C_Jump_W_DE),
		.DE_C_Jump(C_Jump_DE),
		.DE_C_RegDest(C_RegDest_DE),
		.DE_C_AluSource(C_AluSource_DE),
		.DE_C_ALUSel(C_ALUSel_DE),
		.DE_C_StoreLoad(C_StoreLoad_DE),
		.DE_C_Extend(C_Extend_DE),
		.DE_C_Halt(C_Halt_DE),
		.DE_C_Halt_W(C_Halt_DE_W),
		.DE_C_Branch_HZ(HZ_C_Branch_DE)
	);
	
	EX execution
	(
		.clk(Clk),
		.EX_AOperand(AOperand_DE),
		.EX_BOperand(BOperand_DE),
		.EX_DestRegAlu(DestRegAlu_DE),
		.EX_DestRegLoad(DestRegLoad_DE),
		.EX_ExtendedImmediate(ExtendedImmediate_DE),
		.EX_PCPlus4(PCPlus4_DE),
		.EX_ALUOut_I(ALUOut_W_ME),
		.EX_Result(Result_WB),
		.EX_RegS(RegS_DE),
		.EX_C_RegWrite(C_RegWrite_DE),
		.EX_C_DataSource(C_DataSource_DE),
		.EX_C_MemWrite(C_MemWrite_DE),
		.EX_C_Jump(C_Jump_DE),
		.EX_C_RegDest(C_RegDest_DE),
		.EX_C_AluSource(C_AluSource_DE),
		.EX_C_ALUSel(C_ALUSel_DE),
		.EX_C_StoreLoad(C_StoreLoad_DE),
		.EX_C_Extend(C_Extend_DE),
		.EX_C_Halt(C_Halt_DE),
		.EX_C_ForwardA_HZ(HZ_C_ForwardA_EX),
		.EX_C_ForwardB_HZ(HZ_C_ForwardB_EX),
		.EX_C_Stall_DB(DB_Stall),
		.EX_ALUOut(ALUOut_EX),
		.EX_DataToWrite(DataToWrite_EX),
		.EX_RegToWrite(RegToWrite_EX),
		.EX_PCPlus4_O(PCPlus4_EX),
		.EX_RegS_O(HZ_Rs_EX),
		.EX_RegT(HZ_Rt_EX),
		.EX_RegDest(HZ_RDest_EX),
		.EX_C_RegWrite_O(C_RegWrite_EX),
		.EX_C_DataSource_O(C_DataSource_EX),
		.EX_C_MemWrite_O(C_MemWrite_EX),
		.EX_C_Jump_O(C_Jump_EX),
		.EX_C_StoreLoad_O(C_StoreLoad_EX),
		.EX_C_Extend_O(C_Extend_EX),
		.EX_C_Halt_O(C_Halt_EX),
		.EX_C_Load_HZ(HZ_C_Load_EX),
		.EX_C_WriteReg_HZ(HZ_C_WriteReg_EX)
	);
	
	ME memory
	(
		.clk(Clk),
		.ME_ALUOut(ALUOut_EX),
		.ME_DataToWrite(DataToWrite_EX),
		.ME_RegToWrite(RegToWrite_EX),
		.ME_PCPlus4(PCPlus4_EX),
		.ME_DirMem_DB(DB_DirMem),
		.ME_C_RegWrite(C_RegWrite_EX),
		.ME_C_DataSource(C_DataSource_EX),
		.ME_C_MemWrite(C_MemWrite_EX),
		.ME_C_Jump(C_Jump_EX),
		.ME_C_StoreLoad(C_StoreLoad_EX),
		.ME_C_Extend(C_Extend_EX),
		.ME_C_Halt(C_Halt_EX),
		.ME_C_Stall_DB(DB_Stall),
		.ME_C_Lector_DB(DB_Lector),
		.ME_ALUOut_O(ALUOut_ME),
		.ME_ReadData(ReadData_ME),
		.ME_RegToWrite_O(RegToWrite_ME),
		.ME_PCPlus4_O(PCPlus4_ME),
		.ME_ALUOut_O_W(ALUOut_W_ME),
		.ME_RegDest(HZ_RDest_ME),
		.ME_MemoryData(MemoryData_ME),
		.ME_C_RegWrite_O(C_RegWrite_ME),
		.ME_C_DataSource_O(C_DataSource_ME),
		.ME_C_Jump_O(C_Jump_ME),
		.ME_C_StoreLoad_O(C_StoreLoad_ME),
		.ME_C_Extend_O(C_Extend_ME),
		.ME_C_Halt_O(C_Halt_ME),
		.ME_C_Load_HZ(HZ_C_Load_ME),
		.ME_C_WriteReg_HZ(HZ_C_WriteReg_ME)
	);
	
	WB write_back
	(
		.WB_ALUOut(ALUOut_ME),
		.WB_ReadData(ReadData_ME),
		.WB_RegToWrite(RegToWrite_ME),
		.WB_PCPlus4(PCPlus4_ME),
		.WB_C_RegWrite(C_RegWrite_ME),
		.WB_C_DataSource(C_DataSource_ME),
		.WB_C_Jump(C_Jump_ME),
		.WB_C_StoreLoad(C_StoreLoad_ME),
		.WB_C_Extend(C_Extend_ME),
		.WB_C_Halt(C_Halt_ME),
		.WB_Result(Result_WB),
		.WB_RegToWrite_O(RegToWrite_WB),
		.WB_C_RegWrite_O(C_RegWrite_WB),
		.WB_C_Halt_O(C_Halt_WB)
	);
	
	HazardUnit hazard
	(
		.DE_Rs(HZ_Rs_DE),
		.DE_Rt(HZ_Rt_DE),
		.EX_Rs(HZ_Rs_EX),
		.EX_Rt(HZ_Rt_EX),
		.EX_RDest(HZ_RDest_EX),
		.ME_RDest(HZ_RDest_ME),
		.WB_RDest(RegToWrite_WB),
		.DE_C_Branch(HZ_C_Branch_DE),
		.EX_C_Load(HZ_C_Load_EX),
		.EX_C_WriteReg(HZ_C_WriteReg_EX),
		.ME_C_Load(HZ_C_Load_ME),
		.ME_C_WriteReg(HZ_C_WriteReg_ME),
		.WB_C_WriteReg(C_RegWrite_WB),
		.IF_C_StallPC(HZ_C_StallPC_IF),
		.IF_C_StallOutput(HZ_C_StallOutput_IF),
		.DE_C_ForwardA(HZ_C_ForwardA_DE),
		.DE_C_ForwardB(HZ_C_ForwardB_DE),
		.DE_C_FlushOutput(HZ_C_FlushOutput_DE),
		.EX_C_ForwardA(HZ_C_ForwardA_EX),
		.EX_C_ForwardB(HZ_C_ForwardB_EX)
	);

	DebugUnit debug
	(
		.clk(Clk),
		.dato_rx(res_rx),
		.rx_ready(d),
		.data_ready(DB_DataReady),
		.finish(C_Halt_WB),
		.register(RegisterA_DE),
		.memory(MemoryData_ME),
		.PCounter(PC_IF),
		.latch(DB_Latch),
		.data(DB_Data),
		.data_start(DB_DataStart),
		.dir_reg(DB_DirReg),
		.dir_mem(DB_DirMem),
		.dir_latch(DB_DirLatch),
		.lector(DB_Lector),
		.stall(DB_Stall)
	);

	interface interfaz
	(
		.clk(Clk),
		.tick(t),
		.tx_ready(k),
		.dato(DB_Data),
		.start(DB_DataStart),
		.dato_tx(res_tx),
		.tx_start(j),
		.dato_ready(DB_DataReady)
	);
	
	baudrategenerator generator
	(
		.clk(Clk),
		.tick(t)
	);
	
	receptor rx
	(
		.clk(Clk),
		.rx(serial_in),
		.s_tick(t),
		.d_out(res_rx),
		.rx_done(d)
	);
	 
	transmisor tx
	(
		.clk(Clk),
		.d_in(res_tx),
		.tx_start(j),
		.s_tick(t),
		.tx(serial_out),
		.tx_done(k)
	);

endmodule
