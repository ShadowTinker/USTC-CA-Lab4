`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Controller Decoder
// Tool Versions: Vivado 2017.4.1
// Description: Controller Decoder Module
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  对指令进行译码，将其翻译成控制信号，传输给各个部件
// 输入
    // Inst              待译码指令
// 输出
    // jal               jal跳转指令
    // jalr              jalr跳转指令
    // op2_src           ALU的第二个操作数来源。为1时，op2选择imm，为0时，op2选择reg2
    // ALU_func          ALU执行的运算类型
    // br_type           branch的判断条件，可以是不进行branch
    // load_npc          写回寄存器的值的来源（PC或者ALU计算结果）, load_npc == 1时选择PC
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果），wb_select == 1时选择cache内容
    // load_type         load类型
    // src_reg_en        指令中src reg的地址是否有效，src_reg_en[1] == 1表示reg1被使用到了，src_reg_en[0]==1表示reg2被使用到了
    // reg_write_en      通用寄存器写使能，reg_write_en == 1表示需要写回reg
    // cache_write_en    按字节写入data cache
    // imm_type          指令中立即数类型
    // alu_src1          alu操作数1来源，alu_src1 == 0表示来自reg1，alu_src1 == 1表示来自PC
    // alu_src2          alu操作数2来源，alu_src2 == 2’b00表示来自reg2，alu_src2 == 2'b01表示来自reg2地址，alu_src2 == 2'b10表示来自立即数
// 实验要求
    // 补全模块


`include "Parameters.v"   
module ControllerDecoder(
    input wire [31:0] inst,
    output wire jal,
    output wire jalr,
    output wire op2_src,
    output reg [3:0] ALU_func,
    output reg [2:0] br_type,
    output wire load_npc,
    output wire wb_select,
    output reg [2:0] load_type,
    output reg [1:0] src_reg_en,
    output reg reg_write_en,
    output reg [3:0] cache_write_en,
    output wire alu_src1,
    output wire [1:0] alu_src2,
    output reg [2:0] imm_type,
    output wire csr_write,//有效时写CSR
    output wire csr_read,//有效时读CSR
    output wire csr_set,//有效时set CSR相关位
    output wire csr_clear,//有效时clear CSR相关位
    output wire csr_select,//有效时选择imm作为CSR的输入，用于write,set或clear
    output wire rd_req//有效时读取cache
    );    

    assign jal = (inst[6:0] == 7'b1101111);
    assign jalr = (inst[6:0] == 7'b1100111);
    assign op2_src = !(inst[6:0] == 7'b0110011);
    assign load_npc = (inst[6:0] == 7'b1101111 || inst[6:0] == 7'b1100111);
    assign wb_select = (inst[6:0] == 7'b0000011);
    assign alu_src1 = (inst[6:0] == 7'b0010111);
    assign alu_src2 = (inst[6:0] == 7'b0010011) && ((inst[14:12] == 3'b001) || (inst[14:12] == 3'b101)) ? 2'b01 : ((inst[6:0] == 7'b0110011 || inst[6:0] == 7'b1100011) ? 2'b00 : 2'b10);

    assign csr_write =(inst[6:0] == 7'b1110011 && (((inst[14:12] == 3'b010 || inst[14:12] == 3'b011 || inst[14:12] == 3'b110 || inst[14:12] == 3'b111) && inst[19:15] != 5'b0) || (inst[14:12] == 3'b001 || inst[14:12] == 3'b101) )) ? 1'b1 :  1'b0;
    assign csr_read = (inst[6:0] == 7'b1110011 && (((inst[14:12] == 3'b001 || inst[14:12] == 3'b101) && inst[11:7] != 5'b0) || (inst[14:12] == 3'b010 || inst[14:12] == 3'b011 || inst[14:12] == 3'b110 || inst[14:12] == 3'b111))) ? 1'b1 :  1'b0;
    assign csr_set = (inst[6:0] == 7'b1110011 && (inst[14:12] == 3'b010 || inst[14:12] == 3'b110)) ? 1 : 0;
    assign csr_clear = (inst[6:0] == 7'b1110011 && (inst[14:12] == 3'b011 || inst[14:12] == 3'b111)) ? 1 : 0;
    assign csr_select = (inst[6:0] == 7'b1110011 && (inst[14:12] == 3'b001 || inst[14:12] == 3'b010 || inst[14:12] == 3'b011)) ? 0 : 1;

    assign rd_req = (inst[6:0] == 7'b0000011) ? 1 : 0;

    always@(*)
    begin
        case (inst[6:0]) //opcode
            7'b0110011: begin //R-type
                case (inst[14:12]) //funct3
                    3'b000: begin //ADD&SUB
                        case (inst[31:25])//funct7
                            7'b0000000: begin //ADD
                                ALU_func <= `ADD;//运算类型
                                br_type <= `NOBRANCH;//不进行跳转
                                load_type <= `NOREGWRITE;//不从Cache读数据写回寄存器
                                src_reg_en <= 2'b11;//用到了两个寄存器
                                reg_write_en <= 1'b1;//需要写回寄存器
                                cache_write_en <= 4'b0000;//不写到内存
                                imm_type <= `RTYPE;//立即数类型为RTYPE，表示不使用立即数
                            end
                            7'b0100000: begin //SUB
                                ALU_func <= `SUB;
                                br_type <= `NOBRANCH;
                                load_type <= `NOREGWRITE;
                                src_reg_en <= 2'b11;
                                reg_write_en <= 1'b1;
                                cache_write_en <= 4'b0000;
                                imm_type <= `RTYPE;
                            end
                            default: begin //illegal
                                ALU_func <= 4'bxxxx;
                                br_type <= 3'bxxx;
                                load_type <=3'bxxx;
                                src_reg_en <= 2'bxx;
                                reg_write_en <= 1'bx;
                                cache_write_en <= 4'bxxxx;
                                imm_type <= 3'bxxx;
                            end
                        endcase
                    end
                    3'b001: begin //SLL
                        ALU_func <= `SLL;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b010: begin //SLT
                        ALU_func <= `SLT;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b011: begin //SLTU
                        ALU_func <= `SLTU;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b100: begin //XOR
                        ALU_func <= `XOR;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b101: begin //SRL&SRA
                        case (inst[31:25])
                            7'b0000000: begin //SRL
                                ALU_func <= `SRL;
                                br_type <= `NOBRANCH;
                                load_type <= `NOREGWRITE;
                                src_reg_en <= 2'b11;
                                reg_write_en <= 1'b1;
                                cache_write_en <= 4'b0000;
                                imm_type <= `RTYPE;
                            end
                            7'b0100000: begin //SRA
                                ALU_func <= `SRA;
                                br_type <= `NOBRANCH;
                                load_type <= `NOREGWRITE;
                                src_reg_en <= 2'b11;
                                reg_write_en <= 1'b1;
                                cache_write_en <= 4'b0000;
                                imm_type <= `RTYPE;
                            end
                            default: begin
                                ALU_func <= 4'bxxxx;
                                br_type <= 3'bxxx;
                                load_type <=3'bxxx;
                                src_reg_en <= 2'bxx;
                                reg_write_en <= 1'bx;
                                cache_write_en <= 4'bxxxx;
                                imm_type <= 3'bxxx;
                            end
                        endcase
                    end
                    3'b110: begin //OR
                        ALU_func <= `OR;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b111: begin //AND
                        ALU_func <= `AND;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    default: begin
                        ALU_func <= 4'bxxxx;
                        br_type <= 3'bxxx;
                        load_type <=3'bxxx;
                        src_reg_en <= 2'bxx;
                        reg_write_en <= 1'bx;
                        cache_write_en <= 4'bxxxx;
                        imm_type <= 3'bxxx;
                    end
                endcase
            end
            7'b0010011: begin //I-type
                case (inst[14:12]) //funct3
                    3'b000: begin //ADDI
                        ALU_func <= `ADD;//运算类型
                        br_type <= `NOBRANCH;//不进行跳转
                        load_type <= `NOREGWRITE;//不从Cache读数据写回
                        src_reg_en <= 2'b10;//只用了reg1，没有用reg2
                        reg_write_en <= 1'b1;//需要写回寄存器
                        cache_write_en <= 4'b0000;//不写到Cache中
                        imm_type <= `ITYPE;//涉及的立即数为ITYPE立即数
                    end
                    3'b001: begin //SLLI
                        ALU_func <= `SLL;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    3'b010: begin //SLTI
                        ALU_func <= `SLT;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    3'b011: begin //SLTIU
                        ALU_func <= `SLTU;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    3'b100: begin //XORI
                        ALU_func <= `XOR;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    3'b101: begin //SRL&SRA
                        case (inst[31:25])
                            7'b0000000: begin //SRLI
                                ALU_func <= `SRL;
                                br_type <= `NOBRANCH;
                                load_type <= `NOREGWRITE;
                                src_reg_en <= 2'b10;
                                reg_write_en <= 1'b1;
                                cache_write_en <= 4'b0000;
                                imm_type <= `ITYPE;
                            end
                            7'b0100000: begin //SRAI
                                ALU_func <= `SRA;
                                br_type <= `NOBRANCH;
                                load_type <= `NOREGWRITE;
                                src_reg_en <= 2'b10;
                                reg_write_en <= 1'b1;
                                cache_write_en <= 4'b0000;
                                imm_type <= `ITYPE;
                            end
                            default: begin
                                ALU_func <= 4'bxxxx;
                                br_type <= 3'bxxx;
                                load_type <=3'bxxx;
                                src_reg_en <= 2'bxx;
                                reg_write_en <= 1'bx;
                                cache_write_en <= 4'bxxxx;
                                imm_type <= 3'bxxx;
                            end
                        endcase
                    end
                    3'b110: begin //ORI
                        ALU_func <= `OR;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    3'b111: begin //ANDI
                        ALU_func <= `AND;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    default: begin
                        ALU_func <= 4'bxxxx;
                        br_type <= 3'bxxx;
                        load_type <=3'bxxx;
                        src_reg_en <= 2'bxx;
                        reg_write_en <= 1'bx;
                        cache_write_en <= 4'bxxxx;
                        imm_type <= 3'bxxx;
                    end
                endcase
            end
            7'b0110111: begin //LUI
                ALU_func <= `LUI;//运算类型
                br_type <= `NOBRANCH;//不进行跳转
                load_type <= `NOREGWRITE;//不把Cache中数据写回寄存器
                src_reg_en <= 2'b00;//reg1和reg2都没有使用
                reg_write_en <= 1'b1;//需要写回寄存器
                cache_write_en <= 4'b0000;//不写Cache
                imm_type <= `UTYPE;//立即数类型为UTYPE
            end
            7'b0010111: begin //AUIPC
                ALU_func <= `ADD;
                br_type <= `NOBRANCH;
                load_type <= `NOREGWRITE;
                src_reg_en <= 2'b00;
                reg_write_en <= 1'b1;
                cache_write_en <= 4'b0000;
                imm_type <= `UTYPE;
            end
            7'b1101111: begin //JAL
                ALU_func <= `ADD;//ALU加
                br_type <= `NOBRANCH;//不进行条件跳转
                load_type <= `NOREGWRITE;//不把Cache结果写回
                src_reg_en <= 2'b00;//两个寄存器都不使用
                reg_write_en <= 1'b1;//需要写回寄存器
                cache_write_en <= 4'b0000;//不写Cache
                imm_type <= `JTYPE;//采用JTYPE立即数
            end
            7'b1100111: begin //JALR
                ALU_func <= `ADD;
                br_type <= `NOBRANCH;
                load_type <= `NOREGWRITE;
                src_reg_en <= 2'b10;
                reg_write_en <= 1'b1;
                cache_write_en <= 4'b0000;
                imm_type <= `ITYPE;
            end
            7'b1100011: begin //BRANCH
                case (inst[14:12])
                    3'b000: begin //BEQ
                        ALU_func <= `ADD;//无影响
                        br_type <= `BEQ;//分支类型为BEQ
                        load_type <= `NOREGWRITE;//无影响
                        src_reg_en <= 2'b11;//两个寄存器都要使用
                        reg_write_en <= 1'b0;//不写寄存器
                        cache_write_en <= 4'b0000;//不写Cache
                        imm_type <= `BTYPE;//采用B类立即数
                    end
                    3'b001: begin //BNE
                        ALU_func <= `ADD;
                        br_type <= `BNE;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b0;
                        cache_write_en <= 4'b0000;
                        imm_type <= `BTYPE;
                    end
                    3'b100: begin //BLT
                        ALU_func <= `ADD;
                        br_type <= `BLT;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b0;
                        cache_write_en <= 4'b0000;
                        imm_type <= `BTYPE;
                    end
                    3'b101: begin //BGE
                        ALU_func <= `ADD;
                        br_type <= `BGE;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b0;
                        cache_write_en <= 4'b0000;
                        imm_type <= `BTYPE;
                    end
                    3'b110: begin //BLTU
                        ALU_func <= `ADD;
                        br_type <= `BLTU;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b0;
                        cache_write_en <= 4'b0000;
                        imm_type <= `BTYPE;
                    end
                    3'b111: begin //BGEU
                        ALU_func <= `ADD;
                        br_type <= `BGEU;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b0;
                        cache_write_en <= 4'b0000;
                        imm_type <= `BTYPE;
                    end
                    default: begin
                        ALU_func <= 4'bxxxx;
                        br_type <= 3'bxxx;
                        load_type <=3'bxxx;
                        src_reg_en <= 2'bxx;
                        reg_write_en <= 1'bx;
                        cache_write_en <= 4'bxxxx;
                        imm_type <= 3'bxxx;
                    end
                endcase
            end
            7'b0000011: begin //LOAD
                case (inst[14:12])
                    3'b000: begin //LB
                        ALU_func <= `ADD;//需要执行加法
                        br_type <= `NOBRANCH;//不分支
                        load_type <= `LB;//Load类型LB
                        src_reg_en <= 2'b10;//只用reg1
                        reg_write_en <= 1'b1;//写寄存器
                        cache_write_en <= 4'b0000;//不写Cache
                        imm_type <= `ITYPE;//采用I类立即数
                    end
                    3'b001: begin //LH
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `LH;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    3'b010: begin //LW
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `LW;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    3'b100: begin //LBU
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `LBU;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    3'b101: begin //LHU
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `LHU;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `ITYPE;
                    end
                    default: begin
                        ALU_func <= 4'bxxxx;
                        br_type <= 3'bxxx;
                        load_type <=3'bxxx;
                        src_reg_en <= 2'bxx;
                        reg_write_en <= 1'bx;
                        cache_write_en <= 4'bxxxx;
                        imm_type <= 3'bxxx;
                    end
                endcase
            end
            7'b0100011: begin //STORE
                case (inst[14:12])
                    3'b000: begin //SB
                        ALU_func <= `ADD;//需要执行加法
                        br_type <= `NOBRANCH;//不分支
                        load_type <= `NOREGWRITE;//不把Cache中读到的数据写到寄存器
                        src_reg_en <= 2'b11;//reg1和reg2都要用
                        reg_write_en <= 1'b0;//不写寄存器
                        cache_write_en <= 4'b0001;//写Cache，长一个字节
                        imm_type <= `STYPE;//采用S类立即数
                    end 
                    3'b001: begin //SH
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b0;
                        cache_write_en <= 4'b0011;
                        imm_type <= `STYPE;
                    end
                    3'b010: begin //SW
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b11;
                        reg_write_en <= 1'b0;
                        cache_write_en <= 4'b1111;
                        imm_type <= `STYPE;
                    end
                    default: begin
                        ALU_func <= 4'bxxxx;
                        br_type <= 3'bxxx;
                        load_type <=3'bxxx;
                        src_reg_en <= 2'bxx;
                        reg_write_en <= 1'bx;
                        cache_write_en <= 4'bxxxx;
                        imm_type <= 3'bxxx;
                    end
                endcase
            end
            7'b1110011: begin //SYSTEM 只实现了CSR相关指令
                case (inst[14:12])
                    3'b001: begin //CSRRW
                        ALU_func <= `ADD;//不需要ALU操作，采用默认的ADD
                        br_type <= `NOBRANCH;//不branch
                        load_type <= `NOREGWRITE;//不把Cache中的内容写到寄存器
                        src_reg_en <= 2'b10;//需要使用到reg1的值
                        reg_write_en <= 1'b1;//需要写寄存器
                        cache_write_en <= 4'b0000;//不写Cache
                        imm_type <= `RTYPE;//不涉及到立即数
                    end
                    3'b010: begin //CSRRS
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b011: begin //CSRRC
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b10;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b101: begin //CSRRWI
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b00;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b110: begin //CSRRSI
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b00;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    3'b111: begin //CSRRCI
                        ALU_func <= `ADD;
                        br_type <= `NOBRANCH;
                        load_type <= `NOREGWRITE;
                        src_reg_en <= 2'b00;
                        reg_write_en <= 1'b1;
                        cache_write_en <= 4'b0000;
                        imm_type <= `RTYPE;
                    end
                    default: begin
                        ALU_func <= 4'bxxxx;
                        br_type <= 3'bxxx;
                        load_type <=3'bxxx;
                        src_reg_en <= 2'bxx;
                        reg_write_en <= 1'bx;
                        cache_write_en <= 4'bxxxx;
                        imm_type <= 3'bxxx;
                    end
                endcase
            end
            default: begin
                ALU_func <= 4'bxxxx;
                br_type <= 3'bxxx;
                load_type <=3'bxxx;
                src_reg_en <= 2'bxx;
                reg_write_en <= 1'bx;
                cache_write_en <= 4'bxxxx;
                imm_type <= 3'bxxx;
            end
        endcase
    end
    
endmodule
