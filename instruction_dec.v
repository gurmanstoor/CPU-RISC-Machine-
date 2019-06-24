// module instantiation for instruction decoder, interprets input signals
module instruction_dec(in, nsel, opcode, op, readnum, writenum, shift, sximm5, sximm8, Rn, ALUop);
	input [15:0] in;
	input [2:0] nsel;
	output [2:0] opcode;
	output [1:0] op;
	output [2:0] readnum, writenum;
	output reg [1:0] shift;
	output [15:0] sximm5, sximm8;
	output [1:0] ALUop;
	output [2:0] Rn;
	
	// wires to be set
	wire [4:0] imm5; // immediate 5 bit value 
	wire [7:0] imm8; // immediate 8 bit value
	wire [2:0] Rd, Rm; // 3 registers to be used in computations
	
	// out opcode signal set from input
	assign opcode = in[15:13];
	// out op signal set from input
	assign op = in[12:11];
	
	// out Rn signal set from input
	assign Rn = in[10:8];
	// out Rd signal set from input
	assign Rd = in[7:5];
	// out Rm signal set from input
	assign Rm = in[2:0];
	
	// out shift signal set from input
	//assign shift = in[4:3];
	// out imm5 signal set from input
	assign imm5 = in[4:0];
	// out imm8 signal set from input
	assign imm8 = in[7:0];
	
	// sign extending imm5 to 16 bits
	assign sximm5 = {{11{imm5[4]}},imm5};
	// sign extending imm8 to 16 bits
	assign sximm8 = {{8{imm8[7]}}, imm8};
	
	// out signal ALUop set to input signals
	assign ALUop = in[12:11];
	
	// module instantiation for mux3 - uses nsel to pick which register to use
	Mux3 #(3) M2(Rm, Rd, Rn, nsel, readnum);
	// writenum and readnum are the same
	assign writenum = readnum;

	always@(*) begin

	case({opcode,op})

		{3'b011,2'b00}: shift = 2'b00;
		{3'b100,2'b00}: shift = 2'b00;
		{3'b010,2'b00}: shift = 2'b00;
		default: shift = in[4:3];
	endcase
	end
	
endmodule // instruction_dec