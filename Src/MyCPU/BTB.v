`include "Parameters.v"
module BTB # (
  parameter BEFORE_UNUSED = 20,
  parameter TAG_ADDR_LEN = 12
) (
  input wire clk,rst,
  // IF signal
  input wire [31:0] PC_IF,
  output wire found_IF,
  output wire [31:0] NPC_predicted_IF,
  // EX signal
  input wire [2:0] branch_EX,
  input wire found_EX,
  input wire [31:0] PC_EX,
  input wire [31:0] branch_target_EX,
  input wire br_EX,
  output wire fail
);
wire [31 - BEFORE_UNUSED : 0]tag_IF;
assign tag_IF = PC_IF[TAG_ADDR_LEN - 1 : 0];

wire [31 - BEFORE_UNUSED : 0]tag_EX;
assign tag_EX = PC_EX[TAG_ADDR_LEN - 1 : 0];

localparam BUFFER_SIZE = 1 << TAG_ADDR_LEN;
reg [31 : 0] BranchPC[BUFFER_SIZE - 1 : 0];
reg [31 : 0] PredictedPC[BUFFER_SIZE - 1 : 0];
reg state[BUFFER_SIZE - 1 : 0];
reg valid[BUFFER_SIZE - 1 : 0];

// 用来与BHT交互的信号
wire isBranch_EX;
wire jump, jump_EX;
wire prediction_IF;
reg prediction_ID, prediction_EX;
integer right, wrong;
integer i,test;

assign found_IF = (PC_IF == BranchPC[tag_IF]);
assign prediction_IF = found_IF && state[tag_IF] && jump;
assign NPC_predicted_IF = prediction_IF ? PredictedPC[tag_IF] : (PC_IF + 4);
assign fail = (!found_EX && br_EX) || 
              (found_EX && (((br_EX && !prediction_EX) || (!br_EX && prediction_EX))));
assign isBranch_EX = found_EX;

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    prediction_EX = 0;
    prediction_ID = 0;
  end else begin
    prediction_EX = prediction_ID;
    prediction_ID = prediction_IF;
  end
end

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    for (i = 0; i < BUFFER_SIZE; i = i + 1) begin
      BranchPC[i] <= 32'b0;
      PredictedPC[i] <= 32'b0;
      state[i] <= 1'b0;
      valid[i] <= 1'b0;
    end
  end else begin
    if (!found_EX) begin // BTB中没有该PC的信息
      if (br_EX) begin // 需要记录该PC的信息
        BranchPC[i] <= PC_EX;
        PredictedPC[i] <= branch_target_EX;
        state[i] <= 1;
      end
    end else begin // 更新BTB
      if (prediction_EX) begin // 预测值为跳转
        if (branch_EX == `NOBRANCH) begin // 实际该未记录的指令为普通指令
          PredictedPC[tag_EX] <= PC_EX + 4;
          state[tag_EX] <= 0;
        end else if (!br_EX) begin // 是分支指令，本来不要跳转的反而预测跳转了
          state[tag_EX] <= 0;
        end
      end else begin // 预测值为不跳转
        if (br_EX) begin // 本来要跳转的反而预测不要跳转了
          state[tag_EX] <= 1;
        end
      end
    end
  end
end

BHT BHT1(
  .clk(clk),
  .rst(rst),
  .PC_IF(PC_IF),
  .PC_EX(PC_EX),
  .br_EX(br_EX),
  .isBranch_EX(isBranch_EX),
  .jump(jump),
  .jump_EX(jump_EX)
);

endmodule