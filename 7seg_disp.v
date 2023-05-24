`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/10 22:31:29
// Design Name: 
// Module Name: 7seg_disp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_module(
        input wire CLK100MHZ
        , input wire ck_rst
        , input rx
        , output wire [3:0] ja
        , output wire [3:0] jb
    );

    wire [7:0] disp_number;
    wire [3:0] disp_number_digit1;
    wire [3:0] disp_number_digit2;
    wire [6:0] disp_signal;
    wire [6:0] disp_signal_digit1;
    wire [6:0] disp_signal_digit2;
    wire sel;
    wire [7:0] r_data;
    wire [3:0] num;
    wire received_toggle_signal;/*1セットのascii dataを受信するたびにトグルする信号*/

    /*uartから信号を受信してレジスタに格納する*/
    receive_uart_rx receive_uart_rx(.clk(CLK100MHZ), .rst(ck_rst), .receive_signal(rx), .receive_data(r_data), .received_toggle_signal(received_toggle_signal));

    /*受信データ（asciiコード）を16進数にデコードする*/
    convert_data_to_ascii convert_data_to_ascii(.clk(CLK100MHZ), .ascii_data(r_data), .rst(ck_rst),.received_toggle_signal(received_toggle_signal), .decoded_hex_num(num));

    /*UART受信完了トグル毎に、受信した番号をFIFOに入れる*/
    add_num_to_fifo add_num_to_fifo(.clk(CLK100MHZ), .input_data(num), .shift_clk(received_toggle_signal), .rst(ck_rst), .digit1_data(disp_number_digit1), .digit2_data(disp_number_digit2) );

    /*numに入れた数字（16進数）を7seg表示用の信号にデコードする*/
    convert_num_to_segment convert_num_to_segment_digit1(.clk(CLK100MHZ),.num(disp_number_digit1), .rst(ck_rst), .segment(disp_signal_digit1));
    convert_num_to_segment convert_num_to_segment_digit2(.clk(CLK100MHZ),.num(disp_number_digit2), .rst(ck_rst), .segment(disp_signal_digit2));

    /*表示桁切り替え信号selを高速で切り替える*/
    toggle_sel toggle_sel(.clk(CLK100MHZ), .rst(ck_rst), .sel(sel));

    /*sel信号に応じて、表示内容を切り替える。*/
    toggle_digit toggle_digit(.clk(CLK100MHZ), .sel(sel), .digit1(disp_signal_digit1), .digit2(disp_signal_digit2), .disp(disp_signal));

    assign ja[0] = disp_signal[0];
    assign ja[1] = disp_signal[1];
    assign ja[2] = disp_signal[2];
    assign ja[3] = disp_signal[3];
    assign jb[0] = disp_signal[4];
    assign jb[1] = disp_signal[5];
    assign jb[2] = disp_signal[6];
    assign jb[3] = sel;
endmodule

module receive_uart_rx(input wire clk, input wire rst , input wire receive_signal, output reg [7:0] receive_data, output reg received_toggle_signal);
    parameter STATE_IDLE = 0;
    parameter STATE_1ST_NEGEDGE = 1;
    parameter STATE_FETCH_DATA = 2;
    parameter STATE_WAIT_1PERIOD = 3;

    parameter CLOCK_UART = 10416 ; // 1sec/9600*100MHz
    parameter CLOCK_UART_HALF = CLOCK_UART / 2; // 9BIT

    reg [3:0] state;
    reg [16:0] uart_counter;
    reg [7:0] data_counter;
    reg [7:0] receive_data_buf;

    always @ (posedge clk) begin
        if(rst == 0) begin
            receive_data <= 8'b0;
            state <= 4'b0;
            uart_counter <= 17'b0;
            data_counter <= 8'b0;/*今、uart 8bit dataのうち、何番目のデータを受信待ちか*/
            received_toggle_signal <= 0;/*今、*/
        end else begin
            if(state == STATE_IDLE) begin/*negedge待ち受け状態*/
                if(receive_signal == 0) begin
                    state <= STATE_1ST_NEGEDGE;
                end
            end else if(state == STATE_1ST_NEGEDGE) begin/*1.5BIT分の時間を待つ*/
                if(uart_counter > CLOCK_UART+CLOCK_UART_HALF) begin
                    state <= STATE_FETCH_DATA;
                    uart_counter <= 17'b0;
                end else begin
                    uart_counter <= uart_counter+ 17'b1;                
                end
            end else if(state == STATE_FETCH_DATA) begin
                if(data_counter == 4'h8) begin
                    data_counter <= 4'b0;
                    receive_data <= receive_data_buf;
                    received_toggle_signal <= ~received_toggle_signal;
                    state <= STATE_IDLE;
                end else begin
                    receive_data_buf[data_counter] <= receive_signal;
                    state <= STATE_WAIT_1PERIOD;
                end
            end else if(state == STATE_WAIT_1PERIOD) begin/*1BIT分の時間を待つ*/
                if(uart_counter > CLOCK_UART) begin
                    data_counter <= data_counter+4'b1;
                    state <= STATE_FETCH_DATA;
                    uart_counter <= 17'b0;
                end else begin
                    uart_counter <= uart_counter+ 17'b1;                
                end
            end
        end
    end
endmodule

module convert_data_to_ascii(input wire clk,input wire [7:0] ascii_data, input wire rst, input wire received_toggle_signal, output reg [3:0] decoded_hex_num);
    reg previous_toggle_signal;
    always @ (posedge clk) begin
        if(rst == 0) begin
            decoded_hex_num <= 0;
            previous_toggle_signal <= 0;
        end else begin
            if(previous_toggle_signal == received_toggle_signal) begin
            end else begin
                decoded_hex_num <= asciidec(ascii_data);
                previous_toggle_signal <= received_toggle_signal;
            end

        end
    end

    function [3:0]asciidec;/*8bitデータをasciiコードで数字にデコードする。*/
    input [7:0] din;
    begin
        case(din)
            8'h30 : asciidec = 4'h0;
            8'h31 : asciidec = 4'h1;
            8'h32 : asciidec = 4'h2;
            8'h33 : asciidec = 4'h3;
            8'h34 : asciidec = 4'h4;
            8'h35 : asciidec = 4'h5;
            8'h36 : asciidec = 4'h6;
            8'h37 : asciidec = 4'h7;
            8'h38 : asciidec = 4'h8;
            8'h39 : asciidec = 4'h9;
            8'h61 : asciidec = 4'hA;//a
            8'h62 : asciidec = 4'hB;//b
            8'h63 : asciidec = 4'hC;//c
            8'h64 : asciidec = 4'hD;//d
            8'h65 : asciidec = 4'hE;//e
            8'h66 : asciidec = 4'hF;//f
            8'h41 : asciidec = 4'hA;//A
            8'h42 : asciidec = 4'hB;//B
            8'h43 : asciidec = 4'hC;//C
            8'h44 : asciidec = 4'hD;//D
            8'h45 : asciidec = 4'hE;//E
            8'h46 : asciidec = 4'hF;//F
            default:asciidec = 4'h0;
        endcase
    end
    endfunction

endmodule

module convert_num_to_segment(input wire clk, input wire rst, input wire [3:0] num, output reg [6:0] segment);
    always @(posedge clk) begin 
        if(rst == 0) begin
            segment <= 0;
        end else begin
            segment <= segdec(num);
        end
    end

    function [6:0] segdec;/*数字を7seg displayの表示データにデコードする。*/
        input [7:0] din;
        begin
            case(din)
                4'h0 : segdec = 7'b0111111;
                4'h1 : segdec = 7'b0000110;
                4'h2 : segdec = 7'b1011011;
                4'h3 : segdec = 7'b1001111;
                4'h4 : segdec = 7'b1100110;
                4'h5 : segdec = 7'b1101101;
                4'h6 : segdec = 7'b1111101;
                4'h7 : segdec = 7'b0100111;
                4'h8 : segdec = 7'b1111111;
                4'h9 : segdec = 7'b1101111;
                4'hA : segdec = 7'b1110111;//A
                4'hB : segdec = 7'b1111100;//b
                4'hC : segdec = 7'b0111001;//C
                4'hD : segdec = 7'b1011110;//d
                4'hE : segdec = 7'b1111001;//E
                4'hF : segdec = 7'b1110001;//F
                default:segdec = 7'b1000000;
            endcase
        end
    endfunction
endmodule

module add_num_to_fifo(input wire clk,input wire [3:0] input_data, input wire shift_clk, input wire rst, output reg [3:0]digit1_data, output reg [3:0]digit2_data);
    reg previous_shift_clk;
    reg [6:0] delay_counter;

    always @(posedge clk) begin
        if(rst == 0) begin
            digit1_data <= 0;
            digit2_data <= 0;
            previous_shift_clk <= 0;
            delay_counter <= 0;
        end else begin
            if(previous_shift_clk == shift_clk) begin
            end else begin
                if(delay_counter > 7'd100) begin/*input_dataの値が確定するまで100カウント遅延させてから取得する*/
                    digit1_data <= input_data;
                    digit2_data <= digit1_data;
                    previous_shift_clk <= ~previous_shift_clk;
                    delay_counter <= 7'b0;
                end else begin
                    delay_counter <= delay_counter+7'b1;
                end
            end
        end
    end
endmodule

module toggle_sel(input wire clk, input wire rst,output reg sel);
    parameter count_up = 1000000;//100MHz * 10msec
    //parameter count_up = 10000;//100MHz * 10msec
    reg [19:0] counter;
    always @ (posedge clk) begin
        if(rst == 0) begin
            sel <= 0;
            counter <= 20'b0;
        end else begin
            if(counter == count_up) begin
                counter <= 20'b0;
                sel <=~sel;
            end else begin
                counter <= counter +20'b1;
            end
        end
    end
endmodule

module toggle_digit(input wire clk, input wire sel, input wire [6:0] digit1, input wire [6:0] digit2, output reg [6:0] disp );
    always @ (posedge clk) begin
        if(sel == 0) begin
            disp <= digit1;
        end else begin
            disp <= digit2;
        end
    end
endmodule
