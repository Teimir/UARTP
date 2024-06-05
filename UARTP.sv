module UARTP(
	input clk,
	input btn,
	output led,
	output led2,
	output led3,
	output led4,
	output tx,
	input rx,
	output reg [9:0] data_led
);


// Регистры
wire [7:0] data; //Данные
wire data_tx_ready; //Сигнал, что готовы к отправке
wire data_rx_valid; //Сигнал, что получение завершено

wire empty_fifo_rx; //Если пустой буффер приёма
wire full_fifo_tx; //Если заполнен буффер отправки
wire empty_fifo_tx; //Если пустой буффер отправки

wire [7:0] fifo_data; //Данные между фифо
wire [7:0]data_rx; //Данные с рх



reg flag = 0;  
//UART wires
wire [7:0] rx_used;	//сколько очереди занято под RX
wire [7:0] tx_used;	//сколько очереди занято под TX
reg  [3:0] rx_mode = 4'd1;
reg  [3:0] tx_mode = 4'd1;
wire [7:0] data_from_fifo;
wire [7:0] data_to_fifo;
wire [31:0] uart_all_data_out = {
	{
		tx_mode,
		rx_mode
	},
	data_from_fifo,
	tx_used,
	rx_used
};
//Подключение модуля RХ
RX   
#(    
    .CLK_FREQ  (50000000)
)rx_inst(
    .rx_line	(rx),
    .clk		(clk),
    .data		(data_rx),
    .data_valid	(data_rx_valid),
	.mode(rx_mode)
);

Fifo_UART RX_FIFO(
	.clock	(clk),
	.data	(data_rx),
	.rdreq	(UART_OP[1] & ~UART_OP[0]),
	.wrreq	(data_rx_valid),
	.empty	(empty_fifo_rx),
	.full	(),
	.q		(data_from_fifo),
	.usedw	(rx_used)
);
//Подключение модуля ТХ
TX 
#(
    .CLK_FREQ  (50000000)
)TX_inst(
    .data_in    (data),
    .data_valid (!empty_fifo_tx),
    .data_ready (data_tx_ready),
    .clk        (clk),
    .tx_line    (tx),
	.mode		(tx_mode)
);  
Fifo_UART TX_FIFO(
	.clock	(clk),
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
	.clock		(clk),
	.data		(data_to_mem),
	.wren		(RAM_WE),
	.q			(ram_data_out)
);
//CORE
wire [31:0] data_to_mem;
wire [12:0] ram_addres;
wire [1:0] UART_OP;
CORE u0(
	.clk(flag & clk),
	.data_to_mem(data_to_mem),
	.ram_addres(ram_addres),
	.RAM_WE(RAM_WE),
	.ram_data_out(ram_data_out),
	.uart_data_out(uart_all_data_out),
	.UART_OP(UART_OP)
);

always @(posedge clk) begin
	if (UART_OP == 2'b1) begin
		{tx_mode, rx_mode} <= data_to_mem[7:0];
	end
	if (data_rx == 8'hff) flag <= 1;
	if (!empty_fifo_tx && data_tx_ready) data_led[7:0] <= data[7:0];
	data_led[8] <= flag;
	data_led[9] <= rx;
end
endmodule