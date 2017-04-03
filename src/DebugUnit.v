`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:13:12 02/24/2017 
// Design Name: 
// Module Name:    DebugUnit 
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
module DebugUnit
(
	input clk,
	input [7:0] dato_rx,
	input rx_ready,
	input data_ready,
	input finish,
	
	input [31:0] register,
	input [31:0] memory,
	input [31:0] PCounter,
	input [31:0] latch,
	
	output reg [31:0] data = 32'b00000000000000000000000000000000,
	output reg data_start = 1'b0,
	output reg [4:0] dir_reg = 5'b00000,
	output reg [31:0] dir_mem = 32'b00000000000000000000000000000000,
	output reg [3:0] dir_latch = 4'b0000,
	
	output reg lector = 1'b0,
	output reg stall = 1'b1
); 
	 
	localparam waiting = 7'b0000001; 
	localparam continuous = 7'b0000010;
	localparam sendPC = 7'b0000100;
	localparam sendLatches = 7'b0001000;
	localparam sendRegisters = 7'b0010000;
	localparam sendMemory = 7'b0100000;
	localparam step = 7'b1000000;

	reg[6:0] state = waiting; //estado actual 
	reg[6:0] state_next = waiting; //siguiente estado

	always @ (negedge clk)
	begin
		state <= state_next; 
	end

	always @(posedge clk)
	begin	
		data_start = 1'b0;
		if (state == waiting) 
		begin
			if (rx_ready && dato_rx == 99)
			begin
				stall = 1'b0;
				lector = 1'b0;
				state_next = continuous;
			end	
			else if (rx_ready && dato_rx == 115)
			begin
				stall = 1'b0;
				lector = 1'b0;
				state_next = step;
			end
		end
		else if(state == continuous)
		begin
			if(finish)
			begin
				stall = 1'b1;
				lector = 1'b1;
				data = PCounter;
				data_start = 1'b1;
				state_next = sendPC;
			end
		end
		else if(state == sendPC)
		begin
			if(data_ready)
			begin
				data = latch;
				data_start = 1'b1;
				if(dir_latch == 4'b1111)
				begin
					dir_latch = 4'b0000;
					state_next = sendLatches;
				end
				else
				begin
					dir_latch = dir_latch + 1'b1;
				end
			end
		end
		else if(state == sendLatches)
		begin
			if(data_ready)
			begin
				data = register;
				data_start = 1'b1;
				if(dir_reg == 5'b11111)
				begin 
					dir_reg = 5'b00000;
					state_next = sendRegisters;
				end
				else
				begin
					dir_reg = dir_reg + 1'b1;
				end
			end
		end
		else if(state == sendRegisters)
		begin
			if(data_ready)
			begin
				data = memory;
				data_start = 1'b1;
				if(dir_mem == 5'b11111)
				begin
					dir_mem = 32'b00000000000000000000000000000000;
					state_next = sendMemory;
				end
				else
				begin
					dir_mem = dir_mem + 1'b1;
				end
			end
		end
		else if(state == sendMemory)
		begin
			if(data_ready)
			begin
				state_next = waiting;
			end
		end
		else if(state == step)
		begin
			stall = 1'b1;
			lector = 1'b1;
			data = PCounter;
			data_start = 1'b1;
			state_next = sendPC;
		end
	end 

endmodule


