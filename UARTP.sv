module UARTP(
	input clk,
	input btn,
	output led,
	output led2,
	output led3,
	output tx,
	input rx
);


// Регистры
reg [7:0] data = 8'haa; //Данные
reg  data_tx_valid = '0; //Сигнал к отправке на ТХ
wire data_tx_ready; //Сигнал, что готовы к отправке
wire data_rx_valid; //Сигнал, что получение завершено
wire [7:0]data_rx; //Данные с рх
(* keep="true" *)
reg [3:0] u_mode = 4'd1;


//Параметры конечного автомата
localparam wait_data = 2'b00; 
localparam write = 2'b01;

reg sett = 0;

//Регистр конечного автомата
reg [1:0] state = wait_data; 

always @(posedge clk) begin
	case(state) //Конечный автомат
		wait_data: begin //Описание состояния ожидания
			if (data_rx_valid) begin //Если данные получены - переносим в буфер и отправляем
				data <= data_rx;
				if (data_rx == 8'hff) sett <= '1;
				else if (sett && data_rx[7:4] == 4'hf) begin
					u_mode <= data_rx[3:0];
					sett <= '0;
					end
				else sett <= '0;
				state <= write;
			end
		end
		write: begin //Описание состояния отправки
			if (data_tx_ready && data_tx_valid) begin //Если данные готовы к отправке и корректны, сбрасываем корректность и переходим к ожиданию
					data_tx_valid <= 0;
					state <= wait_data;
			end
			else begin
				if (data_tx_ready) begin //Готовы к отправке
				data_tx_valid <= 1;
				end
			end
		end
	endcase
end


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
    .rx_line   (rx),
    .clk       (clk),
    .data      (data_rx),
    .data_valid(data_rx_valid),
	 .mode(u_mode)
);

//Вывод состояния на диоды
assign led = ~state[0];
assign led2 = ~u_mode;
assign led3 = ~sett;
endmodule