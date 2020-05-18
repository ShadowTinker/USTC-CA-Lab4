`timescale 1ns / 1ps

module cpu_tb();
    reg clk = 1'b1;
    reg rst = 1'b1;
    integer counter = 0;
    
    always  #2 clk = ~clk;
    always  #4 counter = counter + 1;
    initial #8 rst = 1'b0;
    
    RV32ICore RV32ICore_tb_inst(
        .CPU_CLK    ( clk          ),
        .CPU_RST    ( rst          )
    );
    
endmodule
