module UARTP(
	input clk_i,
	input [1:0] btn,
	output led,
	output led2,
	output reg led3 = 0,
	output led4,
	output tx,
	input rx,
	output reg [7:0] data_led = 10'd0,
	inout [1:0] gpio
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
//GPIO wires
wire gpio_core_writes = &GPIO_OP;
wire [31:0] gpio_data_out;
wire gpio_valid_out;
reg [31:0] gpio_data;
reg is_gpio_inputing;
wire [1:0][31:0] gpio_all_data_out = {
	{32{~is_gpio_inputing}},
	gpio_data
};

//Подключение модуля RХ
RX   
#(    
    .CLK_FREQ  (60000000)
)rx_inst(
    .rx_line		(rx),
    .clk				(clk),
    .data			(data_rx),
    .data_valid	(data_rx_valid),
	.mode				(rx_mode)
);

Fifo_UART RX_FIFO(
	.clock			(clk),
	.data				(data_rx),
	.rdreq			(UART_OP[1] & ~UART_OP[0]),
	.wrreq			(data_rx_valid),
	.empty			(empty_fifo_rx),
	.full				(),
	.q					(data_from_fifo),
	.usedw			(rx_used)
);
//Подключение модуля ТХ
reg [7:0] data_gpio = 8'h00;
reg valid_gpio = 0;
TX 
#(
    .CLK_FREQ  (60000000)
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
wire [1:0] GPIO_OP;
CORE u0(
	.ena(flag),
	.clk(clk),
	.data_to_mem(data_to_mem),
	.ram_addres(ram_addres),
	.RAM_WE(RAM_WE),
	.ram_data_out(ram_data_out),
	.uart_data_out(uart_all_data_out[UART_OP[1]]),
	.UART_OP(UART_OP),
	.gpio_data_out(gpio_all_data_out[GPIO_OP[1]]),
	.GPIO_OP(GPIO_OP)
);





GPIO #(.width_pin($size(gpio))) u2 (
	.clk(clk),
	.pin(gpio),
	.mode(gpio_all_data_out[1]),
	.data(gpio_data),
	.valid('1),
	.data_o(gpio_data_out)
);





always @(posedge clk) begin
	if (ac == 32'd120000000) begin
		led3 <= ~led3;
		ac <= 0;
	end
	else begin
		ac <= ac + 32'd1;
	end

	if (UART_OP == 2'b1) begin
		{tx_mode, rx_mode} <= data_to_mem[7:0];
	end
	if ((data_rx == 8'hff) && (data_rx_valid)) flag <= 1;
	else if (flag == 1) flag <= 0;
	if (!empty_fifo_tx && data_tx_ready) data_led <= data;
	//GPIO clk
	if (is_gpio_inputing | gpio_core_writes) begin
		gpio_data <= gpio_core_writes ? gpio_data_out : data_to_mem;
	end
	if (GPIO_OP == 2'b01) begin
		is_gpio_inputing = |data_to_mem;
	end
end

assign led = ~empty_fifo_rx;
assign led2 = ~empty_fifo_tx;

endmodule