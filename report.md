# 计算机体系结构Lab3实验报告

<h6 align="right">PB17061179-尹铭佳</h6>

## 实验目标

* 实现BTB（Branch Target Buffer）和BHT（Branch History Table）两种动态分支预测器

* 体会动态分支预测对流水线性能的影响

## 实验环境

* 系统：Windows10
* 实验工具：VSCode+Vivado2018.3

## 实验内容

### 阶段一

> * 阶段目标
>   * 实现一个BTB
>   * 测试Mat Multiple和Quick Sort算法
> * 实现细节
>   * 增加一个BTB模块
>   * IF
>     * 增加一条把PC发给BTB的线
>     * 增加一个流水段寄存器传递的信号found用于判断该PC是否存在BTB中。found信号由BTB产生
>     * 增加一条BTB到NPC Generator的线，替换原来的PC+4到NPC Generator的线。用于传递found信号和预测PC值
>       * 如果state bit为0，那么预测PC为PC+4
>       * 如果state bit为1，那么预测PC为BTB中存储的Branch Target
>   * ID
>     * 传递found信号给EX阶段
>   * EX
>     * 增加从流水段寄存器中的branch，found和PC、branch target、br到BTB的线，用于判断是否保存未保存的指令跳转结果
>       * 如果branch无效但是found有效，那么不进行任何处理
>       * 如果branch有效且found无效，那么增加一个表项，记录PC和branch_target，并根据br来设置BTB该表项的初值（与br相同）——在这一步中，有可能会有tag相同的分支指令的Buffer替换行为发生
>     * 增加从PC和br到BTB的线
>       * 如果无冲突
>         * 如果br和BTB中对应的state bit的值相同
>           * fail信号设定无效
>         * 如果br和BTB中对应的state bit的值不同
>           * 翻转state bit
>           * 预测失败，设定fail信号
>     * 增加从BTB到Hazard的线传递fail信号，如果分支预测失败，那么需要flush掉前IF和ID阶段的流水段。并且去除掉原本branch对应的hazard处理

### 阶段二

> * 阶段目标
>   * 在一阶段的基础上实现一个BHT
>   * 对BTB和BHT做各种分析
>   
> * 实现细节
>   * 在BTB的“内部”实现一个BHT模块
>     * BHT实际是一个2-bit的数组
>     * 需要提供一个查询是否跳转的接口
>     * 需要实现在EX阶段针对跳转结果的状态机更新
>     * 因为BHT只提供一个预测跳还是不跳的状态机，因此对于tag冲突的现象不需要特别处理。发生冲突的后果仅仅是带来少许分之代价而已
>   * 修改BTB的逻辑——原来预测跳转只需要state bit为1即可，现在需要state bit为1和BHT预测跳转
>   
> * BHT逻辑表
>
>   | BTB  | BHT  | REAL | NPC_PRED | flush | NPC_REAL | BTB update |
>   | :--: | :--: | :--: | :------: | :---: | :------: | :--------: |
>   |  Y   |  Y   |  Y   |   BUF    |   N   |   BUF    |     N      |
>   |  Y   |  Y   |  N   |   BUF    |   Y   | PC_EX+4  |     Y      |
>   |  Y   |  N   |  Y   | PC_IF+4  |   Y   |   BUF    |     N      |
>   |  Y   |  N   |  N   | PC_IF+4  |   N   | PC_EX+4  |     Y      |
>   |  N   |  Y   |  Y   | PC_IF+4  |   Y   |   BUF    |     Y      |
>   |  N   |  Y   |  N   | PC_IF+4  |   N   | PC_EX+4  |     N      |
>   |  N   |  N   |  Y   | PC_IF+4  |   Y   |   BUF    |     Y      |
>   |  N   |  N   |  N   | PC_IF+4  |   N   | PC_EX+4  |     N      |

### 分支预测分析

> 结合指BTB+BHT

| 测试程序 | 策略 | 分支收益 | 分支代价 | 周期 | 预测后周期 | 差值 | 分支指令数 | 正确 | 错误 |
| :------: | :--: | :------: | :------: | :--: | :--------: | :--: | :--------: | :--: | :--: |
|   快排   | BTB  |          |          |      |            |      |            |      |      |
|   快排   | 结合 |          |          |      |            |      |            |      |      |
|   矩阵   | BTB  |          |          |      |            |      |            |      |      |
|   矩阵   | 结合 |          |          |      |            |      |            |      |      |
|   BTB    | BTB  |          |          |      |            |      |            |      |      |
|   BTB    | 结合 |          |          |      |            |      |            |      |      |
|   BHT    | BTB  |          |          |      |            |      |            |      |      |
|   BHT    | 结合 |          |          |      |            |      |            |      |      |

## 实验总结

### 收获

### 踩坑

### 花费时间分布

## 改进建议

