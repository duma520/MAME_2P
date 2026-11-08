"""把 copilot2p 插件安装到 MAME 0.289（幂等、可回滚、不重启游戏）。

动作：
  1) 复制 mame_2p/plugin/copilot2p/ → <MAME home>/plugins/copilot2p/
  2) 更新 <MAME home>/ini/plugin.ini：确保存在 `copilot2p  1`，先备份为
     plugin.ini.bak-copilot2p（保留原文件，方便一键回滚）
  3) 校验 plugin.json 结构、init.lua 存在、Lua 语法（若本机有 lua/luac）
  4) 打印生效时机说明：插件仅由 boot.lua 在【每次启动 ROM】时加载，
     故下次开始/切换游戏即生效，不打断当前这局。

回滚：python -m mame_2p.install_plugin --uninstall
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import time
from typing import Tuple

DEFAULT_MAME_HOME = r"\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui"
PLUGIN_NAME = "copilot2p"


def plugin_src_dir() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "plugin", PLUGIN_NAME)


def plugin_dst_dir(mame_home: str) -> str:
    return os.path.join(mame_home, "plugins", PLUGIN_NAME)


def plugin_ini_path(mame_home: str) -> str:
    return os.path.join(mame_home, "ini", "plugin.ini")


def read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def check_plugin_files(src: str) -> Tuple[bool, str]:
    pj = os.path.join(src, "plugin.json")
    lua = os.path.join(src, "init.lua")
    if not os.path.isfile(pj):
        return False, f"缺少 {pj}"
    if not os.path.isfile(lua):
        return False, f"缺少 {lua}"
    try:
        meta = json.loads(read_text(pj))
        p = meta["plugin"]
        assert p["name"] == PLUGIN_NAME
        assert p["type"] == "plugin"
        assert isinstance(p["start"], str)
    except Exception as e:
        return False, f"plugin.json 校验失败: {e}"
    # Lua 语法检查（本机未必有 lua；没有就跳过，不阻断）
    try:
        import subprocess
        for exe in ("luac", "lua"):
            try:
                r = subprocess.run([exe, "-p", lua], capture_output=True, text=True, timeout=10)
                if r.returncode != 0:
                    return False, f"Lua 语法检查失败({exe}): {r.stderr.strip()}"
                return True, f"Lua 语法 OK（{exe} -p）"
            except FileNotFoundError:
                continue
    except Exception:
        pass
    return True, "plugin.json 校验通过；本机无 luac/lua，跳过 Lua 语法检查"


def enable_in_ini(mame_home: str) -> Tuple[bool, str]:
    path = plugin_ini_path(mame_home)
    if not os.path.isfile(path):
        return False, f"找不到 {path}"
    original = read_text(path)
    lines = original.splitlines()
    found = False
    changed = False
    out = []
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            out.append(line)
            continue
        parts = stripped.split()
        if parts and parts[0].lower() == PLUGIN_NAME:
            found = True
            if len(parts) < 2 or parts[1] != "1":
                out.append(f"{PLUGIN_NAME}                 1")
                changed = True
            else:
                out.append(line)
        else:
            out.append(line)
    if not found:
        out.append(f"{PLUGIN_NAME}                 1")
        changed = True
    if changed:
        bak = path + ".bak-copilot2p"
        if not os.path.isfile(bak):
            shutil.copy2(path, bak)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(out) + "\n")
        return True, f"已更新 {path}（原文件备份为 {bak}）"
    return True, f"{path} 已包含 `copilot2p 1`，无需改动"


def disable_in_ini(mame_home: str) -> Tuple[bool, str]:
    path = plugin_ini_path(mame_home)
    if not os.path.isfile(path):
        return True, "plugin.ini 不存在，跳过"
    original = read_text(path)
    out = []
    changed = False
    for line in original.splitlines():
        s = line.strip()
        if s and not s.startswith("#") and s.split() and s.split()[0].lower() == PLUGIN_NAME:
            out.append(f"{PLUGIN_NAME}                 0")
            changed = True
        else:
            out.append(line)
    if changed:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(out) + "\n")
    return True, f"已把 {PLUGIN_NAME} 置 0（{path}）"


def restore_ini(mame_home: str) -> Tuple[bool, str]:
    path = plugin_ini_path(mame_home)
    bak = path + ".bak-copilot2p"
    if os.path.isfile(bak):
        shutil.copy2(bak, path)
        return True, f"已从备份还原 {path}"
    return disable_in_ini(mame_home)


def install(mame_home: str) -> int:
    src = plugin_src_dir()
    ok, msg = check_plugin_files(src)
    print(f"[1] 插件文件校验: {msg}")
    if not ok:
        return 1
    dst = plugin_dst_dir(mame_home)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    # ★ v5.0.1 修复：原实现是 rmtree(dst) + copytree(src, dst)。
    #   UNC（SMB）路径上 rmtree 之后目录句柄/缓存有延迟，紧接着 copytree
    #   会撞 FileExistsError，结果是【旧目录已删掉、新目录没建成】——插件
    #   在网络盘上凭空消失（本机 2026-11-07 实测踩坑）。
    #   改为：不删整个目录，只逐文件覆盖写入（幂等、无删除窗口）。
    os.makedirs(dst, exist_ok=True)
    for name in sorted(os.listdir(src)):
        s = os.path.join(src, name)
        if not os.path.isfile(s):
            continue
        d = os.path.join(dst, name)
        last_err = None
        for attempt in range(3):
            try:
                shutil.copyfile(s, d)
                last_err = None
                break
            except OSError as e:
                last_err = e
                time.sleep(0.8)
        if last_err is not None:
            print(f"[!] 复制 {name} 失败: {last_err}")
            return 1
    print(f"[2] 已安装插件到: {dst}")
    for f in sorted(os.listdir(dst)):
        print(f"      - {f} ({os.path.getsize(os.path.join(dst, f))} B)")
    ok, msg = enable_in_ini(mame_home)
    print(f"[3] plugin.ini: {msg}")
    if not ok:
        return 1
    print("[4] 生效时机（重要，实测纠正）:")
    print("     MAMEUI 前端是单进程跑所有游戏，boot.lua 只在【前端进程启动】时执行一次，")
    print("     require('copilot2p') 之后模块被缓存在 package.loaded 里。")
    print("     => 只退出/切换游戏不会重新加载插件代码，必须【完全退出 MAMEUI 前端再启动】。")
    print("     判断当前跑的是哪个版本：看 copilot2p/plugin_status.json 的 version 字段。")
    return 0


def uninstall(mame_home: str) -> int:
    dst = plugin_dst_dir(mame_home)
    if os.path.isdir(dst):
        shutil.rmtree(dst)
        print(f"[1] 已删除插件目录: {dst}")
    else:
        print(f"[1] 插件目录不存在，跳过: {dst}")
    ok, msg = restore_ini(mame_home)
    print(f"[2] plugin.ini: {msg}")
    print("[3] 注意：已加载的插件要等【完全退出 MAMEUI 前端再启动】才会真正卸载（require 缓存）。")
    return 0


def status(mame_home: str) -> int:
    dst = plugin_dst_dir(mame_home)
    ini = plugin_ini_path(mame_home)
    print(f"插件目录: {dst} 存在={os.path.isdir(dst)}")
    if os.path.isdir(dst):
        for f in sorted(os.listdir(dst)):
            print(f"   - {f}")
    if os.path.isfile(ini):
        for line in read_text(ini).splitlines():
            if line.strip().lower().startswith(PLUGIN_NAME):
                print(f"plugin.ini: {line.strip()}")
    ok, msg = check_plugin_files(plugin_src_dir())
    print(f"源码校验: {msg}")
    return 0 if ok else 1


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="mame_2p.install_plugin")
    ap.add_argument("--mame-home", default=DEFAULT_MAME_HOME)
    ap.add_argument("--uninstall", action="store_true")
    ap.add_argument("--status", action="store_true")
    a = ap.parse_args(argv)
    if a.status:
        return status(a.mame_home)
    if a.uninstall:
        return uninstall(a.mame_home)
    return install(a.mame_home)


if __name__ == "__main__":
    raise SystemExit(main())
