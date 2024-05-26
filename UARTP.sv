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

wire [2:0] ins;

reg flag = 0;
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
	 .mode(4'd1)
);    


//Подключение модуля РХ
RX   
#(    
    .CLK_FREQ  (50000000)
)rx_inst(
    .rx_line   (rx),
    .clk       (clk),
    .data      (data_rx),
    .data_valid(data_rx_valid),
	 .mode(4'd1)
);

Fifo_UART RX_FIFO(
	.clock	(clk),
	.data		(data_rx),
	.rdreq	(!empty_fifo_rx && !full_fifo_tx),
	.wrreq	(data_rx_valid),
	.empty	(empty_fifo_rx),
	.full		(),
	.q			(fifo_data),
	.usedw	()
);

Fifo_UART TX_FIFO(
	.clock	(clk),
	.data		(fifo_data),
	.rdreq	(data_tx_ready),
	.wrreq	(!empty_fifo_rx && !full_fifo_tx),
	.empty	(empty_fifo_tx),
	.full		(full_fifo_tx),
	.q			(data),
	.usedw	()
);


CORE u0(
	.clk(flag ? clk : '0),
	.ins(ins)
);

always @(posedge clk) begin
	if (fifo_data == 8'hff) flag <= 1;
	if (!empty_fifo_tx && data_tx_ready) data_led[7:0] <= data[7:0];
	data_led[8] <= flag;
	data_led[9] <= rx;
end
endmodule