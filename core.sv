module core #(
	parameter word_width = 8
) (
	input	wire								clk,
	output	wire								write,
	input	wire	[word_width - 1:0]			operand,
	output	reg		[$clog2(word_width) - 1:0]	operand_addr,
	input	wire								reset,
	input	wire	[word_width - 1:0]			PC_R,
	output	reg		[$clog2(word_width) - 1:0]	PC_ADRR
);
reg [word_width - 1:0] A;
reg [1:0] state = '0;
reg [3:0] flags = '0;
/*
commands
fetch A
fetch operand_addr
push A
A <= A op RAM[operand_addr]

command structure
write [word_width - 1]| exec type [word_width - 2:word_width - 3] | args [word_width - 4:0]
args for fetch [1:0]
args for calc [2:0]
args for jump [1:0]


states
execute (00)
fetch A (01)
fetch operand_addr (10)
fetch operand (11)

особенность выполнения
КА автомат содержит 4 состояния
00 выполнение
01 загрузка А по PC
10 загрука адреса операнда
11 загрузка адреса операнда и А по PC

начало работы с состояния execute и PC = 0
reset устанавливает текущее состояние как начало работы

остановка тактов и отключение провода write позволяет работать с памятью, иначе ядро будет ожидать что памяь полностью ему принадлежит
*/
assign write = ~|state & PC_R[word_width - 1];	//если у нас состояние позволяет загрузку (то есть в execute state)
//провода АЛУ
wire [word_width - 1:0][7:0] R = {
	A + operand,
	A - operand,
	~A,
	A & operand,
	A | operand,
	A ^ operand,
	A >> 1,
	A << 1
};
//ZF АЛУ
wire [7:0] EXPECTED_ZF = {
	(A + operand)	== 0,
	(A - operand)	== 0,
	(~A)	== 0,
	(A & operand)	== 0,
	(A | operand)	== 0,
	(A ^ operand)	== 0,
	(A >> 1)== 0,
	(A << 1)== 0
};
//CF АЛУ
wire [7:0] EXPECTED_CF = {
	(A + operand) > 2 ** word_width - 1,
	(A - operand) < 0,
	1'b0,
	1'b0,
	1'b0,
	1'b0,
	1'b0,
	1'b0
};
//вспомогательные провода A_p, A_m для нахождения изменения старшего бита в результате сложения/вычитания
wire [word_width - 1:0] A_p = A + operand;
wire [word_width - 1:0] A_m = A - operand;
//OF АЛУ
wire [7:0] EXPECTED_OF = {
	A[word_width - 1] ^ A_p[word_width - 1],
	A[word_width - 1] ^ A_m[word_width - 1],
	1'b0,
	1'b0,
	1'b0,
	1'b0,
	1'b0,
	1'b0
};
//КА основанный на регистре state
always @(posedge clk) begin
	if (reset) begin
		//RESET
		state <= '0;
		PC_ADRR <= '0;
	end else begin
		//FETCH SPECIFIC
		if (state == 2'b01) begin	//RAM[PC]->A
			A <= PC_R;
		end else if (state == 2'b10) begin	//RAM[PC]->operand_addr
			operand_addr <= PC_R[$clog2(word_width) - 1:0];
		end else if (state == 2'b11) begin	//RAM[operand_addr]->A
			A <= operand;
		end
		if (|state) begin
			//если у нас загрузка, то перевести состояние в выполнение, у нас не может быть более 1 загрузки подряд
			state <= '0;
			PC_ADRR <= PC_ADRR + 1;
		end else begin
			//EXECUTE SPECIFIC
			if (PC_R[word_width - 2:word_width - 3] == 0) begin	//fetch
				state <= PC_R[1:0];
				PC_ADRR <= PC_ADRR + 1;
			end else if (PC_R[word_width - 2:word_width - 3] == 1) begin //calc
				A <= R[PC_R[1:0]];
				flags <= {EXPECTED_CF[PC_R[1:0]], EXPECTED_OF[PC_R[1:0]], EXPECTED_ZF[PC_R[1:0]], 1'b1};
				PC_ADRR <= PC_ADRR + 1;
			end else if (flags[PC_R[1:0]]) begin	//jump
				PC_ADRR <= A;
			end
		end
	end
end
endmodule
