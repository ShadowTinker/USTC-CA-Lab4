`timescale 1ns / 1ps

module CSR_EX(
    input wire clk, bubbleE, flushE,
    input wire [31:0] CSR_ID,
    input wire [31:0] csr_reg1_ID,
    input wire [31:0] csr_imm_ID,
    input wire [31:20] csr_wb_addr_ID,
    input wire [11:7] csr_rd_ID,
    input wire csr_write_ID,
    input wire csr_read_ID,
    input wire csr_set_ID,
    input wire csr_clear_ID,
    input wire csr_select_ID,
    output reg [31:0] CSR_EX,
    output reg [31:0] csr_reg1_EX,
    output reg [31:0] csr_imm_EX,
    output reg [31:20] csr_wb_addr_EX,
    output reg [11:7] csr_rd_EX,
    output reg csr_write_EX,
    output reg csr_read_EX,
    output reg csr_set_EX,
    output reg csr_clear_EX,
    output reg csr_select_EX
    );

    initial
    begin
      CSR_EX = 0;
      csr_reg1_EX = 0;
      csr_imm_EX = 0;
      csr_wb_addr_EX = 0;
      csr_rd_EX = 0;
      csr_write_EX = 0;
      csr_read_EX = 0;
      csr_set_EX = 0;
      csr_clear_EX = 0;
      csr_select_EX = 0;
    end
    
    always@(posedge clk)
        if (!bubbleE) 
        begin
            if (flushE) begin
                CSR_EX <= 0;
                csr_reg1_EX <= 0;
                csr_imm_EX <= 0;
                csr_wb_addr_EX <= 0;
                csr_rd_EX <= 0;
                csr_write_EX <= 0;
                csr_read_EX <= 0;
                csr_set_EX <= 0;
                csr_clear_EX <= 0;
                csr_select_EX <= 0;
            end else begin
                CSR_EX <= CSR_ID;
                csr_reg1_EX <= csr_reg1_ID;
                csr_imm_EX <= csr_imm_ID;
                csr_wb_addr_EX <= csr_wb_addr_ID;
                csr_rd_EX <= csr_rd_ID;
                csr_write_EX <= csr_write_ID;
                csr_read_EX <= csr_read_ID;
                csr_set_EX <= csr_set_ID;
                csr_clear_EX <= csr_clear_ID;
                csr_select_EX <= csr_select_ID;
            end 
        end
    
endmodule