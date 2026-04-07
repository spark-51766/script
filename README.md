# script

QPC 数据结构转 SystemVerilog 初始化代码工具集。

## 文件说明

| 文件 | 说明 |
|------|------|
| gen_init_qpc_task.py | Python 脚本，从 Excel 数据结构定义生成 	ask init_qpc SystemVerilog 代码 |
| init_qpc.sv | 生成的 SV 代码（seg 3~16 字段初始化，共 504 个字段） |

## 用法

`ash
# 默认路径
python gen_init_qpc_task.py

# 指定 Excel 文件
python gen_init_qpc_task.py path/to/your_file.xlsx
`

## 生成内容

- 	ask init_qpc(ref hca_qpc, input bit veroce_en) — 无 mq_reg 参数
- seg 3~16 共 504 个字段，每个字段包含：
  - 域段初始值（支持 veRoCE 条件三元表达式）
  - seg0 内部交叉引用（hca_qpc.qpc_seg00.xxx）
  - 域段描述注释
