module gauss_filter_1x5 #(
    parameter WIDTH = 640,
    parameter HEIGHT = 512,
    parameter DATA_WIDTH = 8,
    parameter COEFF_WIDTH = 16,
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
) (
    // Clock and Reset
    input wire clk,
    input wire rst_i,
    
    // AXIS Slave Interface (входной поток)
    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    
    // AXIS Master Interface (выходной поток)
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    input wire m_axis_tready
);
    
    // Коэффициенты фильтра в формате Q8.8
    localparam [COEFF_WIDTH-1:0] COEFF_0 = 16'h0007;  // 0.028087
    localparam [COEFF_WIDTH-1:0] COEFF_1 = 16'h003C;  // 0.23431
    localparam [COEFF_WIDTH-1:0] COEFF_2 = 16'h007A;  // 0.475206
    localparam [COEFF_WIDTH-1:0] COEFF_3 = 16'h003C;  // 0.23431
    localparam [COEFF_WIDTH-1:0] COEFF_4 = 16'h0007;  // 0.028087
    
    // Line Buffers (3 строки: предыдущая, текущая, следующая)
    reg [DATA_WIDTH-1:0] line_buffer_0 [0:WIDTH-1];
    reg [DATA_WIDTH-1:0] line_buffer_1 [0:WIDTH-1];
    reg [DATA_WIDTH-1:0] line_buffer_2 [0:WIDTH-1];
    
    // Указатели записи/чтения
    integer write_ptr;
    integer read_ptr;
    
    // Регистры для хранения окна 1x5
    reg [DATA_WIDTH-1:0] window [0:4];
    reg [DATA_WIDTH-1:0] window_reg [0:4];
    
    // Состояния конечного автомата
    reg [2:0] state;
    reg [10:0] col_counter;
    reg [9:0] row_counter;
    
    // Сигналы управления
    reg buffer_valid;
    reg processing_en;
    reg output_valid;
    reg output_last;
    
    // Сигналы данных
    reg [DATA_WIDTH-1:0] output_data;
    
    // Временные переменные для умножений
    reg [COEFF_WIDTH+DATA_WIDTH-1:0] mult [0:4];
    reg [COEFF_WIDTH+DATA_WIDTH+2:0] sum;
    
    // Параметры состояния
    localparam IDLE = 3'b000;
    localparam FILL_BUFFER = 3'b001;
    localparam PROCESSING = 3'b010;
    localparam FLUSH = 3'b011;
    
    // Всегда готовы принимать данные (игнорируем ready)
    assign s_axis_tready = 1'b1;
    
    // Выходные сигналы AXIS
    assign m_axis_tdata = output_data;
    assign m_axis_tvalid = output_valid;
    assign m_axis_tlast = output_last;
    
    // Функция для зеркалирования адресов
    function integer mirror_index;
        input integer index;
        input integer max_index;
        begin
            if (index < 0)
                mirror_index = -index - 1;
            else if (index >= max_index)
                mirror_index = 2*max_index - index - 1;
            else
                mirror_index = index;
        end
    endfunction
    
    // Основной процесс
    always @(posedge clk) begin
        if (rst_i) begin
            // Сброс всех регистров
            state <= IDLE;
            col_counter <= 0;
            row_counter <= 0;
            write_ptr <= 0;
            read_ptr <= 0;
            processing_en <= 0;
            output_valid <= 0;
            output_last <= 0;
            output_data <= 0;
            
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                line_buffer_0[i] <= 0;
                line_buffer_1[i] <= 0;
                line_buffer_2[i] <= 0;
            end
            
            for (integer i = 0; i < 5; i = i + 1) begin
                window[i] <= 0;
                window_reg[i] <= 0;
            end
            
            sum <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid) begin
                        state <= FILL_BUFFER;
                        // Заполняем первую строку
                        line_buffer_0[write_ptr] <= s_axis_tdata;
                        write_ptr <= write_ptr + 1;
                        col_counter <= 1;
                    end
                end
                
                FILL_BUFFER: begin
                    if (s_axis_tvalid) begin
                        line_buffer_0[write_ptr] <= s_axis_tdata;
                        write_ptr <= write_ptr + 1;
                        col_counter <= col_counter + 1;
                        
                        if (s_axis_tlast) begin
                            // Конец строки
                            row_counter <= row_counter + 1;
                            write_ptr <= 0;
                            col_counter <= 0;
                            
                            if (row_counter == 2) begin
                                // Заполнили 3 строки, можно начинать обработку
                                state <= PROCESSING;
                                processing_en <= 1;
                                read_ptr <= 2; // Начинаем с 3-го пикселя для зеркалирования
                            end
                        end
                    end
                end
                
                PROCESSING: begin
                    if (processing_en) begin
                        // Формируем окно 1x5 с зеркалированием
                        // Верхний ряд (строка 0)
                        window[0] <= line_buffer_0[mirror_index(read_ptr-2, WIDTH)];
                        window[1] <= line_buffer_0[mirror_index(read_ptr-1, WIDTH)];
                        window[2] <= line_buffer_0[read_ptr];
                        window[3] <= line_buffer_0[mirror_index(read_ptr+1, WIDTH)];
                        window[4] <= line_buffer_0[mirror_index(read_ptr+2, WIDTH)];
                        
                        // Сдвигаем окно в регистры для конвейерной обработки
                        for (integer i = 0; i < 5; i = i + 1) begin
                            window_reg[i] <= window[i];
                        end
                        
                        // Выполняем умножения
                        for (integer i = 0; i < 5; i = i + 1) begin
                            mult[i] <= window_reg[i] * 
                                      ((i == 0) ? COEFF_0 :
                                       (i == 1) ? COEFF_1 :
                                       (i == 2) ? COEFF_2 :
                                       (i == 3) ? COEFF_3 : COEFF_4);
                        end
                        
                        // Суммирование
                        sum <= mult[0] + mult[1] + mult[2] + mult[3] + mult[4];
                        
                        // Нормализация (деление на 256) и отсечение
                        output_data <= (sum[COEFF_WIDTH+DATA_WIDTH-1:FRAC_WIDTH] > 255) ? 
                                       8'hFF : sum[COEFF_WIDTH+DATA_WIDTH-1:FRAC_WIDTH];
                        
                        // Управление выходным интерфейсом
                        output_valid <= 1;
                        output_last <= (read_ptr == WIDTH-1);
                        
                        // Переход к следующему пикселю
                        if (read_ptr == WIDTH-1) begin
                            read_ptr <= 0;
                            // Сдвигаем line buffers
                            for (integer i = 0; i < WIDTH; i = i + 1) begin
                                line_buffer_0[i] <= line_buffer_1[i];
                                line_buffer_1[i] <= line_buffer_2[i];
                            end
                            
                            if (row_counter == HEIGHT-1) begin
                                // Последняя строка
                                state <= FLUSH;
                                processing_en <= 0;
                            end
                            row_counter <= row_counter + 1;
                        end else begin
                            read_ptr <= read_ptr + 1;
                        end
                        
                        // Запись новой строки
                        if (s_axis_tvalid && !s_axis_tlast) begin
                            line_buffer_2[write_ptr] <= s_axis_tdata;
                            write_ptr <= write_ptr + 1;
                        end else if (s_axis_tvalid && s_axis_tlast) begin
                            line_buffer_2[write_ptr] <= s_axis_tdata;
                            write_ptr <= 0;
                        end
                    end
                end
                
                FLUSH: begin
                    // Обработка оставшихся строк в буфере
                    output_valid <= 0;
                    output_last <= 0;
                    state <= IDLE;
                    row_counter <= 0;
                end
            endcase
        end
    end
    
endmodule