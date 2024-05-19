module CORE(
	input clk
);


reg [31:0] REGS [32];
reg [31:0] INSTR = 32'd0;
reg [2:0] STATE = 3'b000;

reg ram_we = 0;
reg ram_addr = 0;
reg fetch_flg = 0;

localparam fetch = 3'b000;
localparam execute = 3'b001;
localparam readmem = 3'b010;

wire [31:0] ram_data_in;
wire [31:0] ram_data_out;

wire [3:0] alu_op;
wire [31:0] alu_a;
wire [31:0] alu_b;
wire [31:0] alu_res;

assign alu_op = INSTR[9:3];
assign alu_a = REGS[INSTR[19:15]];
assign alu_b = REGS[INSTR[24:20]];

always @(posedge clk) begin
	case(STATE)
		fetch: begin
			INSTR <= ram_data_out;
			STATE <= execute;
		end
		execute: begin
			case (INSTR[2:0])
				3'b01: REGS[INSTR[14:10]] <= alu_res;
				3'b10: REGS[INSTR[14:10]] <= REGS[INSTR[19:15]];
			endcase
			REGS[31] <= REGS[31] + 32'd1;
			ram_addr <= REGS[31] + 32'd1;
		end
		readmem: begin
			STATE <= fetch;
		end
	endcase
end


MEMORY RAM(
	.address	(ram_addr),
	.clock	(clk),
	.data		(ram_data_in),
	.wren		(ram_we),
	.q			(ram_data_out)
);

ALU #(
	.bit_width(32)
) ALUM(
  .OP	(alu_op),
  .A	(alu_a),
  .B	(alu_b),
  .R	(alu_res)
);

endmodule