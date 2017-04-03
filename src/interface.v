`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:36:52 11/11/2016 
// Design Name: 
// Module Name:    interface 
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
module interface
(
	input clk,
	input tick,
	input tx_ready,
	input [31:0] dato, 
	input start,
	
	output reg [7:0] dato_tx = 8'b00000000,
	output reg tx_start = 1'b0,
	output reg dato_ready = 1'b0
);
	 
	localparam waiting_start = 5'b00001;
	localparam sending_1 = 5'b00010;
	localparam sending_2 = 5'b00100;
	localparam sending_3 = 5'b01000;
	localparam sending_4 = 5'b10000;

	reg[4:0] state = waiting_start; //estado actual
	reg[4:0] state_next = waiting_start; //siguiente estado

	always @ (posedge clk)
	begin
		if(tick == 1)
		begin
			if((state == waiting_start && state_next == sending_1) 
				|| (state == sending_1 && state_next == sending_2)
				|| (state == sending_2 && state_next == sending_3)
				|| (state == sending_3 && state_next == sending_4))
				tx_start <= 1'b1;
			else 
				tx_start <= 1'b0;
				
			if(state == sending_4 && state_next == waiting_start) 
				dato_ready <= 1'b1;
				
			state <= state_next;
		end
		
		if(dato_ready == 1'b1)
		begin
			dato_ready <= 1'b0;
		end
	end

	always @(posedge clk)
	begin	
		if (state == waiting_start) 
		begin
			if (start)
			begin
				dato_tx = dato[31:24];
				state_next = sending_1;
			end	
		end
		else if(state == sending_1)
		begin
			if(tx_ready)
			begin
				dato_tx = dato[23:16];
				state_next = sending_2;
			end
		end
		else if(state == sending_2)
		begin
			if(tx_ready)
			begin
				dato_tx = dato[15:8];
				state_next = sending_3;
			end
		end
		else if(state == sending_3)
		begin
			if(tx_ready)
			begin
				dato_tx = dato[7:0];
				state_next = sending_4;  
			end
		end
		else if(state == sending_4)
		begin
			if(tx_ready && (state_next != waiting_start))
			begin
				state_next = waiting_start;
			end
		end
	end 

endmodule

