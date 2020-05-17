module BHT # (
  parameter BEFORE_UNUSED = 20,
  parameter TAG_ADDR_LEN = 12
) (
  input wire clk,rst,
  // IF signal
  input wire [31:0] PC_IF,
  // EX signal
  input wire [31:0] PC_EX,
  input wire br_EX,
  input wire isBranch_EX,
  output reg jump
);

assign tag_IF = PC_IF[31 - BEFORE_UNUSED : 0];

assign tag_EX = PC_EX[31 - BEFORE_UNUSED : 0];

reg [1 : 0] BranchJudge[TAG_ADDR_LEN - 1 : 0];

always@(*) begin
  if ((BranchJudge[tag_IF] == 2'b11) || (BranchJudge[tag_IF] == 2'b10)) begin
    jump <= 1'b1;
  end else begin
    jump <= 1'b0;
  end
end

always@(posedge clk or posedge rst) begin
  if (rst) begin
    for (integer i = 0; i < (1 << TAG_ADDR_LEN); i = i + 1) begin
      BranchJudge[i] <= 2'b10;
    end
  end else if (isBranch_EX == 1'b1) begin
    case(BranchJudge[tag_EX])
      2'b00 : begin
        if (br_EX == 1'b1) begin
          BranchJudge[tag_EX] <= 2'b01;
        end else begin
          BranchJudge[tag_EX] <= 2'b00;
        end
      end
      2'b01 : begin
        if (br_EX == 1'b1) begin
          BranchJudge[tag_EX] <= 2'b11;
        end else begin
          BranchJudge[tag_EX] <= 2'b00;
        end
      end
      2'b10 : begin
        if (br_EX == 1'b1) begin
          BranchJudge[tag_EX] <= 2'b11;
        end else begin
          BranchJudge[tag_EX] <= 2'b00;
        end
      end
      2'b11 : begin
        if (br_EX == 1'b1) begin
          BranchJudge[tag_EX] <= 2'b11;
        end else begin
          BranchJudge[tag_EX] <= 2'b10;
        end
      end
    endcase
  end
end

endmodule