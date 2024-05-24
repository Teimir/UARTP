module CORE(
	input clk
);


reg [31:0] INSTR = 32'd0;
//
//
//
//

enum reg [2:0] {FETCH, EXECUTE, MEMORY_INTERACTION, HALT} STATE = FETCH;
enum bit [3:0] {NOP, CALC, MOV, MEM_ACT} EXEC_TYPE;

reg ram_we = '0;
wire [31:0] ram_data_out;


wire [31:0] PC;
wire [31:0] PRE_PC = ((INSTR[2:0] == MOV) && (INSTR[19:15] == '1)) || ((STATE == EXECUTE) && (INSTR[2:0] == MEM_ACT)) ? ALU_A : PC + 1;


wire [2:0] INS_T = INSTR[2:0];
wire [3:0] ALU_OP = INSTR[6:3];
wire [31:0] REG_A = INSTR[11:7];
wire [31:0] REG_B = INSTR[16:12];
wire [31:0] REG_C = INSTR[22:17];
wire [9:0] IMM_10 = INSTR[31:22];
wire [14:0] IMM_15 = INSTR[31:17];
wire [19:0] IMM_20 = INSTR[31:12];



wire [31:0] ALU_A;
wire [31:0] ALU_B;
wire [31:0] ALU_R;




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
			
				CALC: begin //data_in <= alu_R
					STATE <= FETCH;
				end
				
				MOV: begin
					STATE <= FETCH;
				end
				
				MEM_ACT: begin
					ram_we <= ALU_OP[0];
					STATE <= MEMORY_INTERACTION;
				end
				
			endcase
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


MEMORY RAM(
	.address	(PRE_PC),
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
register_file #(.bit_width(32), .sel_width(5)) RF (
	.clk				(clk),
	.sel_en			(((STATE == EXECUTE) & (INSTR[2:0] == CALC) | (INSTR[2:0] == MOV)) | ram_we),
	.pc_reset		('0),
	.sel_a			(INSTR[19:15]),
	.sel_b			(INSTR[24:20]),
	.sel_c			(INSTR[14:10]),
	.data_in			(STATE == MEMORY_INTERACTION ? ram_data_out : ALU_R),
	.data_in_pc		(PRE_PC),
	.data_out_a		(ALU_A),
	.data_out_b		(ALU_B),
	.data_out_pc	(PC)
);

endmodule