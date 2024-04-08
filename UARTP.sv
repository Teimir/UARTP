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
reg [7:0] data = 8'haa; //Данные
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
	if(btn == 0) u_mode <= 4'd0;
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



always @(posedge clk) begin
	r <= {r, rx};
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
    .rx_line   (r[2]),
    .clk       (clk),
    .data      (data_rx),
    .data_valid(data_rx_valid),
	 .mode(u_mode)
);


core
#(
	.word_width(32)
) core_inst(
	.write(write2),
	.clk(clk),
	.operand(operand),
	.operand_addr(operand_addr),
	.reset(reset),
	.PC_R(PC_R),
	.PC_ADRR(PC_ADRR)
);

memory
#(
	.word_width(32)
) mem_inst(
	.write(write2),
	.clk(clk),
	.operand(operand),
	.operand_addr(operand_addr),
	.PC_R(PC_R),
	.PC_ADRR(PC_ADRR)
);

//Вывод состояния на диоды
assign led = ~state;
assign led2 = ~sett;
assign led3 = ~u_mode[0];
assign led4 = ~u_mode[1];
endmodule