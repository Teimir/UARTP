module fifo (
  input wire clk,        // тактовый сигнал
  input wire reset,      // сигнал сброса

  input wire write_enable,  // сигнал разрешения записи
  input wire read_enable,   // сигнал разрешения чтения
  input wire data_in,       // входные данные
  output reg data_out,     // выходные данные

  output wire empty,       // сигнал пустого буфера
  output wire full         // сигнал заполненного буфера
);

  // Параметры FIFO
  parameter FIFO_DEPTH = 1;     // глубина FIFO

  // Внутренние сигналы и регистры
  reg [7:0] fifo[FIFO_DEPTH-1:0];  // регистры FIFO
  reg [3:0] write_pointer;         // указатель записи
  reg [3:0] read_pointer;          // указатель чтения
  reg [3:0] count;                 // счетчик элементов
  reg empty_reg, full_reg;         // регистры состояния

  // Логика FIFO
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Сброс FIFO
      write_pointer <= 0;
      read_pointer <= 0;
      count <= 0;
      empty_reg <= 1;
      full_reg <= 0;
    end else begin
      // Запись данных
      if (write_enable && !full_reg) begin
        fifo[write_pointer] <= data_in;
        write_pointer <= write_pointer + 1;
        count <= count + 1;
        empty_reg <= 0;
        if (count == FIFO_DEPTH - 1)
          full_reg <= 1;
      end

      // Чтение данных
      if (read_enable && !empty_reg) begin
        data_out <= fifo[read_pointer];
        read_pointer <= read_pointer + 1;
        count <= count - 1;
        full_reg <= 0;
        if (count == 1'h0)
          empty_reg <= 1;
      end
    end
  end

  // Выходные сигналы состояния FIFO
  assign empty = empty_reg;
  assign full = full_reg;

endmodule