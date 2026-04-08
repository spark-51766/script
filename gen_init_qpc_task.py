#!/usr/bin/env python3
"""
Generate task init_qpc SystemVerilog initialization code from QPC sheet.

Usage:
    python gen_init_qpc_task.py                          # use default path
    python gen_init_qpc_task.py "path/to/file.xlsx"      # specify Excel file

Output:
    init_qpc.sv  - task init_qpc (seg 3~16 field initialization)
"""

import re
import sys
from pathlib import Path

import pandas as pd

DEFAULT_XLSX = Path(
    r"F:/电子笔记/电子笔记/02-众星微项目/04-天蝎RoCE/04-数据结构/天蝎RDMA数据结构v3.83.xlsx"
)
SHEET = "QPC"

# 只生成这些 seg 的初始化代码
TARGET_SEGS = set(range(3, 17))   # seg 3 ~ 16


# ──────────────────────────── 工具函数 ─────────────────────────

def hex_to_decimal(s) -> int | None:
    if not isinstance(s, str):
        return None
    s = re.sub(r"\s+", "", s.strip())
    m = re.match(r"^(0x)?([0-9a-fA-F]+)h?$", s)
    if m:
        return int(m.group(2), 16)
    return None


def sanitize(name: str) -> str:
    """清洗成合法 SV 标识符（小写）。"""
    name = re.sub(r"[：:()（）\[\]．.。·\-–]", "_", name)
    name = re.sub(r"[^a-zA-Z0-9_]", "_", name)
    name = name.strip("_").lower()
    name = re.sub(r"_+", "_", name)
    if name.startswith("_"):
        name = "f" + name
    RESERVED = {
        "module", "input", "output", "inout", "parameter", "localparam",
        "assign", "always", "initial", "begin", "end", "if", "else",
        "case", "endcase", "for", "while", "function", "endfunction",
        "task", "endtask", "logic", "reg", "wire", "bit", "byte",
        "int", "integer", "real", "struct", "union", "enum", "typedef",
        "package", "import", "export", "class", "endclass",
        "constraint", "default", "extends", "virtual", "pure",
        "static", "automatic", "generate", "endgenerate",
        "posedge", "negedge", "or", "ref", "const", "null",
        "type", "covergroup", "coverpoint", "cross",
    }
    if name.lower() in RESERVED:
        name += "_r"
    return name or "reserved"


