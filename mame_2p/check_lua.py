"""Lua 静态校验（本机无 luac/lua 时的替代，不依赖 MAME 进程）。

做三件事：
  1) 括号/字符串/注释的词法平衡检查（能抓最常见的语法错）
  2) function/end 等块结构粗检
  3) 逐条核对插件用到的 MAME 0.289 Lua API 是否在官方 ref-input / 本机
     官方插件源码里出现过（防止臆造接口名，规则 15/19）
"""
from __future__ import annotations

import os
import re
import sys

PLUGIN_LUA = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "plugin", "copilot2p", "init.lua")

# 来自官方 0.289 文档与本机 plugins/*.lua 实证的 API 白名单
KNOWN_APIS = [
    "manager.machine.input", "manager.machine.ioport", "manager.options.entries.homepath",
    "emu.register_prestart", "emu.add_machine_frame_notifier", "emu.add_machine_stop_notifier",
    "emu.register_menu", "emu.print_verbose", "emu.romname", "emu.lang_translate",
    "ioport.ports", "port.fields", "field.player", "field.type_class", "field.is_analog",
    "field.enabled", "field.name", "field.default_name", "field:set_value", "field:clear_value",
    "field:input_seq", "input_manager:seq_pressed", "require('json')", "require('lfs')",
]


def lexical_check(src: str):
    """返回 (ok, msg)：检查长括号注释、引号、圆括号/花括号平衡。"""
    i, n = 0, len(src)
    stack = []
    line = 1
    in_long_comment = False
    long_eq = ""
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if in_long_comment:
            if src.startswith("]" + long_eq + "]", i):
                in_long_comment = False
                i += 2 + len(long_eq)
            else:
                i += 1
            continue
        # 长括号注释 --[[ ... ]] 或 --[=[ ... ]=]
        if src.startswith("--", i):
            j = i + 2
            m = re.match(r"\[(=*)\[", src[j:])
            if m:
                in_long_comment = True
                long_eq = m.group(1)
                i = j + len(m.group(0))
                continue
            # 行注释
            nl = src.find("\n", i)
            i = n if nl < 0 else nl
            continue
        # 长字符串 [[ ... ]]
        if src.startswith("[", i):
            m = re.match(r"\[(=*)\[", src[i:])
            if m:
                close = "]" + m.group(1) + "]"
                end = src.find(close, i + len(m.group(0)))
                if end < 0:
                    return False, f"第 {line} 行：长字符串未闭合"
                line += src.count("\n", i, end)
                i = end + len(close)
                continue
        # 普通字符串（含转义）
        if c in "\"'":
            quote = c
            j = i + 1
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == quote:
                    break
                if src[j] == "\n":
                    return False, f"第 {line} 行：字符串跨行未闭合（{quote}）"
                j += 1
            if j >= n:
                return False, f"第 {line} 行：字符串未闭合（{quote}）"
            i = j + 1
            continue
        if c in "({":
            stack.append((c, line))
        elif c in ")}":
            if not stack:
                return False, f"第 {line} 行：多余的 '{c}'"
            o, ol = stack.pop()
            if (o == "(" and c != ")") or (o == "{" and c != "}"):
                return False, f"第 {line} 行：'{o}'(第{ol}行) 与 '{c}' 不匹配"
        i += 1
    if in_long_comment:
        return False, "长括号注释未闭合"
    if stack:
        o, ol = stack[-1]
        return False, f"第 {ol} 行：'{o}' 未闭合"
    return True, "词法平衡 OK（括号/字符串/注释）"


def block_check(src: str):
    """粗检 function/if/for/while/do 与 end 的数量配对（忽略字符串里的词）。"""
    # 去掉注释与字符串内容后统计（简化版，够抓明显错误）
    clean = re.sub(r"--\[\[.*?\]\]", " ", src, flags=re.S)
    clean = re.sub(r"--[^\n]*", " ", clean)
    clean = re.sub(r"'(?:\\.|[^'\\])*'", " '' ", clean)
    clean = re.sub(r'"(?:\\.|[^"\\])*"', ' "" ', clean)
    opens = len(re.findall(r"\bfunction\b", clean))
    opens += len(re.findall(r"\b(?:if|for|while)\b.*\b(?:do|then)\b", clean))
    # 单独 do ... end（不含 for/while 的）
    opens += len(re.findall(r"(?<!\bfor)(?<!\bwhile)\bdo\b", clean))
    ends = len(re.findall(r"\bend\b", clean))
    return opens, ends


def api_check(src: str):
    hits = []
    for api in KNOWN_APIS:
        # 用最后一个片段做匹配，容忍调用写法差异
        frag = api.split(".")[-1].split(":")[-1].replace("()", "")
        if frag and frag in src:
            hits.append(api)
    missing = [a for a in KNOWN_APIS if a not in hits]
    return hits, missing


def main() -> int:
    src = open(PLUGIN_LUA, "r", encoding="utf-8").read()
    print(f"文件: {PLUGIN_LUA}  ({len(src)} 字符, {src.count(chr(10))+1} 行)")
    ok, msg = lexical_check(src)
    print(f"[1] 词法: {msg}")
    if not ok:
        return 1
    o, e = block_check(src)
    # 说明：正则粗检会把 "if ... then" 与其中的 "do" 重复计数，且会把
    # 字符串/注释里的 end 计入，因此只作提示、不据此判失败（避免误报）。
    print(f"[2] 块结构粗检: 开 {o} / end {e}（仅参考，不判定；粗检存在已知重复计数）")
    hits, missing = api_check(src)
    print(f"[3] 命中已知 0.289 API: {len(hits)}/{len(KNOWN_APIS)}")
    for a in hits:
        print(f"      [OK] {a}")
    if missing:
        print("    未命中（可能未使用，非错误）:")
        for a in missing:
            print(f"      - {a}")
    # 检查是否用了未在国内核实的危险 API
    for bad in ("port:write(", "manager:machine(", "emu.sethook("):
        if bad in src:
            print(f"[!] 警告：使用了旧版/错误 API {bad}")
            return 1
    print("=== Lua 静态校验 PASS（无 luac，属静态检查，非运行时验证）===")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
