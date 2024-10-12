module CORE(
	input ena,
	input wire clk,
	output wire [31:0] data_to_mem,
	//RAM
	output wire [12:0] ram_addres,
	output wire RAM_WE,
	input wire [31:0] ram_data_out,
	//UART
	input wire [31:0] uart_data_out,
	output wire [1:0] UART_OP,
	//GPIO
	input wire [31:0] gpio_data_out,
	output wire [1:0] GPIO_OP
);
localparam PC = 5'd31;
localparam FETCH = 3'd3;
localparam EXECUTE = 3'd1;
localparam INTERACTION = 3'd2;
localparam HALT = 3'd0;
localparam PFETCH = 3'd4;


reg [31:0] RF [32];
initial RF[PC] = 32'd0;

reg [31:0] INSTR = 32'd0;

assign ins = INS_T;

assign ram_addres = ((STATE == EXECUTE || STATE == INTERACTION) && INS_T == MEM_ACT) ? RF[REG_B] : RF[PC];
assign data_to_mem = RF[REG_A];

reg [2:0] STATE = HALT;


enum bit [2:0] {NOP, CALC_CONST_A, CALC_CONST_B, CALC, MEM_ACT, HLT, CALC_EX} EXEC_TYPE;
enum bit [1:0] {SEL_RAM, SEL_UART} MEM_SEL_TYPE;


wire [2:0] INS_T;
assign INS_T = INSTR[2:0];
wire [3:0] ALU_OP = INSTR[6:3];
wire [5:0] REG_A = INSTR[11:7];
wire [5:0] REG_B = INSTR[16:12];
wire [5:0] REG_C = INSTR[21:17];
wire [9:0] IMM_10 = INSTR[31:22];
wire [14:0] IMM_15 = INSTR[31:17];
wire [19:0] IMM_20 = INSTR[31:12];
wire [1:0] SHIFT_OP = INSTR[31:30] & {2{INS_T == CALC_EX}};
//non core modules selection and control
//NOTE: MEM_OP = 0 MUST be non editing operation for any module
wire [1:0] MEM_OP;
wire [1:0] MEM_SEL;
assign {MEM_SEL, MEM_OP} = INSTR[6:3] & {4{(STATE == INTERACTION) && (INS_T == MEM_ACT)}};
wire [3:0][31:0] MEM_VAL = {
	32'b0,
	32'b0,
	uart_data_out,	//SEL_UART
	ram_data_out	//SEL_RAM
};
wire [3:0] REG_WE = {
	1'b0,
	1'b0,
	~(&UART_OP | (UART_OP == 2'b1)),
	~RAM_WE	//SEL_RAM
};
//RAM specialisation
assign RAM_WE = MEM_OP & (MEM_SEL == SEL_RAM);
//UART specialisation
assign UART_OP = MEM_OP & {2{MEM_SEL == SEL_UART}};




wire [31:0] ALU_A;
assign ALU_A = (INS_T == CALC_CONST_A) ? IMM_20 : RF[REG_B];
wire [31:0] ALU_B;
assign ALU_B = (INS_T == CALC_CONST_B) ? IMM_15 : RF[REG_C];
wire [31:0] ALU_R;
reg [31:0] ALU_RES_reg;




always @(posedge clk) begin
	case(STATE)
		PFETCH: begin
			RF[PC] <= RF[PC] + 32'd1;
			STATE <= FETCH;
		end
		FETCH: begin
			INSTR <= ram_data_out;
			STATE <= EXECUTE;
		end	
		EXECUTE: begin
			case(INS_T)
				NOP: begin
					STATE <= PFETCH;
				end
				CALC_CONST_A: begin
					STATE <= INTERACTION;
				end
				CALC_CONST_B: begin
					STATE <= INTERACTION;
				end
				CALC: begin
					STATE <= INTERACTION;
				end
				MEM_ACT: begin
					STATE <= INTERACTION;
				end
				HLT: begin
					RF <= '{default:32'd0};
					STATE <= HALT;
				end
				default: begin
					STATE <= PFETCH;
				end
			endcase
		end	
		INTERACTION: begin
			case(INS_T)
				CALC_CONST_A: begin
					RF[REG_A] <= ALU_RES_reg;
				end
				CALC_CONST_B: begin
					RF[REG_A] <= ALU_RES_reg;
				end
				CALC: begin
					RF[REG_A] <= ALU_RES_reg;
				end
				MEM_ACT: begin
					if (REG_WE[MEM_SEL]) RF[REG_A] <= MEM_VAL[MEM_SEL];
				end
			endcase
			STATE <= PFETCH;
		end	
		HALT: begin
			if (ena) begin
			STATE <= FETCH;
			RF[PC] = 32'd0;
			end
		end	
	endcase
end


ALU #(
	.bit_width(32)
) ALUM(
  .OP		(ALU_OP),
  .SHIFT_OP	(SHIFT_OP),
  .A		(ALU_A),
  .B		(ALU_B),
  .R		(ALU_R),
  .PC		(RF[REG_A])
);

always @(posedge clk) begin
	ALU_RES_reg <= ALU_R;
end

endmodule