def parse_init_expr(raw, field_name: str = "") -> str:
    """
    解析初始值列，返回 SV 赋值右值表达式（不含分号）。
    
    参数:
        raw: 原始初始值
        field_name: 字段名（用于特殊处理）
        
    规则：
      - 纯数字 0     → "'0"
      - 纯数字 1     → "'1"
      - 纯数字 N     → SV hex 字面量
      - veRoCE 条件   → 三元表达式  veroce_en ? ... : ...
      - sw.send_start_psn → hca_qpc.qpc_seg0.send_start_psn
      - seg0.send_start_psn → hca_qpc.qpc_seg0.send_start_psn
      - seg0.rcv_start_psn → hca_qpc.qpc_seg0.rcv_start_psn
      - mq_reg.xxx 引用 → mq_reg.xxx
      - txwqe_rsp_newest_psn 的 hca_qpc.send_start_psn-1 → hca_qpc.qpc_seg0.rcv_start_psn - 1
      - 其他 hca_qpc.send_start_psn → hca_qpc.qpc_seg0.send_start_psn
      - 其他复杂表达式 → 保留注释
    """
    if pd.isna(raw):
        return "'0"

    s = str(raw).strip().replace("\n", " ").replace("\\n", " ")
    s = re.sub(r"\s+", " ", s).strip()
    if not s:
        return "'0"

    # ════════════ 0. 特殊字段处理：txwqe_rsp_newest_psn ════════════
    # 规则: hca_qpc.send_start_psn-1 → hca_qpc.qpc_seg0.rcv_start_psn - 1
    if field_name == "txwqe_rsp_newest_psn" and "send_start_psn" in s:
        # hca_qpc.send_start_psn-1 → hca_qpc.qpc_seg0.rcv_start_psn - 1
        expr = re.sub(r"hca_qpc\.send_start_psn\s*-\s*1", 
                      r"hca_qpc.qpc_seg0.rcv_start_psn - 1", s)
        return expr

    # ════════════ 1. veRoCE 条件表达式 ════════════
    # 模式: "veRoCE场景初始化为EXPR；非veRoCE场景初始化为DEFAULT"
    #       或: "veRoCE为...；非veRoCE为..."
    veroce_pat = re.compile(
        r"veRoCE[场景]*[初始化为]*\s*(.+?)[\s；;]*非veRoCE[场景]*[初始化为]*\s*(.+)",
        re.IGNORECASE,
    )
    m = veroce_pat.search(s)
    if m:
        true_expr = _clean_veroce_expr(m.group(1))
        false_expr = _clean_veroce_expr(m.group(2))
        # 如果 false 也是 0，用 '0 更简洁
        false_sv = _expr_to_sv(false_expr) if false_expr.strip() not in ("0", "'0") else "'0"
        return f"veroce_en ? {true_expr} : {false_sv}"

    # ════════════ 2. rcv_start_psn 条件 bitmap (rxt_req_bitmap) ════════════
    if "?" in s and ("rcv_start_psn" in s or "bitmap" in s.lower()):
        # 原始: rcv_start_psn[8] ? ({256{1'b1}} << rcv_start_psn[7:0]) : ~({256{1'b1}} << rcv_start_psn[7:0])
        cleaned = s.replace("\n", "").replace(" ", "")
        # 尽量还原成可读的 SV 表达式
        return f"// TODO(manual): {s}"

    # ════════════ 3. 部分条件 (如 rxi_sr_time 低24bit) ════════════
    if "低" in s and "veRoCE" in s:
        m = veroce_pat.search(s)
        if m:
            true_e = _clean_veroce_expr(m.group(1))
            return f"veroce_en ? {true_e} : '0  // NOTE: 仅部分 bit"

    # ════════════ 4. sw.send_start_psn → hca_qpc.qpc_seg0.send_start_psn ════════════
    if re.match(r"^sw\.send_start_psn$", s):
        return "hca_qpc.qpc_seg0.send_start_psn"

    # 4b. sw.send_start_psn-1 → hca_qpc.qpc_seg0.send_start_psn-1
    sw_send_ops = re.match(r"^sw\.send_start_psn\s*-\s*(\d+)$", s)
    if sw_send_ops:
        return f"hca_qpc.qpc_seg0.send_start_psn - {sw_send_ops.group(1)}"

    # ════════════ 4c. 裸 send_start_psn（无前缀）→ hca_qpc.qpc_seg0.send_start_psn ════════════
    if s == "send_start_psn":
        return "hca_qpc.qpc_seg0.send_start_psn"

    # 4d. send_start_psn-1 → hca_qpc.qpc_seg0.send_start_psn-1
    send_ops = re.match(r"^send_start_psn\s*-\s*(\d+)$", s)
    if send_ops:
        return f"hca_qpc.qpc_seg0.send_start_psn - {send_ops.group(1)}"

    # ════════════ 5. seg0.send_start_psn / seg0.rcv_start_psn → hca_qpc.qpc_seg0.xxx ════════════
    seg0_m = re.match(r"^seg0\.(send_start_psn|rcv_start_psn)$", s)
    if seg0_m:
        return f"hca_qpc.qpc_seg0.{seg0_m.group(1)}"

    # 5b. seg0.xxx-1 → hca_qpc.qpc_seg0.xxx - 1（带空格）⚠️必须在 ref_patterns 之前
    seg0_ops = re.match(r"^seg0\.(\w+)\s*-\s*(\d+)$", s)
    if seg0_ops:
        return f"hca_qpc.qpc_seg0.{seg0_ops.group(1)} - {seg0_ops.group(2)}"

    # ════════════ 6. hca_qpc.send_start_psn → hca_qpc.qpc_seg0.send_start_psn ════════════
    if s == "hca_qpc.send_start_psn":
        return "hca_qpc.qpc_seg0.send_start_psn"
    
    # 带运算的 hca_qpc.send_start_psn-1 → hca_qpc.qpc_seg0.send_start_psn-1
    hca_send_ops = re.match(r"^(hca_qpc\.send_start_psn)\s*-\s*(\d+)$", s)
    if hca_send_ops:
        return f"hca_qpc.qpc_seg0.send_start_psn - {hca_send_ops.group(2)}"

    # ════════════ 7. 其他 sw.xxx / seg0.xxx / hca_qpc.start_ssn 引用 ════════════
    # 字段名映射: mq_reg 中的字段名 → hca_qpc 中的实际字段名
    FIELD_MAP = {
        "cfg_start_ssn": "start_ssn",
    }

    ref_patterns = [
        (r"^sw\.\w+$", None),
        (r"^seg0\.\w+", "hca_qpc.qpc_seg0"),
        # mq_reg.cfg_start_ssn[...] / -1 等变体 → hca_qpc.start_ssn...
        (r"^mq_reg\.cfg_start_ssn(\[.*?\])?(-\d+)?$", "hca_qpc"),
        (r"^mq_reg\.cfg_start_ssn$", "hca_qpc.start_ssn"),
        # 其他 mq_reg 字段 → hca_qpc.xxx
        (r"^mq_reg\.\w+(\[.*?\])?(\(.*?\))?$", "hca_qpc"),
    ]
    for pat, prefix in ref_patterns:
        if re.match(pat, s):
            if prefix:
                dot_part = s.split(".", 1)[1] if "." in s else s
                clean_name = re.sub(r"\(.*?\)", "", dot_part).strip()
                # 映射字段名（如 cfg_start_ssn → start_ssn）
                base_name = clean_name.split("[")[0].split("-")[0]
                mapped = FIELD_MAP.get(base_name, clean_name)
                if mapped != clean_name:
                    suffix = clean_name[len(base_name):]  # 保留 [8:0]、-1 等
                    return f"{prefix}.{mapped}{suffix}"
                return f"{prefix}.{clean_name}"
            return s

    # 7b. seg0.xxx-1 等带运算的引用 → hca_qpc.qpc_seg0.xxx 形式
    seg0_calc = re.match(r"^seg0\.(\w+)\s*-\s*(\d+)$", s)
    if seg0_calc:
        return f"hca_qpc.qpc_seg0.{seg0_calc.group(1)} - {seg0_calc.group(2)}"

    # 7c. seg0.xxx → hca_qpc.qpc_seg0.xxx
    seg0_simple = re.match(r"^seg0\.(\w+)$", s)
    if seg0_simple:
        return f"hca_qpc.qpc_seg0.{seg0_simple.group(1)}"

    # 7d. mq_reg.xxx-1 等带运算的引用
    calc_ref = re.match(r"^mq_reg\.(\S+)\s*-\s*(\d+)$", s)
    if calc_ref:
        rest_clean = re.sub(r"\(.*?\)", "", calc_ref.group(1)).strip()
        if "cfg_start_ssn" in rest_clean:
            tail = rest_clean.replace("cfg_start_ssn", "")
            return f"hca_qpc.start_ssn - {calc_ref.group(2)}"
        return f"hca_qpc.{rest_clean} - {calc_ref.group(2)}"

    # 7e. 其他 mq_reg.xxx → hca_qpc.xxx
    calc_ref = re.match(r"^mq_reg\.(\S+)$", s)
    if calc_ref:
        rest_clean = re.sub(r"\(.*?\)", "", calc_ref.group(1)).strip()
        if "cfg_start_ssn" in rest_clean:
            return f"hca_qpc.start_ssn"
        return f"hca_qpc.{rest_clean}"

    # ════════════ 8. 纯数字 ════════════
    try:
        val = int(s)
        if val == 0:
            return "'0"
        if val == 1:
            return "'1"
        if val < 0:
            return str(val)
        if val > 255:
            return f"16'h{val:04x}"
        return f"8'h{val:02x}"
    except ValueError:
        pass

    # ════════════ 9. SV 字面量 ════════════
    sv_lit_m = re.match(r"^(\d+)'h([0-9a-fA-F]+)$", s)
    if sv_lit_m:
        w, v = int(sv_lit_m.group(1)), int(sv_lit_m.group(2), 16)
        return f"{w}'h{v:x}"

    sv_bin_m = re.match(r"^(\d+)'b([01]+)$", s)
    if sv_bin_m:
        return s

    # ════════════ 10. 含默认值的说明文字 ════════════
    # 例: "mq_reg.cfg_start_ssn(默认1)" → hca_qpc.start_ssn
    def_m = re.match(r"^(mq_reg\.cfg_start_ssn)\(默认\d+\)$", s)
    if def_m:
        return "hca_qpc.start_ssn"

    # ════════════ 11. 其他 → 注释兜底 ════════════
    return f"'0  // init: {s}"


