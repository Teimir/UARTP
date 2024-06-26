module RX 
#(
    parameter CLK_FREQ = 100000000
)(
    input rx_line,
    input clk,
	 input [3:0] mode,
    output [7:0] data,
    output reg data_valid = 0
);

localparam start = 2'b00;
localparam read = 2'b01;
localparam stop = 2'b10;



wire [31:0] len_bit;
wire [31:0] half_len_bit;
reg [2:0] r = 3'b111;


reg [1:0] state = 2'b0;
reg [31:0] clock_cnt = 32'b0;
reg [4:0] bit_cnt = 4'b0;
reg prev_ss = 0;

reg [7:0] data_r = 'd0;


always @(posedge clk) begin
	r <= {r, rx_line};
end

always @(posedge clk) begin
    prev_ss <= r[2];
    case (state)
        start: begin
            data_valid <= 0;
            if (clock_cnt != 32'd0) clock_cnt <= clock_cnt + 32'd1;
				else if (r[2] == 0 && prev_ss == 1) clock_cnt <= 32'd1;
            if (clock_cnt == half_len_bit) begin
                state <= read;
                clock_cnt <= 32'd0;
                
            end
        end
        read: begin

            if (clock_cnt == len_bit) begin
                data_r <= {r[2], data_r[7:1]};
                bit_cnt <= bit_cnt + 4'd1;
                
                clock_cnt <= 32'd0;                
                if (bit_cnt == 4'd7) begin
                    bit_cnt <= 4'd0;
                    state <= stop;                
                end
            end
            else clock_cnt <= clock_cnt + 32'd1;
        end
        stop: begin
            if (clock_cnt >= len_bit[31:1] && r[2] == 1) begin
                clock_cnt <= 32'd0;
                state <= start;
                data_valid <= 1;
            end
            else clock_cnt <= clock_cnt + 32'd1;
        end
    endcase
end

assign data = (data_valid) ? data_r : 'd0; 
assign len_bit = (mode == 4'd0) ? (CLK_FREQ/4800 + (CLK_FREQ%4800!=0)) : //4800
					  (mode == 4'd1) ? (CLK_FREQ/9600 + (CLK_FREQ%9600!=0))  : //9600
					  (mode == 4'd2) ? (CLK_FREQ/115200 + (CLK_FREQ%115200!=0))   : //115200
					  //(mode == 4'd3) ? 32'd98    : //512000
					  (mode == 4'd3) ? (CLK_FREQ/256000 + (CLK_FREQ%25600!=0))    : //256000
					  (CLK_FREQ/9600 + (CLK_FREQ%9600!=0)) ; //9600 Default
assign half_len_bit = len_bit >> 1;

endmodule