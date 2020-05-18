`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: RV32I Core
// Tool Versions: Vivado 2017.4.1
// Description: Top level of our CPU Core
//////////////////////////////////////////////////////////////////////////////////


//功能说明
    // RV32I Core的顶层模块
//实验要求  
    // 添加CSR指令的数据通路和相应部件

module RV32ICore(
    input wire CPU_CLK,
    input wire CPU_RST,
    input wire [31:0] CPU_Debug_DataCache_A2,
    input wire [31:0] CPU_Debug_DataCache_WD2,
    input wire [3:0] CPU_Debug_DataCache_WE2,
    output wire [31:0] CPU_Debug_DataCache_RD2,
    input wire [31:0] CPU_Debug_InstCache_A2,
    input wire [31:0] CPU_Debug_InstCache_WD2,
    input wire [ 3:0] CPU_Debug_InstCache_WE2,
    output wire [31:0] CPU_Debug_InstCache_RD2
    );
	//wire values definitions
    wire CacheMiss;
    wire bubbleF, flushF, bubbleD, flushD, bubbleE, flushE, bubbleM, flushM, bubbleW, flushW;
    wire [31:0] jal_target, br_target;
    wire jal, br;
    wire jalr_ID, jalr_EX;
    wire [31:0] NPC, PC_IF, PC_4, PC_ID, PC_EX;
    wire [31:0] inst_ID;
    wire reg_write_en_ID, reg_write_en_EX, reg_write_en_MEM, reg_write_en_WB;
    wire [4:0] reg1_src_EX;
    wire [4:0] reg2_src_EX;
    wire [4:0] reg_dest_EX, reg_dest_MEM, reg_dest_WB;
    wire [31:0] data_WB;
    wire [31:0] reg1, reg1_EX;
    wire [31:0] reg2, reg2_EX, reg2_MEM;
    wire [31:0] op2;
    wire [31:0] reg_or_imm;
    wire op2_src;
    wire [3:0] ALU_func_ID, ALU_func_EX;
    wire [2:0] br_type_ID, br_type_EX;
    wire load_npc_ID, load_npc_EX;
    wire wb_select_ID, wb_select_EX, wb_select_MEM;
    wire [2:0] load_type_ID, load_type_EX, load_type_MEM;
    wire [1:0] src_reg_en_ID, src_reg_en_EX;
    wire [3:0] cache_write_en_ID, cache_write_en_EX, cache_write_en_MEM;
    wire alu_src1_ID, alu_src1_EX;
    wire [1:0] alu_src2_ID, alu_src2_EX;
    wire [2:0] imm_type;
    wire [31:0] imm;
    wire [31:0] ALU_op1, ALU_op2, ALU_out;
    wire [31:0] dealt_reg2;
    wire [31:0] result, result_MEM;
    wire [1:0] op1_sel, op2_sel, reg2_sel;
    wire rd_req_ID;

    //csr control
    wire [31:0] csr_alu_input;
    wire [31:0] RF_CSR_write_data;
    //CSR-ID
    wire [31:0] CSR_ID,csr_reg1_ID,csr_imm_ID;
    wire csr_write_ID,csr_read_ID,csr_set_ID,csr_clear_ID,csr_select_ID;
    //CSR-EX
    wire [31:0] CSR_EX,csr_reg1_EX,csr_imm_EX,csr_alu_out_EX;
    wire csr_write_EX,csr_read_EX,csr_set_EX,csr_clear_EX,csr_select_EX;
    wire [31:20] csr_wb_addr_EX;
    wire [11:7] csr_rd_EX;
    //CSR-MEM
    wire [31:0] CSR_MEM,csr_reg1_MEM,csr_imm_MEM,csr_alu_out_MEM;
    wire csr_write_MEM,csr_read_MEM,csr_set_MEM,csr_clear_MEM,csr_select_MEM;
    wire [31:20] csr_wb_addr_MEM;
    wire [11:7] csr_rd_MEM;
    //CSR-WB
    wire [31:0] CSR_WB,csr_reg1_WB,csr_imm_WB,csr_alu_out_WB;
    wire csr_write_WB,csr_read_WB,csr_set_WB,csr_clear_WB,csr_select_WB;
    wire [31:20] csr_wb_addr_WB;
    wire [11:7] csr_rd_WB;
    //BTB signal
    wire found_IF;
    wire found_ID;
    wire found_EX;
    wire [31:0] real_PC_EX;
    wire fail;

    assign real_PC_EX = PC_EX - 4;
    // MUX for op2 source
    assign op2 = op2_src ? imm : reg2;
    // Adder to compute PC_ID + Imm - 4
    assign jal_target = PC_ID + op2 - 4;
    // MUX for ALU op1
    assign ALU_op1 = (op1_sel == 2'h0) ? result_MEM :
                                         ((op1_sel == 2'h1) ? data_WB :
                                                              (op1_sel == 2'h2) ? (PC_EX - 4) :
                                                                                  reg1_EX);
    // MUX for ALU op2
    assign ALU_op2 = (op2_sel == 2'h0) ? result_MEM :
                                         ((op2_sel == 2'h1) ? data_WB :
                                                              ((op2_sel == 2'h2) ? reg2_src_EX :
                                                                                   reg_or_imm));

    // MUX for Reg2
    assign dealt_reg2 = (reg2_sel == 2'h0) ? result_MEM :
                                            ((reg2_sel == 2'h1) ? data_WB : reg2_EX);


    // MUX for result (ALU or PC_EX)
    assign result = load_npc_EX ? PC_EX : ALU_out;

    // MUX for CSR_ALU Input (reg1 or imm)
    assign csr_alu_input = csr_select_EX ? csr_imm_EX : csr_reg1_EX;

    // MUX for RegisterFile after add the csr module
    assign RF_CSR_write_data = csr_read_WB ? CSR_WB : data_WB;

    //Module connections
    // ---------------------------------------------
    // PC-Generator
    // ---------------------------------------------


    NPC_Generator NPC_Generator1(
        .PC(PC_4),
        .jal_target(jal_target),
        .jalr_target(ALU_out),
        .br_target(br_target),
        .jal(jal),
        .jalr(jalr_EX),
        .br(br),
        .NPC(NPC),
        .fail(fail),
        .found_EX(found_EX),
        .PC_EX(PC_EX)
    );


    PC_IF PC_IF1(
        .clk(CPU_CLK),
        .bubbleF(bubbleF),
        .flushF(flushF),
        .NPC(NPC),
        .PC(PC_IF)
    );



    // ---------------------------------------------
    // IF stage
    // ---------------------------------------------

    BTB BTB1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .PC_IF(PC_IF),
        .found_IF(found_IF),
        .NPC_predicted_IF(PC_4),
        .branch_EX(br_type_EX),
        .found_EX(found_EX),
        .PC_EX(real_PC_EX),
        .branch_target_EX(br_target),
        .br_EX(br),
        .fail(fail)
    );

    PC_ID PC_ID1(
        .clk(CPU_CLK),
        .bubbleD(bubbleD),
        .flushD(flushD),
        .PC_IF(PC_4),
        .PC_ID(PC_ID),
        .found_IF(found_IF),
        .found_ID(found_ID)
    );


    IR_ID IR_ID1(
        .clk(CPU_CLK),
        .bubbleD(bubbleD),
        .flushD(flushD),
        .write_en(|CPU_Debug_InstCache_WE2),
        .addr(PC_IF[31:2]),
        .debug_addr(CPU_Debug_InstCache_A2[31:2]),
        .debug_input(CPU_Debug_InstCache_WD2),
        .inst_ID(inst_ID),
        .debug_data(CPU_Debug_InstCache_RD2)
    );



    // ---------------------------------------------
    // ID stage
    // ---------------------------------------------


    RegisterFile RegisterFile1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .write_en(reg_write_en_WB),
        .addr1(inst_ID[19:15]),
        .addr2(inst_ID[24:20]),
        .wb_addr(reg_dest_WB),
        .wb_data(RF_CSR_write_data),
        .reg1(reg1),
        .reg2(reg2)
    );

    CSRExtend CSRExtend1(
        .inst(inst_ID[19:15]),
        .imm(csr_imm_ID)
    );

    CSR CSR1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .write_en(csr_write_WB),
        .read_en(csr_read_ID),
        .set_en(csr_set_WB),
        .clear_en(csr_clear_WB),
        .addr(inst_ID[31:20]),
        .wb_addr(csr_wb_addr_WB),
        .wb_data(csr_alu_out_WB),
        .csr_reg(CSR_ID)
    );

    ControllerDecoder ControllerDecoder1(
        .inst(inst_ID),
        .jal(jal),
        .jalr(jalr_ID),
        .op2_src(op2_src),
        .ALU_func(ALU_func_ID),
        .br_type(br_type_ID),
        .load_npc(load_npc_ID),
        .wb_select(wb_select_ID),
        .load_type(load_type_ID),
        .src_reg_en(src_reg_en_ID),
        .reg_write_en(reg_write_en_ID),
        .cache_write_en(cache_write_en_ID),
        .alu_src1(alu_src1_ID),
        .alu_src2(alu_src2_ID),
        .imm_type(imm_type),
        .csr_write(csr_write_ID),
        .csr_read(csr_read_ID),
        .csr_set(csr_set_ID),
        .csr_clear(csr_clear_ID),
        .csr_select(csr_select_ID),
        .rd_req(rd_req_ID)
    );

    ImmExtend ImmExtend1(
        .inst(inst_ID[31:7]),
        .imm_type(imm_type),
        .imm(imm)
    );

    PC_EX PC_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .PC_ID(PC_ID),
        .PC_EX(PC_EX)
    );

    BR_Target_EX BR_Target_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .address(jal_target),
        .address_EX(br_target)
    );

    Op1_EX Op1_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .reg1(reg1),
        .reg1_EX(reg1_EX)
    );

    Op2_EX Op2_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .op2(op2),
        .reg_or_imm(reg_or_imm)
    );

    Reg2_EX Reg2_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .reg2(reg2),
        .reg2_EX(reg2_EX)
    );

    Addr_EX Addr_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .reg1_src_ID(inst_ID[19:15]),
        .reg2_src_ID(inst_ID[24:20]),
        .reg_dest_ID(inst_ID[11:7]),
        .reg1_src_EX(reg1_src_EX),
        .reg2_src_EX(reg2_src_EX),
        .reg_dest_EX(reg_dest_EX)
    );



    Ctrl_EX Ctrl_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .jalr_ID(jalr_ID),
        .ALU_func_ID(ALU_func_ID),
        .br_type_ID(br_type_ID),
        .load_npc_ID(load_npc_ID),
        .wb_select_ID(wb_select_ID),
        .load_type_ID(load_type_ID),
        .src_reg_en_ID(src_reg_en_ID),
        .reg_write_en_ID(reg_write_en_ID),
        .cache_write_en_ID(cache_write_en_ID),
        .alu_src1_ID(alu_src1_ID),
        .alu_src2_ID(alu_src2_ID),
        .jalr_EX(jalr_EX),
        .ALU_func_EX(ALU_func_EX),
        .br_type_EX(br_type_EX),
        .load_npc_EX(load_npc_EX),
        .wb_select_EX(wb_select_EX),
        .load_type_EX(load_type_EX),
        .src_reg_en_EX(src_reg_en_EX),
        .reg_write_en_EX(reg_write_en_EX),
        .cache_write_en_EX(cache_write_en_EX),
        .alu_src1_EX(alu_src1_EX),
        .alu_src2_EX(alu_src2_EX),
        .found_ID(found_ID),
        .found_EX(found_EX)
    );

    // CSR pipeline register
    CSR_EX CSR_EX1(
        .clk(CPU_CLK),
        .bubbleE(bubbleE),
        .flushE(flushE),
        .CSR_ID(CSR_ID),
        .csr_reg1_ID(reg1),
        .csr_imm_ID(csr_imm_ID),
        .csr_wb_addr_ID(inst_ID[31:20]),
        .csr_rd_ID(inst_ID[11:7]),
        .csr_write_ID(csr_write_ID),
        .csr_read_ID(csr_read_ID),
        .csr_set_ID(csr_set_ID),
        .csr_clear_ID(csr_clear_ID),
        .csr_select_ID(csr_select_ID),
        .CSR_EX(CSR_EX),
        .csr_reg1_EX(csr_reg1_EX),
        .csr_imm_EX(csr_imm_EX),
        .csr_wb_addr_EX(csr_wb_addr_EX),
        .csr_rd_EX(csr_rd_EX),
        .csr_write_EX(csr_write_EX),
        .csr_read_EX(csr_read_EX),
        .csr_set_EX(csr_set_EX),
        .csr_clear_EX(csr_clear_EX),
        .csr_select_EX(csr_select_EX)
    );

    // ---------------------------------------------
    // EX stage
    // ---------------------------------------------

    ALU ALU1(
        .op1(ALU_op1),
        .op2(ALU_op2),
        .ALU_func(ALU_func_EX),
        .ALU_out(ALU_out)
    );

    CSR_ALU CSR_ALU1(
        .csr_op1(CSR_EX),
        .csr_op2(csr_alu_input),
        .csr_set(csr_set_EX),
        .csr_clear(csr_clear_EX),
        .csr_alu_out(csr_alu_out_EX)
    );

    BranchDecision BranchDecision1(
        .reg1(ALU_op1),
        .reg2(dealt_reg2),
        .br_type(br_type_EX),
        .br(br)
    );


    Result_MEM Result_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .result(result),
        .result_MEM(result_MEM)
    );

    Reg2_MEM Reg2_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .reg2_EX(dealt_reg2),
        .reg2_MEM(reg2_MEM)
    );

    Addr_MEM Addr_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .reg_dest_EX(reg_dest_EX),
        .reg_dest_MEM(reg_dest_MEM)
    );



    Ctrl_MEM Ctrl_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .wb_select_EX(wb_select_EX),
        .load_type_EX(load_type_EX),
        .reg_write_en_EX(reg_write_en_EX),
        .cache_write_en_EX(cache_write_en_EX),
        .wb_select_MEM(wb_select_MEM),
        .load_type_MEM(load_type_MEM),
        .reg_write_en_MEM(reg_write_en_MEM),
        .cache_write_en_MEM(cache_write_en_MEM)
    );

    // CSR pipeline register
    CSR_MEM CSR_MEM1(
        .clk(CPU_CLK),
        .bubbleM(bubbleM),
        .flushM(flushM),
        .CSR_EX(CSR_EX),
        .csr_alu_out_EX(csr_alu_out_EX),
        .csr_wb_addr_EX(csr_wb_addr_EX),
        .csr_rd_EX(csr_rd_EX),
        .csr_write_EX(csr_write_EX),
        .csr_read_EX(csr_read_EX),
        .csr_set_EX(csr_set_EX),
        .csr_clear_EX(csr_clear_EX),
        .csr_select_EX(csr_select_EX),
        .CSR_MEM(CSR_MEM),
        .csr_alu_out_MEM(csr_alu_out_MEM),
        .csr_wb_addr_MEM(csr_wb_addr_MEM),
        .csr_rd_MEM(csr_rd_MEM),
        .csr_write_MEM(csr_write_MEM),
        .csr_read_MEM(csr_read_MEM),
        .csr_set_MEM(csr_set_MEM),
        .csr_clear_MEM(csr_clear_MEM),
        .csr_select_MEM(csr_select_MEM)
    );

    // ---------------------------------------------
    // MEM stage
    // ---------------------------------------------


    WB_Data_WB WB_Data_WB1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .bubbleW(bubbleW),
        .flushW(flushW),
        .wb_select(wb_select_MEM),
        .load_type(load_type_MEM),
        .write_en(cache_write_en_MEM),
        .debug_write_en(CPU_Debug_DataCache_WE2),
        .addr(result_MEM),
        .debug_addr(CPU_Debug_DataCache_A2),
        .in_data(reg2_MEM),
        .debug_in_data(CPU_Debug_DataCache_WD2),
        .debug_out_data(CPU_Debug_DataCache_RD2),
        .data_WB(data_WB),
        .miss(CacheMiss),
        .rd_req(rd_req_ID)
    );


    Addr_WB Addr_WB1(
        .clk(CPU_CLK),
        .bubbleW(bubbleW),
        .flushW(flushW),
        .reg_dest_MEM(reg_dest_MEM),
        .reg_dest_WB(reg_dest_WB)
    );

    Ctrl_WB Ctrl_WB1(
        .clk(CPU_CLK),
        .bubbleW(bubbleW),
        .flushW(flushW),
        .reg_write_en_MEM(reg_write_en_MEM),
        .reg_write_en_WB(reg_write_en_WB)
    );

    // CSR pipeline register
    CSR_WB CSR_WB1(
        .clk(CPU_CLK),
        .bubbleW(bubbleW),
        .flushW(flushW),
        .CSR_MEM(CSR_MEM),
        .csr_alu_out_MEM(csr_alu_out_MEM),
        .csr_wb_addr_MEM(csr_wb_addr_MEM),
        .csr_rd_MEM(csr_rd_MEM),
        .csr_write_MEM(csr_write_MEM),
        .csr_read_MEM(csr_read_MEM),
        .csr_set_MEM(csr_set_MEM),
        .csr_clear_MEM(csr_clear_MEM),
        .csr_select_MEM(csr_select_MEM),
        .CSR_WB(CSR_WB),
        .csr_alu_out_WB(csr_alu_out_WB),
        .csr_wb_addr_WB(csr_wb_addr_WB),
        .csr_rd_WB(csr_rd_WB),
        .csr_write_WB(csr_write_WB),
        .csr_read_WB(csr_read_WB),
        .csr_set_WB(csr_set_WB),
        .csr_clear_WB(csr_clear_WB),
        .csr_select_WB(csr_select_WB)
    );

    // ---------------------------------------------
    // WB stage
    // ---------------------------------------------



    // ---------------------------------------------
    // Harzard Unit
    // ---------------------------------------------
    HarzardUnit HarzardUnit1(
        .rst(CPU_RST),
        .reg1_srcD(inst_ID[19:15]),
        .reg2_srcD(inst_ID[24:20]),
        .reg1_srcE(reg1_src_EX),
        .reg2_srcE(reg2_src_EX),
        .reg_dstE(reg_dest_EX),
        .reg_dstM(reg_dest_MEM),
        .reg_dstW(reg_dest_WB),
        .br(br),
        .jalr(jalr_EX),
        .jal(jal),
        .src_reg_en(src_reg_en_EX),
        .wb_select(wb_select_EX),
        .reg_write_en_MEM(reg_write_en_MEM),
        .reg_write_en_WB(reg_write_en_WB),
        .alu_src1(alu_src1_EX),
        .alu_src2(alu_src2_EX),
        .miss(CacheMiss),
        .fail(fail),
        .flushF(flushF),
        .bubbleF(bubbleF),
        .flushD(flushD),
        .bubbleD(bubbleD),
        .flushE(flushE),
        .bubbleE(bubbleE),
        .flushM(flushM),
        .bubbleM(bubbleM),
        .flushW(flushW),
        .bubbleW(bubbleW),
        .op1_sel(op1_sel),
        .op2_sel(op2_sel),
        .reg2_sel(reg2_sel)
    );  
    	         
endmodule