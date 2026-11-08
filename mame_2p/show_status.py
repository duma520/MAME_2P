"""读取 MAME 侧 copilot2p 的 plugin_status.json（UTF-8 安全，避开 pwsh 的 GBK 坑）。

用法：
  python -m mame_2p.show_status
  python -m mame_2p.show_status --raw      # 打印原始 JSON
"""
from __future__ import annotations

import json
import os
import sys

MAME_HOME = r"\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui"
STATUS = os.path.join(MAME_HOME, "copilot2p", "plugin_status.json")
COMMAND = os.path.join(MAME_HOME, "copilot2p", "command.json")


def main(argv=None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    raw = "--raw" in argv

    if not os.path.isfile(STATUS):
        print(f"[!] 状态文件不存在：{STATUS}")
        print("    说明插件没有加载 —— 检查：")
        print("    1) plugins/copilot2p/{plugin.json,init.lua} 是否存在")
        print("    2) ini/plugin.ini 是否有 `copilot2p 1`")
        print("    3) 是否已在加完插件后【重新进入】游戏（插件只在启动 ROM 时加载）")
        return 1

    with open(STATUS, "r", encoding="utf-8") as f:
        text = f.read()

    if raw:
        print(text)
        return 0

    d = json.loads(text)
    print("=== copilot2p 运行状态 ===")
    print(f"  插件版本 : {d.get('version')}")
    print(f"  ROM      : {d.get('rom')}")
    print(f"  帧号     : {d.get('frame')}")
    print(f"  已配对   : {d.get('pairs')}  <-- 关键：>0 才真正在工作")
    print(f"  启用     : {d.get('enabled')}")
    print(f"  连打     : {d.get('burst')}")
    print(f"  错误     : {d.get('last_error') or '(无)'}")

    g = d.get("diag") or {}
    if g:
        print("\n--- 诊断计数 ---")
        for k in ("ports", "records", "with_player", "with_mask", "with_type",
                  "by_type", "chosen"):
            if k in g:
                print(f"  {k:12s} = {g[k]}")
        samples = g.get("samples") or []
        if samples:
            print(f"\n--- 字段样本（前 {len(samples)} 条，格式: 名称|端口|t=type|p=player|m=mask）---")
            for s in samples:
                print(f"  {s}")

    # 顺带看命令文件（决定运行策略）
    if os.path.isfile(COMMAND):
        try:
            with open(COMMAND, "r", encoding="utf-8") as f:
                cmd = json.load(f)
            print(f"\n--- command.json ---\n  {json.dumps(cmd, ensure_ascii=False)}")
        except Exception as e:
            print(f"\n--- command.json 解析失败: {e}")

    # 结论
    pairs = d.get("pairs") or 0
    print()
    if pairs <= 0:
        print("=== 结论：pairs=0，插件未配对任何字段 → 不会控制 2P ===")
        return 2
    print(f"=== 结论：已配对 {pairs} 组，插件应在镜像 1P 输入到 2P ===")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