def _clean_veroce_expr(expr: str) -> str:
    """
    清理 veRoCE 场景的表达式片段。
    输入示例:
      "mq_reg.cfg_start_ssn[8:0]-1"
      "mq_reg.cfg_start_ssn-1"
      "{8'b0,mq_reg.cfg_start_ssn-1}"
      "{8'b0,seg0.rcv_start_psn-1}"
      "1"
    """
    e = expr.strip()
    # seg0.XXX → hca_qpc.qpc_seg0.XXX（注意是 seg0 不是 seg00）
    e = re.sub(r"\bseg0\.(\w+)", r"hca_qpc.qpc_seg0.\1", e)
    # mq_reg.cfg_start_ssn → hca_qpc.start_ssn（含位选、运算等变体）
    e = re.sub(r"mq_reg\.cfg_start_ssn", r"hca_qpc.start_ssn", e)
    return e


def _expr_to_sv(expr: str) -> str:
    """将简单表达式转为 SV 字面量或引用。"""
    expr = expr.strip()
    try:
        val = int(expr)
        if val == 0:
            return "'0"
        if val == 1:
            return "'1"
        return f"{val}"
    except ValueError:
        return expr


# ──────────────────────────── 主逻辑 ────────────────────────────

def load_sheet(path: Path, sheet: str) -> pd.DataFrame:
    df = pd.read_excel(path, sheet_name=sheet, header=0)
    df = df.dropna(how="all").reset_index(drop=True)

    df["_off_num"] = df["Offset"].apply(hex_to_decimal)
    df["_off_num"] = df["_off_num"].ffill()
    df["MSB"]  = pd.to_numeric(df["MSB"],  errors="coerce")
    df["LSB"]  = pd.to_numeric(df["LSB"],  errors="coerce")
    df["位宽"] = pd.to_numeric(df["位宽"], errors="coerce")
    df["_seg"] = pd.to_numeric(df["seg_num"], errors="coerce")
    return df


