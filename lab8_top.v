`define DISPLAY_ZERO 		7'b1000000
`define DISPLAY_ONE		7'b1111001
`define DISPLAY_TWO		7'b0100100
`define DISPLAY_THREE		7'b0110000
`define DISPLAY_FOUR		7'b0011001
`define DISPLAY_FIVE		7'b0010010
`define DISPLAY_SIX		7'b0000010
`define DISPLAY_SEVEN		7'b1111000
`define DISPLAY_EIGHT		7'b0000000
`define DISPLAY_NINE		7'b0010000
`define DISPLAY_NOTHING 	7'b1111111
`define DISPLAY_A		7'b0001000
`define DISPLAY_b		7'b0000011
`define DISPLAY_C		7'b1000110
`define DISPLAY_d		7'b0100001
`define DISPLAY_E		7'b0000110
`define DISPLAY_F		7'b0001110

`define MWRITE			2'b01
`define MREAD			2'b10

// module instantiation for lab7_top
module lab8_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);
	input [3:0] KEY;
	input CLOCK_50;
	input [9:0] SW;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

	// wires represent intermediate other signals within the module
	wire [7:0] read_address, write_address;
	wire write_logic;
	wire [15:0] din;
	wire [15:0] dout;
	wire [15:0] mdata;
	wire [15:0] C;
	wire [15:0] ir_in;
	wire N, V, Z;
	wire write;
	wire [15:0] read_data;
	wire [15:0] write_data;
	wire [8:0] mem_addr;
	wire clk, reset;
	wire [15:0] out;
	wire [15:0] in;
	wire msel;
	wire in_tri_state;
	wire [1:0] mem_cmd;
	wire switch_tri;
	wire led_in;

	//for LEDR
	wire [4:0] presentState;
	
	// clk is the opposite of key[0]
	assign clk = CLOCK_50;
	// reset is the opposite of key[1]
	assign reset = ~KEY[1];
	// in is the input to cpu, read_data is your output from memory/switches
	assign in = read_data;
	// din is your input to memory (out is output from cpu)
	assign din = out;
	// write_data is also your input to memory (out is output from cpu)
	assign write_data = out;
	
	// instantiation of RAM module - represents read and write capabilities for memory
	RAM MEM(clk, read_address, write_address, write, din, dout);
	
	// instantiation of cpu module - contains FSM
	cpu CPU(clk, reset, read_data, in, out, N, V, Z, mem_addr, mem_cmd, presentState);
	
	// read address is lower 8 bits of mem_addr
	assign read_address = mem_addr[7:0];
	// write address is also lower 8 bits of mem_addr
	assign write_address = mem_addr[7:0];
	// write logic is the MSB of mem_addr
	assign write_logic = mem_addr[8:8];
	
	// msel is 1 if write logic is 0
	assign msel = (write_logic == 1'b0);
	// write is 1 if we want to write, and msel is 1 (writing to memory)
	assign write = (mem_cmd == `MWRITE) & msel;
	// tri state input is 1 if we want to read and msel is 1 (reading from memory)
	assign in_tri_state = (mem_cmd == `MREAD) & msel;
	// read_data is defined by a tri state driver; gets dout if true (multiplexer)
	assign read_data = in_tri_state ? dout : 16'bz;		
	
	// assign input to switch tri state driver if you want to write and mem_addr is h140
	assign switch_tri = (mem_cmd == `MREAD) & (mem_addr == 9'h140);
	// read data gets lower 8 bits of switch when driven by tri_state switch
	assign read_data[7:0] = switch_tri ? SW[7:0] : 8'bz;
	
	// led_in is 1 if we want to write and mem_addr is h100 (address)
	assign led_in = (mem_cmd == `MWRITE) & (mem_addr == 9'h100);
	// instantiate load enable register to drive to LEDs
	RegLoad #(8) LEDs(clk, led_in, write_data[7:0], LEDR[7:0]);
	
	// hex display for Zero
	assign HEX5[0] = ~Z;
	// hex display for negative
	assign HEX5[6] = ~N;
	// hex display for overflow
	assign HEX5[3] = ~V;
	
	// disable  hex4
	assign HEX4 = 7'b1111111;
	assign {HEX5[2:1],HEX5[5:4]} = 4'b1111; // disabled


	assign LEDR[9] = 1'b0; // disabled

	//in HALT state LED goes on
	assign LEDR[8] = (presentState == 5'b10001);
  

	// instantiate 4 instances of sseg for the 4 Hex displays we
	// are using, defined as the out signal in binary
	// instantiation sseg for HEX0
	sseg H0(out[3:0],   HEX0);
	// instantiation sseg for HEX1
	sseg H1(out[7:4],   HEX1);
	// instantiation sseg for HEX2
	sseg H2(out[11:8],  HEX2);
	// instantiation sseg for HEX3
	sseg H3(out[15:12], HEX3);
endmodule

// from slide set 7
// instantiation of RAM module which reads and writes from/to memory
module RAM(clk,read_address,write_address,write,din,dout);
  parameter data_width = 16; 
  parameter addr_width = 8;
  parameter filename = "fig8.txt";

  input clk;
  input [addr_width-1:0] read_address, write_address;
  input write;
  input [data_width-1:0] din;
  output [data_width-1:0] dout;
  reg [data_width-1:0] dout;

  reg [data_width-1:0] mem [2**addr_width-1:0];

  initial $readmemb(filename, mem);

  always @ (posedge clk) begin
    if (write)
      mem[write_address] <= din;
    dout <= mem[read_address]; // dout doesn't get din in this clock cycle 
                               // (this is due to Verilog non-blocking assignment "<=")
  end 
endmodule

// from slide sets
module vDFF(clk,D,Q);
  parameter n=1;
  input clk;
  input [n-1:0] D;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clk)
    Q <= D;
endmodule

// from lab 6
module sseg(in,segs);
  input [3:0] in;
  output [6:0] segs;
  
  reg [6:0] segs;
  
  always @(*) begin 
	// display valid output on HEX display depending on input
	case(in)
		4'b0000: segs = `DISPLAY_ZERO;
		4'b0001: segs = `DISPLAY_ONE;
		4'b0010: segs = `DISPLAY_TWO;
		4'b0011: segs = `DISPLAY_THREE;
		4'b0100: segs = `DISPLAY_FOUR;
		4'b0101: segs = `DISPLAY_FIVE;
		4'b0110: segs = `DISPLAY_SIX;
		4'b0111: segs = `DISPLAY_SEVEN;
		4'b1000: segs = `DISPLAY_EIGHT;
		4'b1001: segs = `DISPLAY_NINE;
		4'b1010: segs = `DISPLAY_A;
		4'b1011: segs = `DISPLAY_b;
		4'b1100: segs = `DISPLAY_C;
		4'b1101: segs = `DISPLAY_d;
		4'b1110: segs = `DISPLAY_E;
		4'b1111: segs = `DISPLAY_F;
		default: segs = `DISPLAY_NOTHING;
	endcase	
	end

endmodule
