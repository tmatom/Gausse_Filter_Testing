
//========================================================================= //
// ------------------------------------------------------------------------ //
// Project Name     : TEST_TASK
// File Name        : tb_gauss_filter.sv
// ------------------------------------------------------------------------ //
// Engineer         : Tolkachev Maxim
// Create Date      : 
// Last modified    :
// ------------------------------------------------------------------------ //
// ======================================================================== //
`timescale 1ns/1ps

`define NULL 0

module gauss_filter_tb;
    


    integer valid_data_count,file_read;
    integer bytes_read;
    integer file_bin;

    string filename_RAW  = "../files/alena_8bit.raw"; //"../files/alena_8bit.raw";

    // Параметры
    localparam WIDTH = 640;
    localparam HEIGHT = 512;
    localparam DATA_WIDTH = 8;
    localparam CLK_PERIOD = 10; // 100 МГц
    
    // Сигналы
    reg clk;
    reg rst_i;
    
    // AXIS Slave
    reg [DATA_WIDTH-1:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;
    
    // AXIS Master
    wire [DATA_WIDTH-1:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    reg m_axis_tready;
    
    // Тестовые данные
    reg [15:0] input_data [0:WIDTH*HEIGHT-1];
    reg [7:0] expected_output [0:WIDTH*HEIGHT-1];
    integer input_ptr, output_ptr;
    integer errors;
    
    // Экземпляр DUT
    gauss_filter_1x5 #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_i(rst_i),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );
    
    // Генерация тактового сигнала
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Инициализация
    initial begin
        // Инициализация сигналов
        clk = 0;
        rst_i = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
        input_ptr = 0;
        output_ptr = 0;
        valid_data_count = 0;


    file_bin = $fopen(filename_RAW, "rb");  // Бинарное чтение
    
    if (file_bin == 0) begin
        $display("Error: Cannot open binary file %s", filename_RAW);
        $finish;
    end
    
    // // Чтение всего файла в массив
    // bytes_read = $fread(input_data, file_bin);
    // $fclose(file_bin);
    // // Рассчитываем количество прочитанных 16-битных слов
    // valid_data_count = bytes_read / 2;  // 2 байта на каждый 16-битный элемент
    // $display("Read %0d bytes from file", bytes_read);
    // $display("Loaded %0d 16-bit elements", valid_data_count);
    // if (valid_data_count == 0) begin
    //     $display("Error: No data in file %s", filename_RAW);
    //     $finish;
    // end
    
    while (!$feof(file_bin)) begin
        logic [7:0] byte1, byte2;
        integer status;
        
        // Читаем первый байт
        status = $fread(byte1, file_bin);
        if (status != 1) break;
        
        // Читаем второй байт (если есть)
        status = $fread(byte2, file_bin);
        if (status != 1) begin
            // Если файл имеет нечетное количество байтов
            input_data[valid_data_count] = {8'h00,byte2};  // Дополняем нулем
            valid_data_count++;
            break;
        end
        
        // Объединяем два байта в 16-битное слово
        input_data[valid_data_count] = {8'h00, byte2};
        valid_data_count++;
        $display("%h, %h", byte1,byte2);
    end


    $fclose(file_bin);
    $display("Loaded %d elements from binary file", valid_data_count);
    

    // file_read = $fopen(filename_RAW,"r");

    // if (file_read == `NULL) begin
    //   $display("file_write handle was NULL");
    //   $finish;
    // end



        
    //     // Загрузка тестовых данных
    //     $readmemh(filename_RAW, input_data);


    //     for (int i = 0; i < WIDTH*HEIGHT; i++) begin
    //         if (input_data[i] !== 16'hxxxx) begin
    //             valid_data_count++;
    //         end
    //     end

    //     $display("Load %d elements\n", valid_data_count);

    //     if (valid_data_count==0)
    //     begin
    //         $display("There is`t data in file alena_8bit.raw");
    //         $finish;
    //     end
        
        // Сброс
        #100;
        rst_i = 1;
        #100;
        rst_i = 0;

        // Запуск теста
         fork
            send_data_task();
            receive_data_task();
            timeout_checker();
         join
        
        // Завершение симуляции
        #1000;
        $finish;
    end
    


// always @(posedge clk) 
//   begin
//     if(rst_i) 
//     begin        
//         test_counter <= 0;
//     end else 
//     begin
//         // read_data_complex_sample_i();
//         read_data_complex_sample_mem();

//     end
//   end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Задача для отправки данных - перепись заного
    task send_data_task;
        integer row, col;
        integer idx;
        begin
            $display("Begin send task...");
            
            // Ожидание сброса
            // wait(rst_i == 1'b1);
            // @(posedge clk);
            // #1;
            
            for (row = 0; row < HEIGHT; row = row + 1) begin
                $display("Send data of %0d/%0d row", row+1, HEIGHT);
                
                for (col = 0; col < WIDTH; col = col + 1) begin
                    idx = row * WIDTH + col;
                    
                    // Установка данных
                    s_axis_tdata = input_data[idx];
                    s_axis_tvalid = 1'b1;
                    s_axis_tlast = (col == WIDTH-1) ? 1'b1 : 1'b0;
                    
                    // Ждем такт
                    @(posedge clk);
                    #1;
                    
                    // В реальном интерфейсе приемник может не всегда быть готов,
                    // но по условию мы игнорируем ready
                end
                
                // Пауза между строками (100 тактов)
                s_axis_tvalid = 1'b0;
                s_axis_tlast = 1'b0;
                repeat(100) @(posedge clk);
            end
            
            s_axis_tdata = 8'd0;
            s_axis_tvalid = 1'b0;
            s_axis_tlast = 1'b0;
            $display("Sending task is complete!");
        end
    endtask

 // Задача для приема данных 
    task receive_data_task;
        reg [7:0] received_value;
        reg [7:0] expected_value;
        integer row, col;
        integer idx;
        begin
            $display("Ожидание выходных данных...");
            
            // Ждем начала вывода
            wait(m_axis_tvalid == 1'b1);
            @(posedge clk);
            #1;
            
            row = 0;
            col = 0;
            
            while (output_ptr < WIDTH * HEIGHT) begin
                if (m_axis_tvalid && m_axis_tready) begin
                    // Получаем данные
                    received_value = m_axis_tdata;
                    
                    // Сохраняем для отладки
                    expected_output[output_ptr] = received_value;
                    
                    // Рассчитываем ожидаемое значение (грубая проверка)
                    idx = output_ptr;
                    if (col >= 2 && col < WIDTH-2) // Игнорируем границы из-за зеркалирования
                        expected_value = input_data[idx];
                    else
                        expected_value = 8'hXX; // Граничные пиксели - не проверяем
                    
                    // Проверка
                    if (expected_value !== 8'hXX && received_value !== expected_value) begin
                        // Допускаем небольшую погрешность из-за фильтрации
                        if ($abs(received_value - expected_value) > 10) begin
                            $display("Error on picsel [%0d,%0d]: get %0d, wait ~%0d", 
                                     row, col, received_value, expected_value);
                            errors = errors + 1;
                        end
                    end
                    
                    // Отладочный вывод
                    if (col == 0 || col == WIDTH-1 || output_ptr % (WIDTH*10) == 0) begin
                        $display("Picsel [%0d,%0d]: in=%0d, out=%0d", 
                                 row, col, input_data[idx], received_value);
                    end
                    
                    output_ptr = output_ptr + 1;
                    col = col + 1;
                    
                    if (col == WIDTH) begin
                        col = 0;
                        row = row + 1;
                        if (m_axis_tlast)
                            $display("End row %0d", row);
                    end
                    
                    // Ждем следующий валидный выход
                    @(posedge clk);
                    #1;
                end
                else begin
                    // Нет валидных данных - ждем
                    @(posedge clk);
                    #1;
                end
            end
            
            $display("Receive data finished");
        end
    endtask
    
    // Задача для мониторинга
    task monitor_task;
        integer last_state;
        begin
            $display("Monitor start...");
            last_state = -1;
            
            forever begin
                @(posedge clk);
                
                // Вывод при изменении состояния
                if (dut.state !== last_state) begin
                    $display("Время %0t: Состояние изменилось %0d -> %0d", 
                             $time, last_state, dut.state);
                    last_state = dut.state;
                end
                
                // Вывод при начале/конце строки
                if (s_axis_tvalid && s_axis_tlast)
                    $display("Время %0t: Конец входной строки", $time);
                    
                if (m_axis_tvalid && m_axis_tlast && m_axis_tready)
                    $display("Время %0t: Конец выходной строки", $time);
            end
        end
    endtask
    
    // Таймаут проверки
    task timeout_checker;
        begin
            #5000000; // 5 мс симуляции
            $display("ТАЙМАУТ: Симуляция слишком долгая!");
            $display("Обработано пикселей: %0d из %0d", output_ptr, WIDTH*HEIGHT);
            $finish;
        end
    endtask

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Задача для отправки данных
    task send_data;
        integer row, col;
        begin
            row = 0;
            col = 0;
            // Ожидание сброса
            @(posedge rst_i);
            #100;
            $stop;
            for (row = 0; row < HEIGHT; row = row + 1) begin
                for (col = 0; col < WIDTH; col = col + 1) begin
                    // Установка данных
                    s_axis_tdata = input_data[row*WIDTH + col][7:0]; // Используем младшие 8 бит
                    s_axis_tvalid = 1;
                    s_axis_tlast = (col == WIDTH-1);
                   
                    
                    // Пауза между пикселями
                    @(posedge clk);
                    #1;
                end
                
                // Пауза между строками (100 тактов)
                s_axis_tvalid = 0;
                s_axis_tlast = 0;
                repeat(100) @(posedge clk);
            end
            s_axis_tvalid = 0;
        end
    endtask
    
    // Задача для приема данных
    task receive_data;
        begin
            forever begin
                @(posedge clk);
                if (m_axis_tvalid && m_axis_tready) begin
                    // Сохранение выходных данных
                    $display("Output pixel %d: %h", output_ptr, m_axis_tdata);
                    output_ptr = output_ptr + 1;
                    
                    if (m_axis_tlast) begin
                        $display("End of line received");
                    end
                end
            end
        end
    endtask
    
    // Мониторинг
    task monitor;
        begin
            forever begin
                @(posedge clk);
                $monitor("Time: %0t, State: %d, Col: %d, Row: %d, Output: %h", 
                         $time, dut.state, dut.col_counter, dut.row_counter, m_axis_tdata);
            end
        end
    endtask
    
    // Dump VCD
    initial begin
        $dumpfile("gauss_filter.vcd");
        $dumpvars(0, gauss_filter_tb);
    end
    
endmodule