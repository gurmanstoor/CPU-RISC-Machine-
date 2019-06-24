// module defenition for regfile, handles data input to output of the register file
module regfile(data_in,writenum,write,readnum,clk,data_out);
	input [15:0] data_in;
	input [2:0] writenum, readnum;
	input write, clk;
	output [15:0] data_out;
	
	// declare wires that will be used in the module
	wire [7:0] one_hot, load;
	wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
	
	// instantiate a 3->8 decoder from binary to a one hot code
	// (binary writenum into a one hot code of writenum)
	Dec #(3, 8) decoder(writenum, one_hot);
	
	// Assign load to a one hot code anded with a write value (individually with each bit), 
	// which will determine if load is on or not for each of the registers
	assign load[0] = write & one_hot[0]; // load[0] determines if you will write to R0
	assign load[1] = write & one_hot[1]; // load[1] determines if you will write to R1
	assign load[2] = write & one_hot[2]; // load[2] determines if you will write to R2
	assign load[3] = write & one_hot[3]; // load[3] determines if you will write to R3
	assign load[4] = write & one_hot[4]; // load[4] determines if you will write to R4
	assign load[5] = write & one_hot[5]; // load[5] determines if you will write to R5
	assign load[6] = write & one_hot[6]; // load[6] determines if you will write to R6
	assign load[7] = write & one_hot[7]; // load[7] determines if you will write to R7
	
	// Instantiate RegLoad module calling a 16 bit input, 
	// putting data into a Register if that Load is 1
	RegLoad #(16) RL0 (clk, load[0], data_in, R0); // Assign R0 data_in if load[0] is 1
	RegLoad #(16) RL1 (clk, load[1], data_in, R1); // Assign R1 data_in if load[1] is 1
	RegLoad #(16) RL2 (clk, load[2], data_in, R2); // Assign R2 data_in if load[2] is 1
	RegLoad #(16) RL3 (clk, load[3], data_in, R3); // Assign R3 data_in if load[3] is 1
	RegLoad #(16) RL4 (clk, load[4], data_in, R4); // Assign R4 data_in if load[4] is 1
	RegLoad #(16) RL5 (clk, load[5], data_in, R5); // Assign R5 data_in if load[5] is 1
	RegLoad #(16) RL6 (clk, load[6], data_in, R6); // Assign R6 data_in if load[6] is 1
	RegLoad #(16) RL7 (clk, load[7], data_in, R7); // Assign R7 data_in if load[7] is 1
	
	// Instantiate the Muxb8 module which converts the readnum data 
	// into data_out by using a Decoder and a Multiplexer (Reads a Register)
	Muxb8 #(16) Mux_out (R7, R6, R5, R4, R3, R2, R1, R0, readnum, data_out);
	
endmodule // regfile

// From slide set 6
// a - binary input   (n bits wide)
// b - one hot output (m bits wide)
module Dec(a, b) ;
  parameter n=2 ;
  parameter m=4 ;

  input  [n-1:0] a ;
  output [m-1:0] b ;

  wire [m-1:0] b = 1 << a ;
endmodule // Dec

// From slide set 6 (adapted)
// 8:1 multiplexer with binary select (arbitrary width)
module Muxb8(a7, a6, a5, a4, a3, a2, a1, a0, sb, b) ;
  parameter k = 1 ;
  input [k-1:0] a0, a1, a2, a3, a4, a5, a6, a7 ;  // inputs
  input [2:0]   sb ;   // binary select -- read_num
  output[k-1:0] b ;
  wire  [7:0]   s ;
  
  Dec #(3,8) d(sb,s) ; // Decoder converts binary to one-hot   
  Mux8 #(k)  m(a7, a6, a5, a4, a3, a2, a1, a0, s, b) ; // multiplexer selects input 
endmodule // Muxb8

// From slide set 6 (adapted)
// Eight input k-wide mux with one-hot select 
module Mux8( a7, a6, a5, a4, a3, a2, a1, a0, s, b) ;
  parameter k = 1 ;
  input [k-1:0] a0, a1, a2, a3, a4, a5, a6, a7 ;  // inputs
  input [7:0]   s ; // one-hot select
  output[k-1:0] b ;
  wire [k-1:0] b = ({k{s[0]}} & a0) | 
                   ({k{s[1]}} & a1) |
                   ({k{s[2]}} & a2) |
                   ({k{s[3]}} & a3) |
				   ({k{s[4]}} & a4) |
				   ({k{s[5]}} & a5) |
				   ({k{s[6]}} & a6) |
				   ({k{s[7]}} & a7) ;
endmodule // Mux8

// Adapted from slide set 6 (not quite the same)
// Flip flop with Mux for n input 1 output
module RegLoad( clk, load, in, out) ;
  parameter n = 1;  // width
  input load, clk;
  input 	[n-1:0] in ;
  output 	[n-1:0] out;
  reg 		[n-1:0] out;
  wire 		[n-1:0] next;
  
  // Flip flop, assigns output on rising edge of clk
  always @(posedge clk)
    out = next ;
  // Multiplexer using ? operator, assigns next to in if load is 1, and out if load is 0
  assign next = load ? in : out;
endmodule // RegLoad

// from slide set 6
// module mux4 (one hot)
module Mux4(a3, a2,a1,a0, s, b);
	parameter k = 1;
	input [k-1:0] a3, a2, a1, a0;
	input [3:0] s;
	output [k-1:0] b;
	
	assign b = ({k{s[0]}} & a0) | ({k{s[1]}} & a1) | ({k{s[2]}} & a2) | ({k{s[3]}} & a3);
endmodule

// from slide set 6
// module Mux 3 (one hot)
module Mux3(a2,a1,a0, s, b);
	parameter k = 1;
	input [k-1:0] a2, a1, a0;
	input [2:0] s;
	output [k-1:0] b;
	
	assign b = ({k{s[0]}} & a0) | ({k{s[1]}} & a1) | ({k{s[2]}} & a2);
endmodule