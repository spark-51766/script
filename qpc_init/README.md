# qpc_init

QPC 数据结构转 SystemVerilog 初始化代码工具集。

## 文件说明

| 文件 | 说明 |
|------|------|
| gen_init_qpc_task.py | Python 脚本，从 Excel 数据结构定义生成 	ask init_qpc SystemVerilog 代码 |
| init_qpc.sv | 生成的 SV 代码（seg 3~16 字段初始化，排除 rsv 字段，共 458 个字段） |

## 用法

`ash
python gen_init_qpc_task.py
`

## 生成内容

- 	ask init_qpc(ref hca_qpc, input bit veroce_en)
- seg 3~16 共 458 个字段，每个字段包含域段初始值及描述注释
