// module definition for ALU, computes different aritmetic operations
module ALU(Ain,Bin,ALUop,out,Z);
	input [15:0] Ain, Bin;
	input [1:0] ALUop;
	output [15:0] out;
	output [2:0] Z;
	
	// define regs for use in always block
	reg [15:0] out;
	reg [2:0] Z;
	reg Znew;
	
	// other wires to be used
	wire [15:0] s_sub;
	wire ovf;
	
	// module instantiation for AddSub, calculates overflow
	AddSub #(16) Sub1(Ain, Bin, 1'b1, s_sub, ovf);
	
	// always enter the block if something changes
	always @(*) begin
		// Case statement for different aritmetic operations
		case (ALUop)
			2'b00 : out = Ain + Bin; // Adding
			2'b01 : out = s_sub;
			2'b10 : out = Ain & Bin; // Bitwise And
			2'b11 : out = ~Bin;		 // Bitwise Not
			default : out = 0; // assign a default value of 0 if state is not defined
		endcase
		
		// Assign Znew to 1 if out is 0
		if (out == 16'b0)
			Znew = 1;
		else
			Znew = 0;
			
		// assign Z to Z, ovf, negative --> Z will be 1 if out is 0, ovf will be 1 if there is overflow, out[15] is negative if it is 1 
		Z = {Znew , ovf, out[15]};
	end
	
endmodule // ALU

// from slide set 6
// add a+b or subtract a-b, check for overflow
module AddSub(a,b,sub,s,ovf) ;
  parameter n = 8 ;
  input [n-1:0] a, b ;
  input sub ;           // subtract if sub=1, otherwise add
  output [n-1:0] s ;
  output ovf ;          // 1 if overflow
  wire c1, c2 ;         // carry out of last two bits
  wire ovf = c1 ^ c2 ;  // overflow if signs don't match

  // add non sign bits
  Adder1 #(n-1) ai(a[n-2:0],b[n-2:0]^{n-1{sub}},sub,c1,s[n-2:0]) ;
  // add sign bits
  Adder1 #(1)   as(a[n-1],b[n-1]^sub,c1,c2,s[n-1]) ;
endmodule

// from slide set 6
// multi-bit adder - behavioral
module Adder1(a,b,cin,cout,s) ;
  parameter n = 8 ;
  input [n-1:0] a, b ;
  input cin ;
  output [n-1:0] s ;
  output cout ;
  wire [n-1:0] s;
  wire cout ;

  assign {cout, s} = a + b + cin ;
endmodule 
