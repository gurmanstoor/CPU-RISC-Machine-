// define states and state width
`define SW		5
`define RESET		5'b00000
`define IF1		5'b00001
`define IF2		5'b00010
`define UPDATE_PC2	5'b00011
`define DECODE		5'b00100
`define WRITE_IMM	5'b00101
// define states and state width
`define SW		5
`define RESET		5'b00000
`define IF1		5'b00001
`define IF2		5'b00010
`define UPDATE_PC2	5'b00011
`define DECODE		5'b00100
`define WRITE_IMM	5'b00101
`define GET_A		5'b00110
`define GET_B		5'b00111
`define MOV_ADD		5'b01000
`define ALU_ADD		5'b01001
`define ALU_CMP		5'b01010
`define ALU_AND		5'b01011
`define ALU_MVN		5'b01100
`define WRITE_REG	5'b01101
`define MEM_COMP	5'b01110
`define DATA_ADDR	5'b01111
`define DATA_ADDR2	5'b10000
`define HALT		5'b10001
`define LDR_1   	5'b10010
`define STR_1		5'b10011
`define STR_2		5'b10100
`define STR_3		5'b10101
`define UPDATE_PC	5'b10110
`define BL		5'b10111
`define BX		5'b11000
`define BX2		5'b11001


`define MNONE		2'b00
`define MWRITE		2'b01
`define MREAD		2'b10

// module declaration for cpu
module cpu(clk,reset, read_data,in,out,N,V,Z, mem_addr, mem_cmd, presentState);
	input clk, reset;
	input [15:0] read_data;
	input [15:0] in;
	output [15:0] out;
	output N, V, Z;
	output [8:0] mem_addr;
	output [1:0] mem_cmd;

	//LEDR
	output [4:0] presentState;
	
	
	// wires and regs to be used in lower modules and state machine
	wire [15:0] in_data;
	wire write, asel, bsel;
	wire [3:0] vsel;
	wire [2:0] readnum, writenum;
	wire loada, loadb, loadc, loads;
	wire [1:0] shift, ALUop;
	wire [15:0] mdata;
	wire [8:0] PC, PC_in;
	//wire [8:0] PC_in;
	wire [15:0] sximm5, sximm8;
	wire [15:0] C;
	wire [2:0] opcode;
	wire [1:0] op;
	wire [2:0] Z_out;
	wire [2:0] Rn;
	wire [2:0] nsel;
	
	wire load_ir;
	
	wire reset_pc, load_pc;
	
	
	
	wire [8:0] data_addr_in, data_addr_out;
	
	wire [1:0] mem_cmd;
	wire addr_sel, load_addr;
	
	// wire for state
	wire [4:0] presentState;

	assign PC_in = PC + 9'b000000001;
		
	// data_addr register in value is the out value (lower 9 bits)
	assign data_addr_in = C[8:0];
	// register with load enable for data address
	RegLoad #(9) Data_address(clk, load_addr, data_addr_in, data_addr_out);
	
	// mdata is equal to read_data output from memory
	assign mdata = read_data;
	// module instantiation for instruction decoder - interprets the input into seperate signals
	instruction_dec IN(in_data, nsel, opcode, op, readnum, writenum, shift, sximm5, sximm8, Rn, ALUop);
	
	// module instantiation for datapath - does majority of the internal work
	datapath DP(clk, readnum, writenum, vsel, loada, loadb,  
				 shift, asel, bsel, ALUop, loadc, loads, 
				 write,			  
				 mdata, PC_in,
				 sximm5, sximm8,
				 Z_out, C, N, V, Z);

	//assign pc_sel = (({opcode,op}== 5'b010_00)&(presentState == `UPDATE_PC2));

	// instantiation of program counter - keeps track of the instruction number	 
	Program_Counter pc_1(clk,reset_pc, load_pc, opcode, op, Rn, C, N, V, Z, sximm8, PC);
	
	// mux for address register
	assign mem_addr = addr_sel ? PC : data_addr_out;

	//Finite state machine module instantiation
	finite FSM(clk, reset, opcode, op, presentState, Rn, loada, loadb, loadc, loads, nsel, vsel, write, 
		   asel, bsel, load_ir, reset_pc, load_pc, mem_cmd, addr_sel, load_addr); 

	// module instantiation for flip flop (update in value on rising edge of clk)
	// if load is 1 temp data is in, if not it will not change
	vDFF #(16) vdff1(clk, load_ir ? in : in_data, in_data);

	// assign the value of out to C
	assign out = C;

endmodule  //cpu


