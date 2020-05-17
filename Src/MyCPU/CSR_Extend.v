`timescale 1ns / 1ps

module CSRExtend(
    input wire [19:15] inst,
    output reg [31:0] imm
    );

    always@(*) begin
        imm <= {27'b0, inst};
    end

endmodule