def build_task(df: pd.DataFrame, xlsx_name: str) -> str:
    """生成 task init_qpc 的 SystemVerilog 代码。"""
    # 过滤目标 seg，排除 rsv 字段，排除初始值为空的字段
    work_df = df[df["_seg"].isin(TARGET_SEGS)].copy()
    work_df = work_df[
        work_df["信号名"].apply(lambda n: pd.notna(n) and str(n).strip().lower() != "rsv")
    ]
    work_df = work_df[
        work_df["初始值"].apply(lambda v: pd.notna(v) and str(v).strip() != "")
    ]

    total_fields = len(work_df)
    out: list[str] = []

    def ln(s=""):
        out.append(s)

    # ════════════ File header ════════════
    ln("// ==============================================================")
    ln("//  task init_qpc  - QPC initialization (seg 3~16, exclude rsv fields and empty init values)")
    ln(f"//  Source : {xlsx_name}  Sheet: {SHEET}")
    ln(f"//  Total fields: {total_fields}")
    ln(f"//  Range: seg {min(TARGET_SEGS)} ~ {max(TARGET_SEGS)} (skip seg 0,1,2)")
    ln("// ==============================================================")
    ln()
    ln("task init_qpc(")
    ln("    ref rdma_rxe_qpc_extends hca_qpc,")
    ln("    input bit                  veroce_en")
    ln(");")

    # 按 seg 分组，每个 seg 内按原始行顺序输出
    prev_seg = None
    for _, r in work_df.iterrows():
        seg = int(r["_seg"])
        name = str(r.get("信号名", "")).strip() if pd.notna(r.get("信号名")) else "rsv"
        sv_name = sanitize(name)
        init_raw = r.get("初始值")
        rhs = parse_init_expr(init_raw, field_name=sv_name)

        # seg 分组注释
        if seg != prev_seg:
            ln()
            ln(f"    // ── seg {seg:02d} ──")
            prev_seg = seg

        seg_name = f"qpc_seg{seg}"
        # 描述中的换行/回车等替换为空格，避免断行破坏SV语法
        desc = str(r.get("描述", "")).replace('\n', ' ').replace('\r', ' ').strip() if pd.notna(r.get("描述")) else ""
        if desc:
            line = f"    hca_qpc.{seg_name}.{sv_name} = {rhs};  // {desc}"
        else:
            line = f"    hca_qpc.{seg_name}.{sv_name} = {rhs};"
        ln(line)

    ln()
    ln("endtask")
    ln()

    return "\n".join(out)


def main():
    xlsx_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_XLSX
    xlsx_name = xlsx_path.name
    out_dir   = Path(__file__).parent.resolve()  # 输出到脚本同目录

    print(f"[gen_init_qpc_task] Reading  {xlsx_path}  sheet={SHEET}")
    df = load_sheet(xlsx_path, SHEET)
    print(f"  Total fields   : {len(df)}")
    print(f"  Target seg     : {sorted(TARGET_SEGS)}")

    work_df = df[df["_seg"].isin(TARGET_SEGS)].copy()
    work_df = work_df[
        work_df["信号名"].apply(lambda n: pd.notna(n) and str(n).strip().lower() != "rsv")
    ]
    work_df = work_df[
        work_df["初始值"].apply(lambda v: pd.notna(v) and str(v).strip() != "")
    ]
    print(f"  Generated       : {len(work_df)} (exclude rsv and empty init values)")

    code = build_task(df, xlsx_name)
    out_path = out_dir / "init_qpc.sv"
    out_path.write_text(code, encoding="utf-8")
    print(f"  Output      {out_path}  ({code.count(chr(10))} lines)")


if __name__ == "__main__":
    main()
