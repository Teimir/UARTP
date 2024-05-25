module CORE(
	input clk
);
localparam PC = 5'd31;

reg [31:0] RF [32];

initial RF[PC] = 32'd0;

reg [31:0] INSTR = 32'd0;
reg ram_we = 0;



wire [11:0] ram_addres = (STATE == EXECUTE && INS_T == MEM_ACT) ? RF[REG_B] : RF[PC];
wire [31:0] ram_data_out;
wire [31:0] ram_data_in = RF[REG_A];

enum reg [2:0] {FETCH, EXECUTE, MEMORY_INTERACTION, HALT} STATE = FETCH;
enum bit [3:0] {NOP, CALC_CONST_A, CALC_CONST_B, CALC, MEM_ACT} EXEC_TYPE;


wire [2:0] INS_T = INSTR[2:0];
wire [3:0] ALU_OP = INSTR[6:3];
wire [5:0] REG_A = INSTR[11:7];
wire [5:0] REG_B = INSTR[16:12];
wire [5:0] REG_C = INSTR[22:17];
wire [9:0] IMM_10 = INSTR[31:22];
wire [14:0] IMM_15 = INSTR[31:17];
wire [19:0] IMM_20 = INSTR[31:12];

wire [31:0] ALU_A = (INS_T == CALC_CONST_A) ? IMM_20 : RF[REG_B];
wire [31:0] ALU_B = (INS_T == CALC_CONST_B) ? IMM_15 : RF[REG_C];

always @(posedge clk) begin
		case(STATE)
			FETCH: begin
				INSTR <= ram_data_out;
				STATE <= EXECUTE;
			end
			
			EXECUTE: begin
				case(INS_T)
					NOP: STATE <= FETCH;
					CALC_CONST_A: begin
						RF[REG_A] <= ALU_R;
						STATE <= FETCH;
					end
					CALC_CONST_B: begin
						RF[REG_A] <= ALU_R;
						STATE <= FETCH;
					end
					CALC: begin
						RF[REG_A] <= ALU_R;
						STATE <= FETCH;
					end
					MEM_ACT: begin
						ram_we <= ALU_OP[0];
						STATE <= MEMORY_INTERACTION;
					end
				endcase
				if ((INS_T != CALC && INS_T != CALC_CONST_B && INS_T != CALC_CONST_A) || (REG_A != PC)) RF[PC] <= RF[PC] + 12'd1;
			end
			
			MEMORY_INTERACTION: begin
				if (~ram_we) RF[REG_A] <= ram_data_out;
				else ram_we <= 0;
				STATE <= FETCH;
			end
		endcase
end

MEMORY RAM(
	.address	(ram_addres),
	.clock	(clk),
	.data		(ram_data_in),
	.wren		(ram_we),
	.q			(ram_data_out)
);


ALU #(
	.bit_width(32)
) ALUM(
  .OP	(ALU_OP),
  .A	(ALU_A),
  .B	(ALU_B),
  .R	(ALU_R)
);

endmodule