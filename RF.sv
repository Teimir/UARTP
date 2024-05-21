module register_file #(parameter bit_width = 32, parameter sel_width = 5) (
	input wire 						clk,
	input wire 						sel_en,
	input wire 						pc_reset,
	input wire [sel_width - 1:0]	sel_a,
	input wire [sel_width - 1:0]	sel_b,
	input wire [sel_width - 1:0]	sel_c,
	input wire [bit_width - 1:0]	data_in,
	input wire [bit_width - 1:0]	data_in_pc,
	output wire [bit_width - 1:0]	data_out_a,
	output wire [bit_width - 1:0]	data_out_b,
	output wire [bit_width - 1:0]	data_out_pc
);
reg [bit_width - 1:0] reqisters [2 ** sel_width - 1:0];
assign data_out_a = reqisters[sel_a];
assign data_out_b = reqisters[sel_b];
assign data_out_pc = reqisters[2 ** sel_width - 1];
always @(posedge clk) begin
	if (sel_en) begin
		reqisters[sel_c] <= data_in;
		reqisters[2 ** sel_width - 1] <= &sel_c ? data_in : data_in_pc;
	end else begin
		reqisters[2 ** sel_width - 1] <= data_in_pc;
	end
	if (pc_reset) begin
		reqisters[2 ** sel_width - 1] <= '0;
	end
end
endmodule