module finite(clk, reset, opcode, op, presentState, Rn, loada, loadb, loadc, loads, nsel, vsel, write, 
		asel, bsel, load_ir, reset_pc, load_pc, mem_cmd, addr_sel, load_addr) ; 

	input clk, reset;
	input[2:0] opcode, Rn;
	input[1:0] op;

	output wire [4:0] presentState;
	output reg loada, loadb, loadc, loads;
	output reg write, asel, bsel;
	output reg [2:0] nsel;
	output reg [3:0] vsel;
	output reg load_ir;
	output reg reset_pc, load_pc;
	output reg [1:0] mem_cmd;
	output reg addr_sel, load_addr;


	wire[4:0] nextStateReset;
	reg[4:0] nextState;
	//wire[4:0] p;

	//assign p = presentState;


	// module instantiation for flip flop, update next state on rising edge of clk
	vDFF #(`SW) STATE(clk, nextStateReset, presentState);
	
	// go to reset state if reset is 1, otherwise go to next state
	assign nextStateReset = reset ? `RESET : nextState;	

	
	
	// always block for state machine, posedge clk not needed because of vDFF
	always @(*) begin
		// case statement for every possible state
		case(presentState)
			// reset state for when reset is asserted
			`RESET 		: begin
							// reset_pc is 1 to reset program counter
							reset_pc = 1;
							// load_pc is 1 to write to program counter
							load_pc = 1;
							// everything else is default 0
							load_addr = 0;
							mem_cmd = `MNONE;
							addr_sel = 0;
							load_ir = 0;
							write = 0;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							asel = 0;
							bsel = 0;
							// next state is IF1
							nextState = `IF1;
						end
			// state for IF1
			`IF1 		: begin
							// write to address register
							addr_sel = 1;
							
							//defaults
							reset_pc = 0;
							load_addr = 0;
							mem_cmd = `MREAD;
							load_pc = 0;
							load_ir = 0;
							write = 0;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							asel = 0;
							bsel = 0;
							// assign next state
							nextState = `IF2;
						end
			// IF 1 state
			`IF2		: begin
							// set load_ir to 1 to write to instruction register
							addr_sel = 1;
							load_ir = 1;
							// defaults
							mem_cmd = `MREAD;
							load_pc = 0;
							reset_pc = 0;
							load_addr = 0;
							write = 0;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							asel = 0;
							bsel = 0;
							// assign next state
							nextState = `UPDATE_PC;
						end
			// update pc state
			`UPDATE_PC	: begin
							// load pc (count up once)
							load_pc = 0;
							//defaults
							addr_sel = 0;
							mem_cmd = `MNONE;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							write = 0;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							asel = 0;
							bsel = 0;
							// assign next state
							if ({opcode,op}==5'b010_11) nextState = `BL;
							else if({opcode,op}==5'b010_00) nextState = `BX;
							else nextState = `UPDATE_PC2;
						end
			// update pc 2 state
			`UPDATE_PC2	: begin
							// load pc (count up once)
							load_pc = 1;

							//defaults
							addr_sel = 0;
							mem_cmd = `MNONE;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							write = 0;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							asel = 0;
							bsel = 0;
							// assign next state
							if(opcode==3'b001) nextState = `IF1;
							else if (opcode == 3'b010) nextState = `IF1;
							else nextState = `DECODE;
						end
			// decoding instruction based on inputs
			`DECODE		: begin 
							// set other signals to 0, they are not being used
							load_pc = 0;
							mem_cmd = `MNONE;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							write = 0;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							asel = 0;
							bsel = 0;
							// case statement for deciding which state to go to next (checking opcode and op)
							casex ({opcode, op})
								// ADD, CMP and AND go to GET_A, 
								5'b101_00 : nextState = `GET_A;
								5'b101_01 : nextState = `GET_A;
								5'b101_10 : nextState = `GET_A;
								// MOV_ADD, MVN go to GET_B
								5'b110_00 : nextState = `GET_B;
								5'b101_11 : nextState = `GET_B;
								// MOV imm goes to write imm state
								5'b110_10 : nextState = `WRITE_IMM;
								// LDR
								5'b011_00 : nextState = `GET_A;
								// STR
								5'b100_00 : nextState = `GET_A;
								5'b111_xx : nextState = `HALT;
								//lab8 table 2 states
								//5'b010_11 : if(Rn ==3'b111) begin nextState = `BL; end
								//5'b010_00 : nextState = `BX;
								default : begin nextState = 5'bxxxxx;
								end
							endcase
						end
			// write an immediate constant value to a register
			`WRITE_IMM	: begin
							load_pc = 0;
							addr_sel = 0;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							// set vsel to 0100 (one hot), picking the sximm8 value
							vsel = 4'b0100;
							// write is 1 to write to the register
							write = 1;
							// nsel is 001 (one hot), writing to register Rn
							nsel = 3'b001;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							asel = 0;
							bsel = 0;
							mem_cmd = `MNONE;
							// next state is IF1
							nextState = `IF1; 
						end
			// This is to get the value from a register and store into A, for instructions that use more than one value
			`GET_A		: begin
							load_pc = 0;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							// nsel is 001 since we are reading from register Rn
							nsel = 3'b001;
							loada = 1;
							loadb = 0;
							loadc = 0;
							loads = 0;
							write = 0;
							vsel = 4'b0000;
							asel = 0;
							bsel = 0;
							mem_cmd = `MNONE;
							// case statement to determine next state
							case({opcode, op})
								5'b011_00 : nextState = `MEM_COMP;
								5'b100_00 : nextState = `MEM_COMP;
								// next state is GET_B for all other cases
								default  : nextState = `GET_B;
							endcase
						end
			// get the value from a register and store it in B, we will either get here from decode, or GET_A
			`GET_B		: begin
							load_pc = 0;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							mem_cmd = `MNONE;
							// nsel is 100 because we are reading from Rm
							nsel = 3'b100;
							loadb = 1; 
							write = 0;
							loada = 0;
							loadc = 0;
							loads = 0;
							vsel = 4'b0000;
							asel = 0;
							bsel = 0;
							// case statement for assigning next value for nextState
							case({opcode, op})
								// You will got to a certain state depending on opcode and op (these are the different instructions)
								5'b110_00 : nextState = `MOV_ADD;
								5'b101_00 : nextState = `ALU_ADD;
								5'b101_01 : nextState = `ALU_CMP;
								5'b101_10 : nextState = `ALU_AND;
								5'b101_11 : nextState = `ALU_MVN;
								default :   nextState = 5'bxxxxx;
							endcase
						end
			// moves a value from one register to another, using a shift if necessary
			`MOV_ADD	: begin
							load_pc = 0;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							mem_cmd = `MNONE;
							// set asel to 1 so when you add A + B = 0 + B = B
							asel = 1;
							bsel = 0;
							// put value into C
							loadc = 1;
							loada = 0;
							loadb = 0;
							loads = 0;
							write = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							// go to next state (WRITE_REG)
							nextState = `WRITE_REG;
						end
			// adds two input values together
			`ALU_ADD	: begin
							load_pc = 0;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							mem_cmd = `MNONE;
							asel = 0;
							bsel = 0;
							// put value into C
							loadc = 1;
							loada = 0;
							loadb = 0;
							loads = 0;
							write = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							// next state is WRITE_REG
							nextState = `WRITE_REG;
						end
			// compares two values and sets the 3 bit Z register depending on if the output is 0, has overflow, or is negative
			`ALU_CMP	: begin
							load_pc = 0;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							mem_cmd = `MNONE;
							asel = 0;
							bsel = 0;
							// set the value into register S
							loads = 1;
							loada = 0;
							loadb = 0;
							loadc = 0;
							write = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							// next state is WAIT
							nextState = `IF1;
						end
			// bitwise ands two values
			`ALU_AND	: begin
							load_pc = 0;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							mem_cmd = `MNONE;
							asel = 0;
							bsel = 0;
							// set value into C
							loadc = 1;
							loada = 0;
							loadb = 0;
							loads = 0;
							write = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							// nextstate is WRITE REG
							nextState = `WRITE_REG;
						end
			// Bitwise NOT of input B
			`ALU_MVN	: begin
							load_pc = 0;
							addr_sel = 0;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							mem_cmd = `MNONE;
							asel = 0;
							bsel = 0;
							// set value into C
							loadc = 1;
							loada = 0;
							loadb = 0;
							loads = 0;
							write = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							// next state is WRITE_REG
							nextState = `WRITE_REG;
						end
			// writes a value to a register in REGFILE from the register C
			`WRITE_REG	: begin
							load_pc = 0;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							// select C value
							vsel = 4'b0001;
							write = 1;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							asel = 1'b0;
							bsel = 1'b0;
							// write to Register Rd
							nsel = 3'b010;
							mem_cmd = `MNONE;
							// next state is WAIT
							nextState = `IF1;
						end
			// mem comp state
			`MEM_COMP	: begin
							load_pc = 0;
							addr_sel = 0;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							/* R[Rd]=M[R[Rn]+sx(im5)] */
							// adds R[Rn] with sximm5
							asel = 0;  // R[Rn]
							bsel = 1;  //sximm5
							loadc = 1; // puts it into C
							
							loada = 0;
							loadb = 0;
							loads = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							write = 0;
							addr_sel = 0;
							mem_cmd = `MNONE;
							// next state is DATA_ADDR
							nextState = `DATA_ADDR;
						end
			// state DATA_ADDR
			`DATA_ADDR	: begin
							load_pc = 0;
							load_ir = 0;
							reset_pc = 0;
							addr_sel = 0;
							
							
							vsel = 4'b0000;
							write = 0;
							nsel = 3'b000;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							asel = 0;
							bsel = 0;
							
							// write to address register
							load_addr = 1;
							// nextState is DATA_ADDR2
							nextState = `DATA_ADDR2;
							mem_cmd = `MNONE;
						end
			// state DATA_ADDR2
			`DATA_ADDR2	: begin
							// defaults
							addr_sel = 0;
							load_pc = 0;
							load_ir = 0;
							reset_pc = 0;
							vsel = 4'b0000;
							write = 0;
							nsel = 3'b000;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							asel = 0;
							bsel = 0;
							// make sure to stay writing to register
							load_addr = 1;
							mem_cmd = `MNONE;	
							// go to LDR or STR1 state
							case({opcode,op}) 
								5'b011_00 : nextState = `LDR_1;
								5'b100_00 : nextState = `STR_1;
								default : nextState = 5'bxxxxx;
							endcase
						end
			// HALT State
			`HALT		: begin
							load_pc = 0;
							load_addr = 0;
							addr_sel = 0;
							load_ir = 0;
							reset_pc = 0;
							
							mem_cmd = `MNONE;
								
							vsel = 4'b0000;
							write = 0;
							nsel = 3'b000;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							asel = 0;
							bsel = 0;
							// stay in halt (unless reset)
							nextState = `HALT;
						end
			// LDR1
			`LDR_1		: begin
							// take value mdata
							vsel = 4'b1000;
							// write it to a register
							write = 1;
							loada = 0;
							loadb = 0;
							loadc = 0;
							loads = 0;
							asel = 0;
							bsel = 0;
							
							load_pc = 0;
							load_addr = 0;
							addr_sel = 0;
							load_ir = 0;
							reset_pc = 0;
							// write to Register Rd
							nsel = 3'b010;
							mem_cmd = `MREAD; // reading address from memory
							// go to IF1
							nextState = `IF1;
						end
			// STR1
			`STR_1		: begin
							load_pc = 0;
							addr_sel = 0;
							load_ir = 0;
							load_addr = 0;
							reset_pc = 0;
							// writing to memory
							mem_cmd = `MWRITE;
							// nsel is 010 because we are reading from Rd
							nsel = 3'b010;
							// write to register B
							loadb = 1; 
							// write the value
							write = 1;
							
							// more defaults
							loada = 0;
							loadc = 0;
							loads = 0;
							vsel = 4'b0000;
							asel = 1;
							bsel = 1;
							// go to STR2
							nextState = `STR_2;
						end
			// STR2
			`STR_2		: begin
							load_pc = 0;
							addr_sel = 0;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							
							// R[Rd] + 0
							asel = 1;  // 0
							bsel = 0;  //R[Rd]
							loadc = 1; // put into C
							
							loada = 0;
							loadb = 0;
							loads = 0;
							nsel = 3'b000;
							vsel = 4'b0000;
							write = 0;
							addr_sel = 0;
							// write to memory
							mem_cmd = `MWRITE;
							
							// go to STR3
							nextState = `STR_3;
						end
			// STR3
			`STR_3		: begin
							load_pc = 0;
							addr_sel = 0;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							
							asel = 0;
							bsel = 0;
							loadc = 0;
							
							loada = 0;
							loadb = 0;
							loads = 0;
							nsel = 3'b000;
							// take the value from C
							vsel = 4'b0000;
							write = 0;
							addr_sel = 0;
							// write to memory
							mem_cmd = `MWRITE;
							
							// go to IF1
							nextState = `IF1;
						end

			// lab 8 table 2 BL states
			`BL		: begin
							load_pc = 0;
							addr_sel = 0;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							
							asel = 0;
							bsel = 0;
							loadc = 0;
							
							loada = 0;
							loadb = 0;
							loads = 0;
	
							//write to Rn
							nsel = 3'b001;
							// take the value from PC
							vsel = 4'b0010;
							write = 1;
							addr_sel = 0;
							
							mem_cmd = `MNONE;
							
							// go to IF1
							nextState = `UPDATE_PC2;
						end

			// lab 8 table 2 BX state 1
			`BX		: begin
							load_pc = 0;
							addr_sel = 0;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							
							asel = 0;
							bsel = 0;
							loadc = 0;
							
							loada = 0;
							loadb = 1;
							loads = 0;
	
							//read from Rd
							nsel = 3'b010;
							// take the value from PC
							vsel = 4'b0000;
							write = 0;
							addr_sel = 0;
							
							mem_cmd = `MNONE;
							
							// go to IF1
							nextState = `BX2;
						end

			// lab 8 table 2 BX state 2
			`BX2		: begin
							load_pc = 0;
							addr_sel = 0;
							load_addr = 0;
							load_ir = 0;
							reset_pc = 0;
							
							asel = 1;
							bsel = 0;
							loadc = 1;
							
							loada = 0;
							loadb = 0;
							loads = 0;
	
							//read from Rd
							nsel = 3'b000;
							// take the value from PC
							vsel = 4'b0000;
							write = 0;
							addr_sel = 0;
							
							mem_cmd = `MNONE;
							
							// go to IF1
							nextState = `UPDATE_PC2;
						end
			// default state
			default: begin 
						// more defaults
						load_pc = 0;
						load_addr = 0;
						addr_sel = 0;
						load_ir = 0;
						reset_pc = 0;
						
						mem_cmd = `MNONE;
						
						vsel = 4'b0000;
						write = 0;
						nextState = 5'b00000;
						nsel = 3'b000;
						loada = 0;
						loadb = 0;
						loadc = 0;
						loads = 0;
						asel = 0;
						bsel = 0;
					end
		endcase	
						
	end
endmodule // finite state machine


// module definition for program counter
module Program_Counter(clk, reset_pc, load_pc, opcode, op, cond, Rd, N, V, Z, sximm8, PC);    
	input clk, reset_pc;
	input load_pc;
	input N, V, Z;
	input [2:0] opcode, cond;
	input [1:0] op;
	input [15:0] sximm8, Rd;
	output [8:0] PC;
	
	wire [8:0] next_pc;
	reg [8:0] next_temp;
	
	// register with load enable for pc
	RegLoad #(9) pc_reg(clk, load_pc, next_pc, PC);   
	// mux with counter added on
	assign next_pc = reset_pc ? 9'b0 : next_temp;


	//Branch case stateents for Lab8
	always@(*) begin

	case({opcode,op,cond})

	  //B state
	  {3'b001,2'b00,3'b000}: begin
					//if(sximm8[15]==1'b0) begin 
					next_temp = PC + 9'b000000001 + sximm8; //end
					//else begin next_temp = PC +9'b000000001 - sximm8; end
	  end

	  //BED state
	  {3'b001,2'b00,3'b001}: begin
					//if({Z,sximm8[15]}==2'b10) 
					if(Z==1'b1) begin next_temp = PC +9'b000000001 + sximm8; end
					//else if({Z,sximm8[15]}==2'b11) begin next_temp = PC +9'b000000001 - sximm8; end
					else  begin next_temp = PC + 9'b000000001; end
	  end

	  //BNE state
	  {3'b001,2'b00,3'b010}: begin
					//if({Z,sximm8[15]}==2'b00) 
					if(Z==1'b0) begin next_temp = PC +9'b000000001 + sximm8; end
					//else if({Z,sximm8[15]}==2'b01) begin next_temp = PC +9'b000000001 - sximm8; end
					else begin next_temp = PC + 9'b000000001; end
	  end
	
	  //BLT state
	  {3'b001,2'b00,3'b011}: begin
					//if((N!=V) & (sximm8[15]==1'b0)) 
					if(N!=V) begin next_temp = PC +9'b000000001 + sximm8; end
					//else if((N!=V) & (sximm8[15]==1'b1)) begin next_temp = PC +9'b000000001 - sximm8; end
					else begin next_temp = PC + 9'b000000001; end
	  end

	  //BLE state
	  {3'b001,2'b00,3'b100}: begin
					//if(((N!=V)|(Z==1'b1)) & (sximm8[15]==1'b0)) 
					if((N!=V)|(Z==1'b1)) begin next_temp = PC +9'b000000001 + sximm8; end
					//else if(((N!=V)|(Z==1'b1)) & (sximm8[15]==1'b1)) begin next_temp = PC +9'b000000001 - sximm8; end
					else begin next_temp = PC + 9'b000000001; end
	  end

	  //BL state
	  {3'b010,2'b11,3'b111}: begin 
					next_temp = PC + 9'b000000001 + sximm8;
	  end

	  //BX state
	  {3'b010,2'b00,3'b000}: begin 
					next_temp = Rd;
	  end


	  default: begin next_temp = PC + 9'b000000001; end

	endcase

  end

endmodule


