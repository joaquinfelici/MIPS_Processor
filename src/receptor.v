`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:36:32 11/11/2016 
// Design Name: 
// Module Name:    receptor 
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
module receptor
#( 
    parameter D_BIT = 8, //8 bits de datos
    parameter SB_BIT = 1 //1 bit de stop
)
(
  input clk,
  input rx, //bit de entrada
  input s_tick, //tick (16 por baud rate)
  output reg[D_BIT-1:0] d_out = 0, //byte de salida
  output reg rx_done = 0//señal de finalizacion
);

localparam SB_TICK = (SB_BIT*16)+8; //ticks de stop + 8

reg[3:0] s = 0; //contador de ticks
reg[3:0] n = 0; //contador de bits
reg[4:0] c = 0; //contador de ticks de stop

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
		if (!rx) //llega un 0 
        state_next = START;
		else
		  state_next = state;
    START:
		if (s == 7) //mitad de bit de start
		  state_next = DATA;
		else
		  state_next = state;
	 DATA: 
	   if (n == D_BIT-1) //todos los bits de datos leidos
        state_next = STOP;
		else
		  state_next = state;
    STOP:    
		if (c == SB_TICK-1) //todos los bits de stop
		  state_next = IDLE;
		else
		  state_next = state;
	 default: state_next = IDLE;
  endcase
end

always @ (posedge clk)
begin
  if(s_tick == 1)
  begin
	 if (state == START) 
	 begin
		if(s == 7) //reiniciar contador de ticks
		begin
    	  s <= 0;
		  state <= state_next;
		end
		else
		  s <= s + 1'b1;
	 end
	 else if (state == DATA)
	 begin	
		if (s == 15) //tomar bit y reiniciar contador de ticks
		begin
		  s <= 0;
		  d_out <= {rx, d_out[D_BIT-1:1]};
		  n <= n + 1'b1;
		  state <= state_next;
		end
		else
		  s <= s + 1'b1;
	 end
	 else if (state == STOP)
	 begin
		if(c == SB_TICK-1) //señal de terminado
		begin  
		  rx_done <= 1;
		  state <= state_next;
		end
		else
		  c <= c + 1'b1;
	 end
    else //reiniciar contadores
    begin
      s <= 0;
		c <= 0;
		n <= 0;
		rx_done <= 0;
		state <= state_next;
    end
  end
end

endmodule
