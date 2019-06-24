// Module definition for datapath, puts together all modules and links them
module datapath( clk, readnum, writenum, vsel, loada, loadb,        // register operand fetch stage
				 shift, asel, bsel, ALUop, loadc, loads,  // computation stage (sometimes called "execute")
				 write,			  // set when "writing back" to register file
				 mdata, PC_in,
				 sximm5, sximm8,
				 Z_out, C, N, V, Z); 					 // outputs
	
	input clk, write, asel, bsel;
	input [3:0] vsel;
	input [2:0] readnum, writenum;
	input loada, loadb, loadc, loads;
	input [1:0] shift, ALUop;
	input [15:0] mdata; ////
	input [8:0] PC_in;  ////
	input [15:0] sximm5, sximm8;
	output [15:0] C;
	output [2:0] Z_out;
	output N, V, Z;
	
	
	// wires for signals that will be assigned values later
	wire [15:0] data_in, data_out;
	wire [15:0] a_out, b_out;
	wire [15:0] Ain, Bin;
	wire [15:0] sout;
	wire [2:0] Z_status;
	wire [15:0] out;
	
	// module instantiation for regfile - connects the data_in with data_out, eventually for top level module
	regfile REGFILE(data_in,writenum,write,readnum,clk,data_out);
	// module instantiation for shifter - connects the in (b_out) to the out (sout)
	shifter SHIFTER(b_out, shift, sout);
	// module instantiation for ALU - Connects Ain, Bin with out and Z, so that the ALU works properly
	ALU ALU_tb(Ain,Bin,ALUop,out,Z_status);
	
	// Assigns new registers to store new values according to load
	RegLoad #(16) RA(clk, loada, data_out, a_out);   // Register A
	RegLoad #(16) RB(clk, loadb, data_out, b_out);   // Register B
	RegLoad #(16) RC(clk, loadc, out, C); // Register C
	RegLoad #(3) Status(clk, loads, Z_status, Z_out);      // Status Register
	
	// vsel is a one hot code, selects one of the 4 inputs for data_in
	Mux4 #(16) M1(mdata, sximm8, {7'b0, PC_in}, C, vsel, data_in );   ////
		
	// multiplexer with load asel, inputs are 16'b0 and a_out
	assign Ain = asel ? 16'b0 : a_out;
	// multiplexer with load bsel, inputs are sximm5 and sout
	assign Bin = bsel ? sximm5 : sout;  ////
	
	// N is Negative output
	assign N = Z_out[0];
	// V is Overflow output
	assign V = Z_out[1];
	// Z is if output is 0
	assign Z = Z_out[2];
	
endmodule // datapath