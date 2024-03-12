module memory #(
  parameter word_width = 8
)(
  input  wire                clk,
  input  wire                write,
  inout  wire  [word_width - 1:0]      operand,
  input  wire  [$clog2(word_width) - 1:0]  operand_addr,
  output  wire  [word_width - 1:0]      PC_R,
  input  wire  [$clog2(word_width) - 1:0]  PC_ADRR
);
reg [$clog2(word_width) - 1: 0] mem;
assign operand = write ? 'z : mem[operand_addr];
assign PC_R = mem[PC_ADRR];
always @(posedge clk) begin
  if (write) begin
    mem[operand_addr] <= operand;
  end
end
endmodule

