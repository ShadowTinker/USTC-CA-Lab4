`timescale 1ns / 1ps

module CSR(
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire read_en,
    input wire set_en,
    input wire clear_en,
    input wire [31:20] addr, wb_addr,
    input wire [31:0] wb_data,
    output wire [31:0] csr_reg
    );

    reg [31:0] reg_file[4095:0];
    integer i;

    // init register file
    initial
    begin
        for(i = 0; i < 4095; i = i + 1) 
            reg_file[i][31:0] <= 32'b0;
    end

    always@(negedge clk or posedge rst) 
    begin 
        if (rst)
            for (i = 0; i < 4095; i = i + 1) 
                reg_file[i][31:0] <= 32'b0;
        else if(write_en)
            reg_file[wb_addr] <= wb_data;
    end

    assign csr_reg = read_en ? reg_file[addr] : 32'hxxxx_xxxx;

endmodule
