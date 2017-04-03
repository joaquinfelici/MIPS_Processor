`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:19:33 02/13/2017
// Design Name:   Pipeline
// Module Name:   C:/Facultad/10mo semestre/Arquitectura de Computadoras/MIPS/Test_Pipeline.v
// Project Name:  MIPS
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Pipeline
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Test_Pipeline;

	// Inputs
	reg clk;
	reg serial_in;

	// Outputs
	wire serial_out;

	// Instantiate the Unit Under Test (UUT)
	Pipeline uut (
		.Clk(clk), 
		.serial_in(serial_in),
		.serial_out(serial_out)
	);

	initial begin
		clk = 0;
		
		serial_in = 0;
		#10400;
		serial_in = 1;
		#10400;
		serial_in = 1;
		#10400;
		serial_in = 0;
		#10400;
		serial_in = 0;
		#10400;
		serial_in = 0;
		#10400;
		serial_in = 1;
		#10400;
		serial_in = 1;
		#10400;
		serial_in = 0;
		#10400;
		serial_in = 1;
	end
      
	always
		#1 clk = !clk;		
	
endmodule

