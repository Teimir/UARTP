module register_file #(parameter bit_width = 32, parameter sel_width = 5) (
	input wire 						clk,
	input wire 						en,
	input wire [sel_width - 1:0]	sel_a,
	input wire [sel_width - 1:0]	sel_b,
	input wire [sel_width - 1:0]	sel_c,
	input wire [bit_width - 1:0]	data_in,
	output wire [bit_width - 1:0]	data_out_a,
	output wire [bit_width - 1:0]	data_out_b
);
reg [bit_width - 1:0] reqisters [2 ** sel_width - 1:0];
assign data_out_a = reqisters[sel_a];
assign data_out_b = reqisters[sel_b];
assign data_out_pc = reqisters[2 ** sel_width - 1];
always @(posedge clk) begin
	if (en) begin
		reqisters[sel_c] <= data_in;
	end
end
endmodule