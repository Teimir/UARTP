module UARTP(
	input clk_i,
	input btn,
	output led,
	output led2,
	output reg led3 = 0,
	output reg led4 = 0,
	output tx,
	input rx,
	output reg [9:0] data_led = 10'd0
);


// Регистры
wire [7:0] data; //Данные
wire data_tx_ready; //Сигнал, что готовы к отправке
wire data_rx_valid; //Сигнал, что получение завершено

wire full_fifo_rx; //Если заполнен буффер приёма
wire empty_fifo_rx; //Если пустой буффер приёма
wire full_fifo_tx; //Если заполнен буффер отправки
wire empty_fifo_tx; //Если пустой буффер отправки

wire [7:0] fifo_data; //Данные между фифо
wire [7:0]data_rx; //Данные с рх


wire clk,clk2;

MPLL u1(
	.inclk0(clk_i),
	.c0(clk2)
);

reg [31:0] ac = 32'd0;
reg [31:0] ac2 = 32'd0;

assign clk = clk2;

reg flag = 0;  
reg [1:0] sel_clk = 0;
wire clk0;

//UART wires
wire [7:0] rx_used;	//сколько очереди занято под RX
wire [7:0] tx_used;	//сколько очереди занято под TX
reg  [3:0] rx_mode = 4'd1;
reg  [3:0] tx_mode = 4'd1;
wire [7:0] data_from_fifo;
wire [7:0] data_to_fifo;
wire [1:0][31:0] uart_all_data_out = {
	{
		24'b0,
		data_from_fifo
	},
	{
		{
			tx_mode,
			rx_mode
		},
		data_from_fifo,
		tx_used,
		rx_used
	}
};


//CLK-PLL
MainCLKPLL CLPLL(
	.inclk0	(clk_inp),
	.c0		(clk0)
);



//Подключение модуля RХ
RX   
#(    
    .CLK_FREQ  (60000000)
)rx_inst(
    .rx_line		(rx),
    .clk				(clk0),
    .data			(data_rx),
    .data_valid	(data_rx_valid),
	.mode				(rx_mode)
);

Fifo_UART RX_FIFO(
	.clock			(clk0),
	.data				(data_rx),
	.rdreq			(UART_OP[1] & ~UART_OP[0]),
	.wrreq			(data_rx_valid),
	.empty			(empty_fifo_rx),
	.full				(),
	.q					(data_from_fifo),
	.usedw			(rx_used)
);
//Подключение модуля ТХ
TX 
#(
    .CLK_FREQ  (60000000)
)TX_inst(
    .data_in    (data),
    .data_valid (!empty_fifo_tx),
    .data_ready (data_tx_ready),
    .clk        (clk0),
    .tx_line    (tx),
	.mode		(tx_mode)
);  
Fifo_UART TX_FIFO(
	.clock	(clk0),
	.data	(data_to_mem),
	.rdreq	(data_tx_ready),
	.wrreq	(&UART_OP),
	.empty	(empty_fifo_tx),
	.full	(full_fifo_tx),
	.q		(data),
	.usedw	(tx_used)
);
//RAM
wire [31:0] ram_data_out;
MEMORY RAM(
	.address	(ram_addres),
	.clock		(clk0),
	.data		(data_to_mem),
	.wren		(RAM_WE),
	.q			(ram_data_out)
);
//CORE
wire [31:0] data_to_mem;
wire [12:0] ram_addres;
wire [1:0] UART_OP;
CORE u0(
	.clk(flag & clk0),
	.data_to_mem(data_to_mem),
	.ram_addres(ram_addres),
	.RAM_WE(RAM_WE),
	.ram_data_out(ram_data_out),
	.uart_data_out(uart_all_data_out[UART_OP[1]]),
	.UART_OP(UART_OP)
);

always @(posedge clk) begin
	if (ac == 32'd100000000) begin
		led3 <= ~led3;
		ac <= 0;
	end
	else begin
		ac <= ac + 32'd1;
	end

	if (UART_OP == 2'b1) begin
		{tx_mode, rx_mode} <= data_to_mem[7:0];
	end
	if (data_rx == 8'hff) flag <= 1;
	if (!empty_fifo_tx && data_tx_ready) data_led[7:0] <= data[7:0];
	data_led[8] <= flag;
	data_led[9] <= rx;
end



always @(posedge clk_i) begin
	if (ac2 == 32'd50000000) begin
		led4 <= ~led4;
		ac2 <= 0;
	end
	else begin
		ac2 <= ac2 + 32'd1;
	end
end



assign led = ~empty_fifo_rx;
assign led2 = ~empty_fifo_tx;




endmodule