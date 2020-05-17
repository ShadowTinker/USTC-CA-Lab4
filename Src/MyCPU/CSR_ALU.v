`timescale 1ns / 1ps

`include "Parameters.v"   
module CSR_ALU(
    input wire [31:0] csr_op1,
    input wire [31:0] csr_op2,
    input wire csr_set,
    input wire csr_clear,
    output reg [31:0] csr_alu_out
    );

    always@(*) begin
        if (csr_set) begin
            csr_alu_out <= csr_op1 | csr_op2;
        end else if (csr_clear) begin
            csr_alu_out <= csr_op1 ^ (csr_op2 ^ 32'b0);
        end else begin
            csr_alu_out <= csr_op2;
        end
    end

endmodule