enum bit[3:0] {
  OP_CP,
  OP_ADD,
  OP_SUB,
  OP_NOT,
  OP_AND,
  OP_OR,
  OP_XOR,
  OP_RSH,
  OP_LSH,
  OP_CMP_GREATER,
  OP_CMP_EQUAL,
  OP_CMP_LESS,
  OUT_T,
  OUT_F
} ALU_OPERATION;
module ALU #(parameter bit_width = 32) (
  input wire [3:0]        OP,
  input wire [bit_width - 1:0]  A,
  input wire [bit_width - 1:0]  B,
  input wire [bit_width - 1:0] PC,
  output wire [bit_width - 1:0]  R
);
//логические операторы
wire [bit_width - 1:0] NOT = ~A;
wire [bit_width - 1:0] AND = A & B;
wire [bit_width - 1:0] OR = A | B;
wire [bit_width - 1:0] XOR = OR & ~AND;
//арифетические операторы
wire [bit_width:0] ADDER = (OP[0] ? A : NOT) + B;
//wire [bit_width:0] ADDER = A + B;

//сдвиги логические
wire [bit_width - 1:0] L_SHIFT = A << 1;
wire [bit_width - 1:0] R_SHIFT = A >> 1;
//сравнение
wire [bit_width - 1:0] CMP_GREATER = {bit_width{A > B}};
wire [bit_width - 1:0] CMP_EQUAL = {bit_width{A == B}};
wire [bit_width - 1:0] CMP_LESS = {bit_width{A < B}};

wire [bit_width - 1:0] OUT_T = (A == '1) ? B : PC;
wire [bit_width - 1:0] OUT_F = (A == '0) ? B : PC;
//вывод результата
wire [bit_width - 1:0] RAW_R [13:0];
assign RAW_R[13] = OUT_F; 
assign RAW_R[12] = OUT_T; 
assign RAW_R[11] = CMP_LESS; 
assign RAW_R[10] = CMP_EQUAL; 
assign RAW_R[9] = CMP_GREATER;
assign RAW_R[8] = L_SHIFT;
assign RAW_R[7] = R_SHIFT;
assign RAW_R[6] = XOR;
assign RAW_R[5] = OR;
assign RAW_R[4] = AND;
assign RAW_R[3] = NOT; 
assign RAW_R[2] = ~ADDER[bit_width - 1:0]; 
assign RAW_R[1] = ADDER[bit_width - 1:0];
assign RAW_R[0] = A; 

assign R = RAW_R[OP];
endmodule
