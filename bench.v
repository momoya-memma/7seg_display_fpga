`timescale 1ps/1ps

module tb_Prpg10;/*このモジュール名がsim実行結果のファイル名になる。*/
  reg clk, tx ;/*テストベンチ内で使用するレジスタを宣言する*/
  wire [3:0] ingicater;
  wire  [3:0] ja;
  wire  [3:0] jb;

  reg [6:0] segment;
  wire digit;

  assign ja[0] = segment[0];
  assign ja[1] = segment[1];
  assign ja[2] = segment[2];
  assign ja[3] = segment[3];
  assign jb[0] = segment[4];
  assign jb[1] = segment[5];
  assign jb[2] = segment[6];
  assign jb[3] = digit;


  parameter STEP = 104160000; //104usec
  parameter CYC = 1000;/*period 10ns=1u/100=100MHz*/
  always #(CYC/2) clk = ~clk;/*CYC/2が経過するたびにclkを反転*/

  seven_seg_disp disp ( /*sim対象のモジュールをdutという名前でインスタンス化*/
    .CLK100MHZ (clk),/*モジュールのポートCLK100MHZに（）の中身の値を対応づける*/
    .uart_rx_of_pmod (tx),
    .led (ingicater),
    .ja (ja),
    .jb (jb)
  );

  initial begin
    $dumpfile("tb_Prpg10.vcd"); // vcd file name
    $dumpvars(0,tb_Prpg10);     // dump targetは「全部」

    // Initilai value
    #(CYC* 0)   clk=0; segment=7'b0000000; tx=1;

    #(STEP* 5)  
    // Set seed
    #(STEP)   tx=0;   //tx start
    #(STEP)   tx=1;   //ascii 5 1of8
    #(STEP)   tx=0;   //ascii 5 2of8
    #(STEP)   tx=1;   //ascii 5 3of8
    #(STEP)   tx=0;   //ascii 5 4of8
    #(STEP)   tx=1;   //ascii 5 5of8
    #(STEP)   tx=1;   //ascii 5 6of8
    #(STEP)   tx=0;   //ascii 5 7of8
    #(STEP)   tx=0;   //ascii 5 8of8

    // Stop simulation
    #(STEP*5)   $finish;
  end
  
endmodule
