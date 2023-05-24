`timescale 1ns/1ps

module sim_result;/*このモジュール名がsim実行結果のファイル名になる。*/
  reg clk ;/*テストベンチ内で使用するレジスタを宣言する*/
  reg ck_rst;
  reg rx;
  wire [3:0] ja;
  wire [3:0] jb;

  parameter UART_STEP = 104160;/*period 1000ns=1usec*/
  parameter CYC = 10;/*10ns = 100MHz*/

  always #(CYC/2) clk=~clk;

  top_module test_module ( /*sim対象のモジュールをdutという名前でインスタンス化*/
    .CLK100MHZ (clk)/*モジュールのポートCLK100MHZに（）の中身の値を対応づける*/
    , .ck_rst (ck_rst)
    , .rx (rx)
    , .ja (ja)
    , .jb (jb)
  );

  initial begin
    $dumpfile("sim_result.vcd"); // vcd file name
    $dumpvars(0,sim_result);     // dump targetは「全部」

    // Initilai value
    #(CYC* 0)   clk=0;ck_rst=0;rx=1;

    // Set seed
    #(CYC*100)   ck_rst=1'b1;   //

    #(CYC*10)        rx=1'b0;   //start bit
    #(UART_STEP*1)   rx=1'b1;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b1;   //
    #(UART_STEP*1)   rx=1'b1;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b1;   //end bit

    #(UART_STEP*5)         rx=1'b0;   //start bit
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b1;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b1;   //
    #(UART_STEP*1)   rx=1'b1;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b0;   //
    #(UART_STEP*1)   rx=1'b1;   //end bit





    // Stop simulation
    #(UART_STEP*3)   $finish;
  end
  
endmodule
