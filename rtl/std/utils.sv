//STD library, see latest versions: https://github.com/Pasha-2033/monolit/blob/main/std/utils.sv
`define min(a, b) ((a) > (b) ? (b) : (a))
`define max(a, b) ((a) > (b) ? (a) : (b))
module bit_reverse #(
	parameter word_width
)(
	input	wire [word_width - 1:0] in,
	output	wire [word_width - 1:0] out
);
genvar i;
generate
	for(i = 0; i < word_width; ++i) begin: reverse
		assign out[i] = in[word_width - i - 1];
	end
endgenerate
endmodule
module fast_adder #(
	parameter cascade_size = 4,
	parameter word_width = 4
) (
	input	wire					C_IN,
	input	wire [word_width - 1:0]	A,
	input	wire [word_width - 1:0]	B,
	output	wire [word_width - 1:0]	R,
	output	wire					P,
	output	wire					G,
	output	wire					C_OUT
);
localparam cascade_num = word_width / cascade_size;
wire [cascade_size - 1:0] PP;
wire [cascade_size - 1:0] PG;
wire [cascade_size - 1:0] GG;
wire [cascade_size:0] C;
assign C[0] = C_IN;
assign C_OUT = C[cascade_size];
assign P = &PP;
assign G = |GG;
genvar i;
genvar j;
generate
	if (cascade_num > 1) begin
		for(i = 0; i < cascade_size; ++i) begin: adder_cascade
			fast_adder #(.cascade_size(cascade_size), .word_width(cascade_num)) child_fast_adder (
				.C_IN(C[i]),
				.A(A[i * cascade_num+:cascade_num]),
				.B(B[i * cascade_num+:cascade_num]),
				.R(R[i * cascade_num+:cascade_num]),
				.P(PP[i]),
				.G(PG[i])
			);
		end
	end else begin
		for(i = 0; i < cascade_size; ++i) begin: bit_cascade
			//can be optimised by component num
			assign R[i] = A[i] ^ B[i] ^ C[i];
			assign PP[i] = A[i] | B[i];
			assign PG[i] = A[i] & B[i];
		end
	end
	for(i = 0; i < cascade_size; ++i) begin: signal_cascade
		if (i == cascade_size - 1) begin
			assign GG[i] = PG[i];
		end else begin
			assign GG[i] = PG[i] & (&PP[cascade_size - 1:i + 1]);
		end
		wire [i + 1:0] PRE_C;
		assign PRE_C[i + 1] = PG[i];
		assign PRE_C[0] = C_IN & (&PP[i:0]);
		for (j = 0; j < i; ++j) begin: c_cascade
			assign PRE_C[j + 1] = PG[j] & (&PP[i:j + 1]);
		end
		assign C[i + 1] = |PRE_C;
	end
