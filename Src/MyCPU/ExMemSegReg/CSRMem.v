`timescale 1ns / 1ps

module CSR_MEM(
    input wire clk, bubbleM, flushM,
    input wire [31:0] CSR_EX,
    input wire [31:0] csr_alu_out_EX,
    input wire [31:20] csr_wb_addr_EX,
    input wire [11:7] csr_rd_EX,
    input wire csr_write_EX,
    input wire csr_read_EX,
    input wire csr_set_EX,
    input wire csr_clear_EX,
    input wire csr_select_EX,
    output reg [31:0] CSR_MEM,
    output reg [31:0] csr_alu_out_MEM,
    output reg [31:20] csr_wb_addr_MEM,
    output reg [11:7] csr_rd_MEM,
    output reg csr_write_MEM,
    output reg csr_read_MEM,
    output reg csr_set_MEM,
    output reg csr_clear_MEM,
    output reg csr_select_MEM
    );

    initial
    begin
      CSR_MEM = 0;
      csr_alu_out_MEM = 0;
      csr_wb_addr_MEM = 0;
      csr_rd_MEM = 0;
      csr_write_MEM = 0;
      csr_read_MEM = 0;
      csr_set_MEM = 0;
      csr_clear_MEM = 0;
      csr_select_MEM = 0;
    end
    
    always@(posedge clk)
        if (!bubbleM) 
        begin
            if (flushM) begin
                CSR_MEM <= 0;
                csr_alu_out_MEM <= 0;
                csr_wb_addr_MEM <= 0;
                csr_rd_MEM <= 0;
                csr_write_MEM <= 0;
                csr_read_MEM <= 0;
                csr_set_MEM <= 0;
                csr_clear_MEM <= 0;
                csr_select_MEM <= 0;
            end else begin
                CSR_MEM <= CSR_EX;
                csr_alu_out_MEM <= csr_alu_out_EX;
                csr_wb_addr_MEM <= csr_wb_addr_EX;
                csr_rd_MEM <= csr_rd_EX;
                csr_write_MEM <= csr_write_EX;
                csr_read_MEM <= csr_read_EX;
                csr_set_MEM <= csr_set_EX;
                csr_clear_MEM <= csr_clear_EX;
                csr_select_MEM <= csr_select_EX;
            end
        end
    
endmodule