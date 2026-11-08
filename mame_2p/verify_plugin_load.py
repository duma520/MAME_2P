"""零侵入验证：复刻 MAME 0.289 的插件发现/加载前置检查。

不启动 MAME、不碰你正在跑的游戏。依据本机 plugins/boot.lua 的实际逻辑：
  * 从 mame.ini 的 pluginspath 取插件根目录
  * 遍历子目录，读 plugin.json，取 plugin.name
  * 按 plugin.ini 的 <name> 值决定是否 startplugin
  * boot.lua 里 `plugin = require(entry.name)` + `plugin.startplugin()`
    → 因此 <插件根>/<name>/init.lua 必须存在且 return 一个含 startplugin 的表

本脚本只做静态一致性检查 + JSON 契约校验 + Lua 顶层结构校验，
并输出「MAME 侧实际会看到什么」。
"""
from __future__ import annotations

import json
import os
import re
import sys

DEFAULT_MAME_HOME = r"\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui"
PLUGIN_NAME = "copilot2p"


def read_text(p):
    with open(p, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def parse_ini_value(path, key):
    """从 mame.ini 读形如 `pluginspath  plugins` 的值（忽略注释）。"""
    if not os.path.isfile(path):
        return None
    for line in read_text(path).splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        parts = s.split(None, 1)
        if parts and parts[0].lower() == key.lower():
            return parts[1].strip() if len(parts) > 1 else ""
    return None


def parse_plugin_ini(path):
    """返回 {name: bool_enabled}。"""
    out = {}
    if not os.path.isfile(path):
        return out
    for line in read_text(path).splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        parts = s.split()
        if len(parts) >= 2 and parts[0].lower() not in ("#",):
            try:
                out[parts[0]] = parts[1] == "1"
            except Exception:
                pass
    return out


def lua_toplevel_check(src):
    """校验 Lua 顶层结构：return exports 且 exports 表含 startplugin 定义。"""
    problems = []
    if not re.search(r"\breturn\s+exports\b", src):
        problems.append("缺少 `return exports`（boot.lua 的 require 会拿到 nil）")
    if not re.search(r"function\s+\w+\.startplugin\s*\(", src):
        problems.append("缺少 `<plugin>.startplugin(...)` 定义（boot.lua 会调用它）")
    if not re.search(r"local\s+exports\s*=\s*\{", src):
        problems.append("缺少 `local exports = { ... }` 表")
    return problems


def main() -> int:
    home = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_MAME_HOME
    ok = True
    print(f"MAME home: {home}")

    ini = os.path.join(home, "ini", "mame.ini")
    pluginspath = parse_ini_value(ini, "pluginspath")
    print(f"[1] mame.ini pluginspath = {pluginspath!r}")
    if pluginspath is None:
        print("    [!] 未读到 pluginspath，退回默认 plugins")
        pluginspath = "plugins"
    # mame.ini 的路径相对 homepath
    root = os.path.join(home, pluginspath.replace("/", os.sep))
    print(f"    解析为插件根目录: {root}")
    print(f"    目录存在: {os.path.isdir(root)}")
    ok &= os.path.isdir(root)

    pdir = os.path.join(root, PLUGIN_NAME)
    pj = os.path.join(pdir, "plugin.json")
    lua = os.path.join(pdir, "init.lua")
    print(f"[2] 插件目录: {pdir} 存在={os.path.isdir(pdir)}")
    print(f"    plugin.json 存在={os.path.isfile(pj)}  init.lua 存在={os.path.isfile(lua)}")
    ok &= os.path.isfile(pj) and os.path.isfile(lua)

    if os.path.isfile(pj):
        meta = json.loads(read_text(pj))
        p = meta.get("plugin", {})
        print(f"[3] plugin.json: name={p.get('name')!r} version={p.get('version')!r} "
              f"type={p.get('type')!r} start={p.get('start')!r}")
        # 关键：name 必须与目录名一致，否则 require(entry.name) 找不到
        if p.get("name") != PLUGIN_NAME:
            print(f"    [!] name 与目录名不一致：{p.get('name')!r} != {PLUGIN_NAME!r}")
            ok = False
        # 目录名必须符合 plugin.schema 的 name 正则
        if not re.fullmatch(r"[A-Za-z][0-9A-Za-z_]*", p.get("name") or ""):
            print("    [!] name 不符合 plugin.schema 正则")
            ok = False
        for req in ("name", "description", "version", "author", "type"):
            if req not in p:
                print(f"    [!] 缺少必填字段 {req}")
                ok = False
        if p.get("type") != "plugin":
            print(f"    [!] type 必须为 'plugin'，实际 {p.get('type')!r}")
            ok = False

    if os.path.isfile(lua):
        src = read_text(lua)
        problems = lua_toplevel_check(src)
        print(f"[4] init.lua 顶层结构检查: {'OK' if not problems else 'FAIL'}")
        for pr in problems:
            print(f"    [!] {pr}")
        ok &= not problems
        # API 白名单：按【方法名】匹配，不绑定变量名。
        # 例：插件里写 pr.p1:input_seq(...)，字面 "field:input_seq" 不会出现，
        # 但 :input_seq( 这个方法是真实的 —— 按方法签名匹配才准确。
        must_methods = [
            ":set_value(", ":clear_value(", ":input_seq(", ":seq_pressed(",
        ]
        must_tokens = [
            "manager.machine.ioport", "field.player",
            "emu.register_prestart", "emu.add_machine_frame_notifier",
            "emu.add_machine_stop_notifier",
        ]
        miss_m = [m for m in must_methods if m not in src]
        miss_t = [m for m in must_tokens if m not in src]
        total = len(must_methods) + len(must_tokens)
        print(f"[5] 关键 API 出现情况: {total - len(miss_m) - len(miss_t)}/{total}")
        for m in miss_m:
            print(f"    [!] 未出现方法: {m}")
            ok = False
        for m in miss_t:
            print(f"    [!] 未出现标识: {m}")
            ok = False

    pini = os.path.join(home, "ini", "plugin.ini")
    enables = parse_plugin_ini(pini)
    print(f"[6] plugin.ini 中 {PLUGIN_NAME} = {enables.get(PLUGIN_NAME)!r}")
    if not enables.get(PLUGIN_NAME):
        print("    [!] 未启用，MAME 不会 startplugin")
        ok = False

    print(f"=== 插件加载前置检查: {'PASS' if ok else 'FAIL'} ===")
    if ok:
        print("说明：这只是静态前置检查（不启动 MAME）。真正的运行态验证"
              "需要重启/重开 ROM 后由插件写 plugin_status.json 来证明。")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