endgenerate
endmodule
//CARRY is a special case of DOUBLE_PECISION
typedef enum bit[1:0] {LOGIC, ARITHMETIC, DOUBLE_PECISION, CYCLIC} SHIFT_TYPE;
//WARNING: DO NOT SET $size(C_IN) > 1
`define RCR(D_IN, C_IN) {D_IN[$size(D_IN) - 2:1], C_IN}
module polyshift_r #(
	parameter word_width
) (
	input wire [word_width - 2:0] C_IN,
	input wire [word_width - 1:0] D_IN,
	input wire [$clog2(word_width) - 1:0] shift_size,
	input wire [1:0] shift_type,
	output wire [word_width - 1:0] D_OUT
);
wire [3:0][word_width - 2:0] shift_args = {
	D_IN[word_width - 2:0],						//CYCLIC,
	C_IN,										//DOUBLE_PECISION
	{word_width - 1{D_IN[word_width - 1]}},		//ARITHMETIC
	{word_width - 1{1'b0}}						//LOGIC
};
wire [word_width - 2:0] shift_arg = shift_args[shift_type];
wire [word_width - 1:0][word_width - 1:0] shift_input;
assign shift_input[0] = D_IN;
assign D_OUT = shift_input[shift_size];
genvar i;
generate
	for(i = 1; i < word_width; ++i) begin: input_generation
		assign shift_input[i] = {shift_arg[i - 1:0], D_IN[word_width - 1:i]};
	end
endgenerate
endmodule
`define RCL(D_IN, C_IN) {C_IN, D_IN[$size(D_IN) - 2:1]}
module polyshift_l #(
	parameter word_width
) (
	input wire [word_width - 2:0] C_IN,
	input wire [word_width - 1:0] D_IN,
	input wire [$clog2(word_width) - 1:0] shift_size,
	input wire [1:0] shift_type,
	output wire [word_width - 1:0] D_OUT
);
wire [3:0][word_width - 2:0] shift_args = {
	D_IN[word_width - 1:1],		//CYCLIC,
	C_IN,						//DOUBLE_PECISION
	{word_width - 1{1'b0}},		//ARITHMETIC (may be put '1??? because it`s looks like LOGIC)
	{word_width - 1{1'b0}}		//LOGIC
};
wire [word_width - 2:0] shift_arg = shift_args[shift_type];
wire [word_width - 1:0][word_width - 1:0] shift_input;
assign shift_input[0] = D_IN;
assign D_OUT = shift_input[shift_size];
genvar i;
generate
	for(i = 1; i < word_width; ++i) begin: input_generation
		assign shift_input[i] = {D_IN[word_width - i - 1:0], shift_arg[word_width - 2:word_width - i - 1]};
	end
endgenerate
endmodule
module counter_c #(
	parameter word_width
) (
	input	wire					clk,
	input	wire					count,
	input	wire					load,
	input	wire					reset,
	input	wire [word_width - 1:0]	D_IN,
	output	reg  [word_width - 1:0]	D_OUT,
	output	wire					will_overflow
);
wire [word_width - 1:0] load_flow = {load_flow[word_width - 2:0] & ~D_OUT[word_width - 2:0], count & load};
wire [word_width - 1:0] count_flow = {count_flow[word_width - 2:0] & D_OUT[word_width - 2:0], ~load_flow[0]};
wire inner_clk = clk & (count | load);
assign will_overflow = &(load_flow[0] ? ~D_OUT : D_OUT);
always @(posedge inner_clk) begin
	if (reset) begin
		D_OUT <= '0;
	end else begin
		D_OUT <= ~count & load ? D_IN : {D_OUT[word_width - 1:1] ^ (count_flow[word_width - 1:1] | load_flow[word_width - 1:1]), ~D_OUT[0]};
	end
end
endmodule
module counter_cs_forward #(
	parameter word_width
) (
	input	wire					clk,
	input	wire					action,
	input	wire					reset,
	input	wire [word_width - 1:0]	D_IN,
	output	reg  [word_width - 1:0]	D_OUT,
	output	wire					will_overflow
);
//action 0 - count, 1 - load
wire [word_width - 2:0] count_flow = {count_flow[word_width - 3:0] & D_OUT[word_width - 2:1], D_OUT[0]};
assign will_overflow = &D_OUT & ~action;
always @(posedge clk) begin
	if (reset) begin
		D_OUT <= '0;
	end else begin
		D_OUT <= action ? D_IN : {D_OUT[word_width - 1:1] ^ count_flow, ~D_OUT[0]};
	end
end
endmodule
module counter_cs_backward #(
	parameter word_width
) (
	input	wire					clk,
	input	wire					action,
	input	wire					reset,
	input	wire [word_width - 1:0]	D_IN,
	output	reg  [word_width - 1:0]	D_OUT,
	output	wire					will_overflow
);
//action 0 - count, 1 - load
wire [word_width - 2:0] load_flow = {load_flow[word_width - 3:0] | D_OUT[word_width - 2:1], D_OUT[0]};
assign will_overflow = ~(|D_OUT | action);
always @(posedge clk) begin
	if (reset) begin
		D_OUT <= '0;
	end else begin
		D_OUT <= action ? D_IN : {D_OUT[word_width - 1:1] ^ ~load_flow, ~D_OUT[0]};
	end
end
endmodule
//NOTE: it supports non 2^n outputs, so it won`t overgenerate
//WARNING: DO NOT SET output_width = 1
module decoder #(
	parameter output_width
) (
	input	wire [$clog2(output_width) - 1:0] select,
	output	wire [output_width - 1:0] out
);
localparam input_width = $clog2(output_width);
wire [input_width - 1:0] inversed_select = ~select;
genvar i;
genvar j;
generate
	for (i = 0; i < output_width; ++i) begin: decoded_output
		wire [input_width - 1:0] selection;
		for (j = 0; j < input_width; ++j) begin: selection_union
			assign selection[j] = i % (2 ** (j + 1)) >= 2 ** j ? select[j] : inversed_select[j];
		end
		assign out[i] = &selection;
	end
endgenerate
endmodule
module decoder_c #(
	parameter output_width
) (
	input	wire enable,
	input	wire [$clog2(output_width) - 1:0] select,
	output	wire [output_width - 1:0] out
);
wire [output_width - 1:0] raw_decoded;
decoder #(.output_width(output_width)) dec (
	.select(select),
	.out(raw_decoded)
);
assign out = raw_decoded & {output_width{enable}};
endmodule
//NOTE: it supports non 2^n inputs, so it won`t overgenerate
//WARNING: DO NOT SET input_width = 1
module encoder #(
	parameter input_width
) (
	input wire [input_width - 1:0] select,
	output wire	[$clog2(input_width) - 1:0] out
);
localparam output_width = $clog2(input_width);
genvar i;
genvar j;
generate
	for (i = 0; i < output_width; ++i) begin: encoded_output
		localparam unit_size = 2 ** i;
		localparam rest_width = input_width % (2 * unit_size);
		localparam full_width = (input_width - rest_width) / 2;
		localparam collector_size = full_width + (rest_width > unit_size ? rest_width % unit_size : 0);
		wire [collector_size - 1:0] collector;
		for (j = 0; j < collector_size; j = j + unit_size) begin: selection_union
			localparam target_start = j * 2 + unit_size;
			assign collector[`min(collector_size, j + unit_size) - 1:j] = select[`min(input_width, target_start + unit_size) - 1:target_start];
		end
		if (collector_size > 1) begin
			assign out[i] = |collector;
		end else begin
			assign out[i] = collector;
		end
	end
endgenerate
endmodule
module tri_state_buffer #(
	parameter word_width,
	parameter word_length
) (
	input	wire [word_length - 1:0][word_width - 1:0] in,
	input	wire [word_length - 1:0] en,
	output	wire [word_width - 1:0] out
);
genvar i;
generate
	for (i = 0; i < word_length; ++i) begin: buffer_unit
		assign out = en[i] ? in[i] : 'z;
	end
endgenerate
endmodule