module UARTP(
	input clk,
	input btn,
	output led,
	output led2,
	output led3,
	output led4,
	output tx,
	input rx
);


// Регистры
wire [7:0] data; //Данные
reg  data_tx_valid = '0; //Сигнал к отправке на ТХ
wire data_tx_ready; //Сигнал, что готовы к отправке
wire data_rx_valid; //Сигнал, что получение завершено
wire [7:0]data_rx; //Данные с рх
(* keep="true" *)
reg [3:0] u_mode = 4'd1;
reg [2:0] r = 3'b111;


wire write2;
wire [31:0] operand;
wire [4:0] operand_addr;
wire [31:0] PC_R;
wire [4:0]  PC_ADRR;
wire reset;

//Параметры конечного автомата
localparam wait_data = 0; 
localparam write = 1;



reg sett = 0;

//Регистр конечного автомата
reg state = wait_data; 

always @(posedge clk) begin
	if(btn == 0) u_mode <= 4'd1;
	if (data_rx_valid) begin //Если данные получены - переносим в буфер и отправляем
		if (data_rx == 8'hff) sett <= '1;
		else if (sett && data_rx[7:4] == 4'hf) begin
			u_mode <= data_rx[3:0];
			sett <= '0;
		end
	else sett <= '0;
	end
	if (data_tx_ready && data_tx_valid) begin //Если данные готовы к отправке и корректны, сбрасываем корректность и переходим к ожиданию
		data_tx_valid <= 0;
	end
	else begin
		if (data_tx_ready) begin //Готовы к отправке
			data_tx_valid <= 1;
		end
	end
	
end



always @(posedge clk) begin
	r <= {r, rx};
end


fifo fifo_inst(
  .clk(clk),        // тактовый сигнал
  .reset(btn == 0),      // сигнал сброса
  .write_enable(data_rx_valid),  // сигнал разрешения записи
  .read_enable(data_tx_ready),   // сигнал разрешения чтения
  .data_in(data_rx),       // входные данные
  .data_out(data),     // выходные данные

  .empty(~led),       // сигнал пустого буфера
  .full(~led2)         // сигнал заполненного буфера
);



//Подключение модуля ТХ
TX 
#(
    .CLK_FREQ  (50000000)
)TX_inst(
    .data_in    (data),
    .data_valid (data_tx_valid),
    .data_ready (data_tx_ready),
    .clk        (clk),
    .tx_line    (tx),
	 .mode(u_mode)
);    


//Подключение модуля РХ
RX   
#(    
    .CLK_FREQ  (50000000)
)rx_inst(
    .rx_line   (r[2]),
    .clk       (clk),
    .data      (data_rx),
    .data_valid(data_rx_valid),
	 .mode(u_mode)
);


//Вывод состояния на диоды
assign led3 = ~u_mode[0];
assign led4 = ~u_mode[1];
endmodule