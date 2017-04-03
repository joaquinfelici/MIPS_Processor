`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:36:21 11/11/2016 
// Design Name: 
// Module Name:    baudrategenerator 
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
module baudrategenerator
(
  input clk,
  output reg tick = 1'b0
);

reg[8:0] c = 1'b0; //contador de clocks

always @(posedge clk)
begin 
  c <= c + 1'b1;
  if (c == 325)
  begin
    tick <= 1'b1;
	 c <= 1'b0;
  end
  else
	 tick <= 1'b0;
end

endmodule

