"""入口：python -m mame_2p [install|uninstall|verify|status|selftest]

本包只服务于 MAME 侧的 copilot2p Lua 插件：安装、卸载、校验、看状态。
方案一（外部 SendInput 按键模拟）已于 v1.4.0 移除 —— 实测 MAME 走
RawInput，SendInput 合成的按键不进入其输入流，无法驱动模拟器。
"""
from __future__ import annotations

import argparse
import os
import sys

from . import APP_VERSION


def cmd_install(argv) -> int:
    from .install_plugin import install, DEFAULT_MAME_HOME
    return install(getattr(argv, "mame_home", None) or DEFAULT_MAME_HOME)


def cmd_uninstall(argv) -> int:
    from .install_plugin import uninstall, DEFAULT_MAME_HOME
    return uninstall(getattr(argv, "mame_home", None) or DEFAULT_MAME_HOME)


def cmd_verify(argv) -> int:
    """插件加载前置检查 + Lua 静态校验。"""
    from .verify_plugin_load import main as verify_main
    from .check_lua import main as lua_main
    rc1 = verify_main()
    rc2 = lua_main()
    return 0 if (rc1 == 0 and rc2 == 0) else 1


def cmd_status(argv) -> int:
    """读 MAME 侧插件自写的 plugin_status.json。"""
    from .show_status import main as status_main
    return status_main([] if not getattr(argv, "raw", False) else ["--raw"])


def cmd_selftest(argv) -> int:
    """只读自检：确认各模块可导入、插件文件齐备、部署路径可访问。"""
    print("=== mame_2p 自检 v%s ===" % APP_VERSION)
    ok = True

    # 1) 模块可导入
    for name in ("install_plugin", "verify_plugin_load", "check_lua",
                 "show_status", "fix_game_bridge"):
        try:
            __import__("mame_2p." + name)
            print(f"[1] 导入 {name} OK")
        except Exception as e:
            ok = False
            print(f"[1] 导入 {name} FAIL: {e}")

    # 2) 插件源文件齐备
    src = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "plugin", "copilot2p")
    for fn in ("init.lua", "plugin.json"):
        p = os.path.join(src, fn)
        exists = os.path.isfile(p)
        ok &= exists
        print(f"[2] 源文件 {fn}: {'存在 ' + str(os.path.getsize(p)) + ' B' if exists else '缺失'}")

    # 3) 部署目录可访问
    try:
        from .install_plugin import DEFAULT_MAME_HOME
        dst = os.path.join(DEFAULT_MAME_HOME, "plugins", "copilot2p")
        reach = os.path.isdir(dst)
        print(f"[3] 部署目录可达: {reach}  {dst}")
        ok &= reach
    except Exception as e:
        print(f"[3] 部署目录检查失败: {e}")

    # 4) 已无方案一残留模块
    pkg = os.path.dirname(os.path.abspath(__file__))
    # 方案一专属模块；config.py 属共用基础设施（路径常量），不在其列
    gone = ("daemon.py", "wininput.py", "copilot_bridge.py",
            "verify_move.py", "vision.py", "gui.py")
    left = [f for f in gone if os.path.isfile(os.path.join(pkg, f))]
    print(f"[4] 方案一残留: {left if left else '无'}")
    ok &= not left

    print(f"=== 自检结果: {'PASS' if ok else 'FAIL'} ===")
    return 0 if ok else 1


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="mame_2p",
        description="MAME 多玩家输入镜像插件的配套工具（安装/校验/状态）")
    ap.add_argument("command", nargs="?", default="help",
                    choices=["install", "uninstall", "verify", "status",
                             "selftest", "help"],
                    help="要执行的动作")
    ap.add_argument("--mame-home", default=None,
                    help="MAME 安装目录（默认用内置 UNC 路径）")
    ap.add_argument("--raw", action="store_true", help="status 时打印原始 JSON")
    a = ap.parse_args(argv)

    if a.command == "install":
        return cmd_install(a)
    if a.command == "uninstall":
        return cmd_uninstall(a)
    if a.command == "verify":
        return cmd_verify(a)
    if a.command == "status":
        return cmd_status(a)
    if a.command == "selftest":
        return cmd_selftest(a)

    print(__doc__)
    print("可用命令：")
    print("  install    安装/更新插件到 MAME（自动备份 plugin.ini）")
    print("  uninstall  卸载插件并还原 plugin.ini")
    print("  verify     插件加载前置检查 + Lua 静态校验")
    print("  status     读插件自写的 plugin_status.json（含 menu_verify）")
    print("  selftest   只读自检（模块/源文件/部署目录/残留）")
    print()
    print("注意：插件代码由 MAMEUI 进程启动时 require 一次并缓存，")
    print("      改完必须【完全退出 MAMEUI 前端再启动】才会加载新版本。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
