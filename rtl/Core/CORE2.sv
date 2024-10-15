module CORE_v2(
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
	output wire [1:0] GPIO_OP,
	output reg blink = 0
);
localparam PC = 5'd31;
localparam FETCH = 3'd3;
localparam EXECUTE = 3'd1;
localparam INTERACTION = 3'd2;
localparam HALT = 3'd0;
localparam PFETCH = 3'd4;


reg [31:0] RF [32];
initial RF[PC] = 32'd0;




assign ram_addres = (INS_T == MEM_ACT) ? RF[REG_B]+32'd3 : RF[PC];
assign data_to_mem = RF[REG_A];

reg [2:0] STATE = HALT;


enum bit [2:0] {NOP, CALC_CONST_A, CALC_CONST_B, CALC, MEM_ACT, HLT, CALC_EX} EXEC_TYPE;
enum bit [1:0] {SEL_RAM, SEL_UART} MEM_SEL_TYPE;



always_ff @( posedge clk ) begin : saver_block
  if (enabled) begin
	if (INS_T2 == CALC_CONST_A | INS_T2 == CALC | INS_T2 == CALC_CONST_B) RF[REG_A2] <= REG_B2 == 5'd31 ? ALU_RES_reg-32'd2 : ALU_RES_reg;
	else if (INS_T2 == MEM_ACT) if (REG_WE[MEM_SEL]) RF[REG_A2] <= MEM_VAL[MEM_SEL]; 
	if ((instr_queue[0][11:7] != 5'd31 & instr_queue[1][11:7] != 5'd31 & instr_queue[2][11:7] != 5'd31 )) RF[PC] <= RF[PC] + 32'd1;
  end
end


// Очередь инструкций. 0 - для получения из памяти, 1 для выбора данных и расчётов, 2 для записи результата
reg [31:0] instr_queue [3];
logic enabled = 0;
//Сдвиг
always @( posedge clk ) begin : instr_queue_block
    if (~enabled && ena) enabled <= '1;
	if (enabled) begin
		blink <= ~blink;
		if (instr_queue[0][11:7] == 5'd31 | instr_queue[1][11:7] == 5'd31 | instr_queue[2][11:7] == 5'd31 ) instr_queue[0] <= 32'd0;
		else begin
			instr_queue[0] <= ram_data_out; 
			//RF[PC] <= RF[PC] + 32'd1;
		end 
	    instr_queue [1] <= instr_queue[0];
		instr_queue [2] <= instr_queue[1];
	    
	end
	if (instr_queue[0][2:0] == 3'd5) enabled <= 0;
end





wire [31:0] INSTR = instr_queue[1];
wire [2:0] INS_T = INSTR[2:0];
wire [3:0] ALU_OP = INSTR[6:3];
wire [5:0] REG_A = INSTR[11:7];
wire [5:0] REG_B = INSTR[16:12];
wire [5:0] REG_C = INSTR[21:17];
wire [9:0] IMM_10 = INSTR[31:22];
wire [14:0] IMM_15 = INSTR[31:17];
wire [19:0] IMM_20 = INSTR[31:12];
wire [1:0] SHIFT_OP = INSTR[31:30] & {2{INS_T == CALC_EX}};

wire [31:0] INSTR2 = instr_queue[2];

wire [2:0] INS_T2 = INSTR2[2:0];
wire [3:0] ALU_OP2 = INSTR2[6:3];
wire [5:0] REG_A2 = INSTR2[11:7];
wire [5:0] REG_B2 = INSTR2[16:12];
wire [5:0] REG_C2 = INSTR2[21:17];
wire [9:0] IMM_102 = INSTR2[31:22];
wire [14:0] IMM_152 = INSTR2[31:17];
wire [19:0] IMM_202 = INSTR2[31:12];
wire [1:0] SHIFT_OP2 = INSTR2[31:30] & {2{INS_T2 == CALC_EX}};



//non core modules selection and control
//NOTE: MEM_OP = 0 MUST be non editing operation for any module
wire [1:0] MEM_OP;
wire [1:0] MEM_SEL;
assign {MEM_SEL, MEM_OP} = INSTR2[6:3] & {4{INS_T2 == MEM_ACT}};
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




// Логика АЛУ

//Входы Алу
wire [31:0] ALU_A;
assign ALU_A = (INS_T == CALC_CONST_A) ? IMM_20 : RF[REG_B];
wire [31:0] ALU_B;
assign ALU_B = (INS_T == CALC_CONST_B) ? IMM_15 : RF[REG_C];

//Результат АЛУ
wire [31:0] ALU_R;
reg [31:0] ALU_RES_reg;

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

//Сохранение результата АЛУ
always_ff @(posedge clk) begin
	ALU_RES_reg <= ALU_R;
end

endmodule