`timescale 1ns / 1ps

module CSR_WB(
    input wire clk, bubbleW, flushW,
    input wire [31:0] CSR_MEM,
    input wire [31:0] csr_alu_out_MEM,
    input wire [31:20] csr_wb_addr_MEM,
    input wire [11:7] csr_rd_MEM,
    input wire csr_write_MEM,
    input wire csr_read_MEM,
    input wire csr_set_MEM,
    input wire csr_clear_MEM,
    input wire csr_select_MEM,
    output reg [31:0] CSR_WB,
    output reg [31:0] csr_alu_out_WB,
    output reg [31:20] csr_wb_addr_WB,
    output reg [11:7] csr_rd_WB,
    output reg csr_write_WB,
    output reg csr_read_WB,
    output reg csr_set_WB,
    output reg csr_clear_WB,
    output reg csr_select_WB
    );

    initial
    begin
        CSR_WB = 0;
        csr_alu_out_WB = 0;
        csr_wb_addr_WB = 0;
        csr_rd_WB = 0;
        csr_write_WB = 0;
        csr_read_WB = 0;
        csr_set_WB = 0;
        csr_clear_WB = 0;
        csr_select_WB = 0;
    end
    
    always@(posedge clk)
        if (!bubbleW) 
        begin
            if (flushW) begin
                CSR_WB <= 0;
                csr_alu_out_WB <= 0;
                csr_wb_addr_WB <= 0;
                csr_rd_WB <= 0;
                csr_write_WB <= 0;
                csr_read_WB <= 0;
                csr_set_WB <= 0;
                csr_clear_WB <= 0;
                csr_select_WB <= 0;
            end else begin
                CSR_WB <= CSR_MEM;
                csr_alu_out_WB <= csr_alu_out_MEM;
                csr_wb_addr_WB <= csr_wb_addr_MEM;
                csr_rd_WB <= csr_rd_MEM;
                csr_write_WB <= csr_write_MEM;
                csr_read_WB <= csr_read_MEM;
                csr_set_WB <= csr_set_MEM;
                csr_clear_WB <= csr_clear_MEM;
                csr_select_WB <= csr_select_MEM;
            end
        end
    
endmodule