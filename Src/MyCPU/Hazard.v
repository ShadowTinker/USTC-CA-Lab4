`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Hazard Module
// Tool Versions: Vivado 2017.4.1
// Description: Hazard Module is used to control flush, bubble and bypass
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  识别流水线中的数据冲突，控制数据转发，和flush、bubble信号
// 输入
    // rst               CPU的rst信号
    // reg1_srcD         ID阶段的源reg1地址
    // reg2_srcD         ID阶段的源reg2地址
    // reg1_srcE         EX阶段的源reg1地址
    // reg2_srcE         EX阶段的源reg2地址
    // reg_dstE          EX阶段的目的reg地址
    // reg_dstM          MEM阶段的目的reg地址
    // reg_dstW          WB阶段的目的reg地址
    // br                是否branch
    // jalr              是否jalr
    // jal               是否jal
    // src_reg_en        指令中的源reg1和源reg2地址是否有效
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果）
    // reg_write_en_MEM  MEM阶段的寄存器写使能信号
    // reg_write_en_WB   WB阶段的寄存器写使能信号
    // alu_src1          ALU操作数1来源：0表示来自reg1，1表示来自PC
    // alu_src2          ALU操作数2来源：2’b00表示来自reg2，2'b01表示来自reg2地址，2'b10表示来自立即数
// 输出
    // flushF            IF阶段的flush信号
    // bubbleF           IF阶段的bubble信号
    // flushD            ID阶段的flush信号
    // bubbleD           ID阶段的bubble信号
    // flushE            EX阶段的flush信号
    // bubbleE           EX阶段的bubble信号
    // flushM            MEM阶段的flush信号
    // bubbleM           MEM阶段的bubble信号
    // flushW            WB阶段的flush信号
    // bubbleW           WB阶段的bubble信号
    // op1_sel           ALU的操作数1来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自PC，2'b11表示来自reg1
    // op2_sel           ALU的操作数2来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自reg2地址，2'b11表示来自reg2或立即数
    // reg2_sel          reg2的来源
// 实验要求
    // 补全模块


module HarzardUnit(
    input wire clk,rst,
    input wire [4:0] reg1_srcD, reg2_srcD, reg1_srcE, reg2_srcE, reg_dstE, reg_dstM, reg_dstW,
    input wire br, jalr, jal,
    input wire [1:0] src_reg_en,
    input wire wb_select,
    input wire reg_write_en_MEM,
    input wire reg_write_en_WB,
    input wire alu_src1,
    input wire [1:0] alu_src2,
    input wire miss,
    input wire fail,
    output reg flushF, bubbleF, flushD, bubbleD, flushE, bubbleE, flushM, bubbleM, flushW, bubbleW,
    output reg [1:0] op1_sel, op2_sel, reg2_sel
    );

    //flush
    always@(*) begin
        if(rst) begin
            flushF <= 1'b1;
            flushD <= 1'b1;
            flushE <= 1'b1;
            flushM <= 1'b1;
            flushW <= 1'b1;
        end else if (fail) begin
            flushF <= 1'b0;
            flushD <= 1'b1;
            flushE <= 1'b1;
            flushM <= 1'b0;
            flushW <= 1'b0;
        end else if (jalr) begin
            flushF <= 1'b0;
            flushD <= 1'b1;
            flushE <= 1'b1;
            flushM <= 1'b0;
            flushW <= 1'b0;
        end else if (jal) begin
            flushF <= 1'b0;
            flushD <= 1'b1;
            flushE <= 1'b0;
            flushM <= 1'b0;
            flushW <= 1'b0;
        end else if ((reg1_srcD == reg_dstE || reg2_srcD == reg_dstE) && wb_select == 1'b1) begin
            flushF <= 1'b0;
            flushD <= 1'b0;
            flushE <= 1'b1;
            flushM <= 1'b0;
            flushW <= 1'b0;
        end else begin
            flushF <= 1'b0;
            flushD <= 1'b0;
            flushE <= 1'b0;
            flushM <= 1'b0;
            flushW <= 1'b0;
        end
    end

    //bubble
    always@(*) begin
        if ((reg1_srcD == reg_dstE || reg2_srcD == reg_dstE) && wb_select == 1'b1) begin
            bubbleF <= 1'b1;
            bubbleD <= 1'b1;
            bubbleE <= 1'b0;
            bubbleM <= 1'b0;
            bubbleW <= 1'b0;
        end else if (miss == 1'b1) begin
            bubbleF <= 1'b1;
            bubbleD <= 1'b1;
            bubbleE <= 1'b1;
            bubbleM <= 1'b1;
            bubbleW <= 1'b1;
        end else begin
            bubbleF <= 1'b0;
            bubbleD <= 1'b0;
            bubbleE <= 1'b0;
            bubbleM <= 1'b0;
            bubbleW <= 1'b0;
        end
    end

    //forward
    always@(*) begin
        //op1_sel
        if(alu_src1 == 0
        && src_reg_en[1] == 1'b1 
        && reg1_srcE == reg_dstM 
        && reg_write_en_MEM == 1'b1 
        && reg1_srcE != 5'b0) begin
            op1_sel <= 2'b00;
        end else if (alu_src1 == 0
        && src_reg_en[1] == 1'b1 
        && reg1_srcE == reg_dstW 
        && reg_write_en_WB == 1'b1 
        && reg1_srcE != 5'b0) begin
            op1_sel <= 2'b01;
        end else if (alu_src1 == 1) begin
            op1_sel <= 2'b10;
        end else begin
            op1_sel <= 2'b11;
        end
        //op2_sel
        if(alu_src2 == 2'b00
        && src_reg_en[0] == 1'b1 
        && reg2_srcE == reg_dstM 
        && reg_write_en_MEM == 1'b1 
        && reg2_srcE != 5'b0) begin
            op2_sel <= 2'b00;
        end else if (alu_src2 == 2'b00
        && src_reg_en[0] == 1'b1 
        && reg2_srcE == reg_dstW 
        && reg_write_en_WB == 1'b1 
        && reg2_srcE != 5'b0) begin
            op2_sel <= 2'b01;
        end else if (alu_src2 == 2'b00) begin
            op2_sel <= 2'b11;
        end else if (alu_src2 == 2'b01) begin
            op2_sel <= 2'b10;
        end else begin
            op2_sel <= 2'b11;
        end

        //reg_sel
        if(src_reg_en[0] == 1'b1 
        && reg2_srcE == reg_dstM 
        && reg_write_en_MEM == 1'b1 
        && reg2_srcE != 5'b0) begin
            reg2_sel <= 2'b00;
        end else if (src_reg_en[0] == 1'b1 
        && reg2_srcE == reg_dstW 
        && reg_write_en_WB == 1'b1 
        && reg2_srcE != 5'b0) begin
            reg2_sel <= 2'b01;
        end else if (alu_src2 == 2'b01) begin
            reg2_sel <= 2'b10;
        end else begin
            reg2_sel <= 2'b11;
        end
    end
    
integer total, right, wrong;
always @(posedge clk,posedge rst)
    begin
        if (rst) begin
            total = 0;
            wrong = 0;
            right = 0;
        end else begin
            if (br) total = total + 1;
            if (fail) wrong = wrong + 1;
            right = total - wrong;
        end
    end
endmodule