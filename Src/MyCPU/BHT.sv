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
  output wire jump,
  output reg jump_EX
);
wire [31 - BEFORE_UNUSED : 0]tag_IF;
assign tag_IF = PC_IF[TAG_ADDR_LEN - 1 : 0];

wire [31 - BEFORE_UNUSED : 0]tag_EX;
assign tag_EX = PC_EX[TAG_ADDR_LEN - 1 : 0];

localparam BUFFER_SIZE = 1 << TAG_ADDR_LEN;

reg [1 : 0] BranchJudge[BUFFER_SIZE - 1 : 0];
reg jump_ID;

assign jump = (BranchJudge[tag_IF] == 2'b11) || (BranchJudge[tag_IF] == 2'b10);

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    jump_EX = 0;
    jump_ID = 0;
  end else begin
    jump_EX = jump_ID;
    jump_ID = jump;
  end
end
integer i;
always@(posedge clk or posedge rst) begin
  if (rst) begin
    for (i = 0; i < BUFFER_SIZE; i = i + 1) begin
      BranchJudge[i] <= 2'b00;
    end
  end else if (isBranch_EX == 1'b1) begin
    case(BranchJudge[tag_EX])
      2'b00 : BranchJudge[tag_EX] = br_EX ? 2'b01 : 2'b00;
      2'b01 : BranchJudge[tag_EX] = br_EX ? 2'b11 : 2'b00;
      2'b10 : BranchJudge[tag_EX] = br_EX ? 2'b11 : 2'b00;
      2'b11 : BranchJudge[tag_EX] = br_EX ? 2'b11 : 2'b10;
    endcase
  end
end

endmodule