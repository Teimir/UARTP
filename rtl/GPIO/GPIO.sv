module GPIO#(
	parameter width_pin = 2
)
(
	input clk,
	inout [width_pin-1:0] pin,
	input [31:0] mode,
	input [31:0] data,
	input valid,
	output [31:0] data_o
);

//wire [31:0] data_o_wire;

reg [31:0] mode_reg = 32'h0; // 0 - read, 1 - write
reg [31:0] data_reg = 32'd3;

always @(posedge clk)begin
	if (valid) begin
		mode_reg <= mode;
		data_reg <= data;
	end
	//data_o <= data_o_wire;
end

genvar i;
generate
	for (i = 0; i < width_pin; i++) begin : iobuff_b
		alt_iobuf my_iobuf (
				.i			(data_reg[i]),
				.oe		(mode_reg[i]), 
				.o			(data_o[i]),
				.io		(pin[i])
		);
	end

//defparam <instance_name>.io_standard = "1.8 V"; 
//defparam <instance_name>.current_strength  = "maximum current"; 
//defparam <instance_name>.slow_slew_rate = "off"; 
//defparam <instance_name>.enable_bus_hold = "on";
//defparam <instance_name>.weak_pull_up_resistor = "off";
//defparam <instance_name>.termination = "series 50 ohms"; 
	
	
//defparam <instance_name>.io_standard = "2.5 V"; 
//defparam <instance_name>.location = "IOBANK_2";
//defparam <instance_name>.enable_bus_hold = "on";
//defparam <instance_name>.weak_pull_up_resistor = "off";
//defparam <instance_name>.termination = "parallel 50 ohms with calibration";
endgenerate


endmodule