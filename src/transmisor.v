`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:36:42 11/11/2016 
// Design Name: 
// Module Name:    transmisor 
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
module transmisor
#( 
    parameter D_BIT = 8, //8 bits de datos
    parameter SB_BIT = 1 //1 bit de stop
)
(
  input clk,
  input[D_BIT-1:0] d_in, //byte de entrada
  input tx_start, //señal para enviar
  input s_tick, //tick (16 por baud rate)
  output reg tx = 1, //bit de salida
  output reg tx_done = 0 //salida completa
);

reg[3:0] s = 0; //contador de ticks
reg[3:0] n = 0; //contador de bits
reg[1:0] c = 0; //contador de bits de stop

localparam IDLE = 4'b0001;
localparam START = 4'b0010;
localparam DATA = 4'b0100;
localparam STOP = 4'b1000;
			  
reg[3:0] state = IDLE; //estado actual
reg[3:0] state_next = IDLE; //siguiente estado

always @*
begin
  case (state)
    IDLE:
      if (tx_start) //llega la señal para comenzar 
        state_next = START; 
		else
		  state_next = state;
    START:
      if (s == 15) //transmitio el primer 0
		  state_next = DATA;
		else
		  state_next = state;
    DATA:
      if (n == D_BIT-1) //transmitio los bits de datos
        state_next = STOP;
		else
		  state_next = state;
    STOP:
	   if (c == SB_BIT-1) //transmitio los bits de stop
        state_next = IDLE;
		else
		  state_next = state;
    default: state_next = IDLE;
  endcase
end

always @(posedge clk)
begin 
 if(s_tick == 1)
 begin
  if (state == START)
  begin
    if(s == 15) //reinicio contador y transmito un 0
	 begin
		s <= 0;
		tx <= 0;
		state <= state_next;
	 end
	 else
		s <= s + 1'b1;
  end
  else if (state == DATA)
  begin
	 if (s == 15)  //reinicio contador y transmito el bit de dato
		begin
		  s <= 0;
		  tx <= d_in[n];
		  n <= n + 1'b1;
		  state <= state_next;
		end
	 else
		s <= s + 1'b1;
  end
  else if (state == STOP) //reinicio contador y transmito el bit de stop
  begin
	 if(s == 15)
	 begin
		s <= 0;
		tx <= 1;
		if (c == SB_BIT-1) //señal de terminado
		begin
		  tx_done <= 1;
		  state <= state_next;
		end
		c <= c + 1'b1;
	 end
	 else
		s <= s + 1'b1;
  end
  else //reinicio contadores
  begin
      s <= 0;
		c <= 0;
		n <= 0;
		tx_done <= 0;
		state <= state_next;
  end
 end
end

endmodule

