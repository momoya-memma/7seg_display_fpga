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


module seven_seg_disp(
    input wire CLK100MHZ,
    //input wire [3:0] jc,
    input wire uart_rx_of_pmod,
    //input wire [3:0] btn,
    output wire [3:0] led,
    output wire [3:0] ja,
    output wire [7:4] jb
    );
    
    parameter STATE_INITIAL = 0;
    parameter STATE_IDLE = 1;
    parameter STATE_1ST_NEGEDGE = 2;
    parameter STATE_FETCH_DATA = 3;
    parameter STATE_WAIT_1PERIOD = 4;
    parameter STATE_UPDATE_DISP = 5;
    
    parameter CLOCK_UART = 10416 ; // 1sec/9600*100MHz
    parameter CLOCK_UART_HALF = CLOCK_UART / 2; // 9BIT
    parameter UART_PERIOD = CLOCK_UART * 9; // 9BIT
    
    
    reg [3:0] state;
    reg [6:0] segment;
    reg [6:0] segment_digit1;
    reg [6:0] segment_digit2;
    reg digit_reg;
    reg [20:0] counter;
    reg [16:0] uart_counter;
    reg [7:0] num;
    reg digit_sel;
    reg [3:0] led_output;
    reg [7:0] receive_data;/*受け取ったデータを8bit分格納しておくレジスタ*/
    reg [3:0] data_counter;/*今何bit目まで受け取ったかを管理するレジスタ*/
    
    initial begin 
        state <= STATE_INITIAL;
        segment <= 7'b0;
        segment_digit1 <= 7'b0;
        segment_digit2 <= 7'b0;
        counter <= 21'b0;
        uart_counter <= 17'b0;
        num <= 8'b0;
        digit_sel <= 1'b0;
        digit_reg <= 1'b0;
        led_output <= 4'b0;
        receive_data = 8'b0;
        data_counter = 4'b0;
    end


    always @ (posedge CLK100MHZ) begin
        counter <= counter + 1'b1;
        if (counter > 1000000) begin
            digit_sel <= !digit_sel;
            if(digit_sel) begin
                segment <= segment_digit1;
            end else begin
                segment <= segment_digit2;
            end
            counter <= 21'b0;
        end
        
        if(state == STATE_INITIAL) begin/*最初だけはいる。*/
                segment_digit1 <= segdec(num);
                segment_digit2 <= segdec(num);
                state <= STATE_IDLE;
                led_output = 4'h0;
        end else if(state == STATE_IDLE) begin/*negedge待ち受け状態*/
            led_output = 4'h1;
            if(uart_rx_of_pmod == 0) begin
                state <= STATE_1ST_NEGEDGE;
            end
        end else if(state == STATE_1ST_NEGEDGE) begin/*1.5BIT分の時間を待つ*/
            led_output = 4'h2;
            if(uart_counter > CLOCK_UART+CLOCK_UART_HALF) begin
                state <= STATE_FETCH_DATA;
                uart_counter <= 17'b0;
            end else begin
                uart_counter <= uart_counter+ 17'b1;                
            end
        end else if(state == STATE_FETCH_DATA) begin
            led_output = 4'h3;
            if(data_counter == 4'h8) begin
                data_counter <= 4'b0;
                num <= asciidec(receive_data);
                state <= STATE_UPDATE_DISP;
            end else begin
                receive_data[data_counter] <= uart_rx_of_pmod;
                state <= STATE_WAIT_1PERIOD;
            end
        end else if(state == STATE_WAIT_1PERIOD) begin/*1BIT分の時間を待つ*/
            led_output = 4'h4;
            if(uart_counter > CLOCK_UART) begin
                data_counter <= data_counter+4'b1;
                state <= STATE_FETCH_DATA;
                uart_counter <= 17'b0;
            end else begin
                uart_counter <= uart_counter+ 17'b1;                
            end
        end else if(state == STATE_UPDATE_DISP) begin
            led_output = 4'h5;
            if(digit_reg == 1'b0) begin
                segment_digit1 <= segdec(num);
            end else begin
                segment_digit2 <= segdec(num);
            end
            digit_reg <= !digit_reg;
            state = STATE_IDLE;
        end
    end
    
    function [6:0] segdec;/*数字を7seg displayの表示データにデコードする。*/
    input [3:0] din;
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
            default:segdec = 7'b0000001;
        endcase
    end
    endfunction

    function [3:0]asciidec;/*8bitデータをasciiコードで数字にデコードする。*/
    input [7:0] din;
    begin
        case(din)
            8'b00110000 : asciidec = 4'h0;
            8'b00110001 : asciidec = 4'h1;
            8'b00110010 : asciidec = 4'h2;
            8'b00110011 : asciidec = 4'h3;
            8'b00110100 : asciidec = 4'h4;
            8'b00110101 : asciidec = 4'h5;
            8'b00110110 : asciidec = 4'h6;
            8'b00110111 : asciidec = 4'h7;
            8'b00111000 : asciidec = 4'h8;
            8'b00111001 : asciidec = 4'h9;
            default:asciidec = 4'ha;
        endcase
    end
    endfunction
    
    assign ja[0] = segment[0];
    assign ja[1] = segment[1];
    assign ja[2] = segment[2];
    assign ja[3] = segment[3];
    assign jb[4] = segment[4];
    assign jb[5] = segment[5];
    assign jb[6] = segment[6];
    assign jb[7] = digit_sel;
    assign led = led_output;
    
endmodule
