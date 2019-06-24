// module definition for shifter, which shifts the bit position to multiply/divide by bases of 2
module shifter(in,shift,sout);
	input [15:0] in;
	input [1:0] shift;
	output [15:0] sout;
	
	// declare regs for use in always block
	reg [15:0] sout;
	reg [15:0] copy_in;
	
	// always enter the block if any signal changes
	always @(*) begin
		// copy the in signal
		copy_in = in;
		// case statement deciding if you will not shift, shift left, 
		// shift right or shift right with the same value from the leftmost bit
		case (shift)
			2'b00 : sout = in; // no shift
			2'b01 : sout = in << 1; // shift left
			2'b10 :	sout = in >> 1; // shift right
			2'b11 : begin sout = in >> 1; // shift right and preserve MSB
						  sout[15] = copy_in[15]; end
			default : sout = 16'b?; // default if no valid state
		endcase
	end
	
endmodule // shifter