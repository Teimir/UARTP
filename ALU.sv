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
wire [bit_width:0] ADDER = (OP[0] ? NOT : A) + B;
//сдвиги логические
wire [bit_width - 1:0] L_SHIFT = A << 1;
wire [bit_width - 1:0] R_SHIFT = A >> 1;
//сравнение
wire [bit_width - 1:0] CMP_GREATER = {bit_width{A > B}};
wire [bit_width - 1:0] CMP_EQUAL = {bit_width{A == B}};
wire [bit_width - 1:0] CMP_LESS = {bit_width{A < B}};

wire [bit_width - 1:0] OUT_T = (A == '1) ? B : PC + 32'd1;
wire [bit_width - 1:0] OUT_F = (A == '0) ? B : PC + 32'd1;
//вывод результата
wire [bit_width - 1:0][7:0] RAW_R  = {
  OUT_F,
  OUT_T,
  CMP_LESS,
  CMP_EQUAL,
  CMP_GREATER,
  L_SHIFT,
  R_SHIFT,
  XOR,
  OR,
  AND,
  NOT,
  ~ADDER[bit_width - 1:0],
  ADDER[bit_width - 1:0],
  A
};
assign R = RAW_R[OP];
endmodule
