module CORE(
	input clk
);
enum reg [2:0] {FETCH, EXECUTE, MEMORY_INTERACTION, HALT} STATE = FETCH;
enum bit [3:0] {NOP, CALC_CONST_A, CALC, JMP, GET_PC, MEM_ACT} EXEC_TYPE;
reg [31:0] PC;
reg [31:0] INSTR;
//instr separation
wire [2:0]	INS_T	= INSTR[2:0];
wire [3:0]	ALU_OP	= INSTR[6:3];
wire [31:0]	REG_A	= INSTR[11:7];
wire [31:0]	REG_B	= INSTR[16:12];
wire [19:0]	IMM_20	= INSTR[31:12];
wire [31:0] RF_A;
wire [31:0] ALU_A = (INS_T == GET_PC) ? PC : (INS_T == CALC_CONST_A) ? IMM_20 : RF_A;
wire [31:0] ALU_B;
wire [31:0] ALU_R;
wire [31:0] PRE_PC = (INS_T == JMP) && |ALU_B ? ALU_A : PC + 1;
wire [31:0]	ADDR = (INS_T == MEM_ACT) ? ALU_A : PC + 1;

reg ram_we = '0;
wire [31:0] ram_data_out;


register_file #(.bit_width(32), .sel_width(5)) RF (
	.clk(clk),
	.en((STATE == MEMORY_INTERACTION) || !((INS_T == NOP) || (INS_T == JMP))),
	.sel_a(REG_A),
	.sel_b(REG_B),
	.sel_c(REG_A),
	.data_in((STATE == MEMORY_INTERACTION) ? ram_data_out : ALU_R),
	.data_out_a(RF_A),
	.data_out_b(ALU_B)
);
MEMORY RAM(
	.address	(ADDR),
	.clock		(clk),
	.data		(ALU_B),
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
always @(posedge clk) begin
	case(STATE)
		
		// Получаем инструкцию из памяти (EXECUTE гарантирует, что данные корректны, устанавливая их)
		FETCH: begin 
			INSTR <= ram_data_out;
			STATE <= EXECUTE;
		end
		
		//Выполняем действия по данным инструкции
		EXECUTE: begin
			case (INSTR[2:0])			
				NOP: begin //Ничего не делаем
					STATE <= FETCH;
				end	
				CALC_CONST_A: begin //data_in <= alu_R
					STATE <= FETCH;
				end		
				CALC: begin //data_in <= alu_R
					STATE <= FETCH;
				end		
				JMP: begin
					STATE <= FETCH;
				end
				GET_PC: begin
					STATE <= FETCH;
				end
				MEM_ACT: begin
					ram_we <= ALU_OP[0];
					STATE <= MEMORY_INTERACTION;
				end
				
			endcase
			PC <= PRE_PC;
		end
		MEMORY_INTERACTION: begin
			STATE <= FETCH;
			ram_we <= '0;
		end
		HALT: begin
			if (0) begin		//TODO: for future
				STATE <= FETCH;
			end
		end
	endcase
end
endmodule