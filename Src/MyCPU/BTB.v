module BTB # (
  parameter BEFORE_UNUSED = 20,
  parameter TAG_ADDR_LEN = 12,
)(
  input wire clk,rst,
  // IF signal
  input wire [31:0] PC_IF,
  output reg found_IF,
  output reg [31:0] NPC_predicted_IF,
  // EX signal
  input wire branch_EX,
  input wire found_EX,
  input wire [31:0] PC_EX,
  input wire [31:0] branch_target_EX,
  input wire br_EX,
  output reg fail
);

wire [31 : 32 - BEFORE_UNUSED] before_IF;
wire [31 - BEFORE_UNUSED, 0] tag_IF;
assgin {before_IF, tag_IF} = PC_IF;

wire [31: 32 - BEFORE_UNUSED] before_EX;
wire [31 - BEFORE_UNUSED, 0] tag_EX;
assgin {before_EX, tag_EX} = PC_EX;

reg [31 : 0] BranchPC[TAG_ADDR_LEN - 1 : 0];
reg [31 : 0] PredictedPC[TAG_ADDR_LEN - 1 : 0];
reg state[TAG_ADDR_LEN - 1 : 0];
reg valid[TAG_ADDR_LEN - 1 : 0];

alway@(posedge clk or posedge rst) begin
  if (rst) begin
    for (int i = 0; i < TAG_ADDR_LEN; i++) begin
      valid[i] <= 1'b0;
      BranchPC[i] <= 32'b0;
      PredictedPC[i] <= 32'b0;
      state[i] <= 1'b0;
    end
  end else begin
    if (valid[tag_IF] == 1'b1) begin // IF阶段，判断BTB中是否已存有跳转信息
      if (BranchPC[tag_IF] == PC_IF) begin // 已有表项，且表项的PC对应得上（不同PC有可能tag相同）
        found_IF <= 1'b1;
        NPC_predicted_IF <= PredictedPC[tag_IF];
      end else begin // BTB表冲突，可能需要替换，替换工作在EX阶段完成
        found_IF <= 1'b0;
        NPC_predicted_IF <= PC_IF + 4;
      end
    end else begin // 没有相关信息
      found_IF <= 1'b0;
      NPC_predicted_IF <= PC_IF + 4;
    end

    if (branch_EX == 1'b1 and found_EX == 1'b0) begin // EX阶段，判断是否要增加一个新的表项，也有可能会把旧的表项替换
      BranchPC[tag_EX] <= PC_EX;
      PredictedPC[tag_EX] <= branch_target_EX;
      state[tag_EX] <= br_EX;
      valid[tag_EX] <= 1'b1;
    end

    if (found_EX == 1'b1) begin // EX阶段，判断之前在IF阶段做的分支预测是否正确，如果正确无操作，如果错误那么更新BTB
      if ((br_EX != state[tag_EX])) begin // 预测错误
        state[tag_EX] <= br_EX;
        fail <= 1'b1;
      end else begin
        fail <= 1'b0;
      end
    end
  end
end