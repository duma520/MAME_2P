"""一键修复 dsh-game-bridge 视觉引擎（本机专用，可重复执行）。

本机特有背景（2026-11-06 实测确认）：
  CPU = AMD Phenom II X4 955（K10 架构，仅 SSE3/SSE4a，**不支持 SSE4.2**）。
  NumPy 2.x 把 x86-64 基线提高到 SSE4.2，因此引擎 venv 里 numpy 2.5.4 的
  _multiarray_umath.pyd 在导入时直接 DLL 初始化失败 —— 这是 CPU 硬限制，
  不是装坏了，降级 numpy 也无用（numpy 1.26 不支持 Python 3.13）。

修复思路（不改 MAME、不改插件源码、可逆）：
  1) 引擎核心 dsh_game_core 是**纯 Python**（13 文件，无 .pyd/.so），
     把它复制到系统 Python 3.10 的 user site-packages；
  2) 系统 Python 3.10 自带 numpy 1.26.4（支持老 CPU）+ cv2 + dxcam + mss；
  3) 给 capture.py 打兼容补丁：老版 dxcam 的 grab() 不接受
     new_frame_only 关键字，回退到无参调用；
  4) 让 DSH 插件通过环境变量 DSH_GAME_BRIDGE_PYTHON 指向该系统 Python。

用法：
  python -m mame_2p.fix_game_bridge            # 执行修复
  python -m mame_2p.fix_game_bridge --check    # 只检查不改动
  python -m mame_2p.fix_game_bridge --verify   # 完整验证（ping/selftest/snapshot）
  python -m mame_2p.fix_game_bridge --restore  # 移除本脚本装的 dsh_game_core
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import shutil
import subprocess
import sys
from typing import Dict, List, Optional

ENGINE_SRC = os.path.join(
    os.environ.get("LOCALAPPDATA", os.path.expanduser("~")),
    "dsh-game-bridge", "engine", "0.0.1", "Lib", "site-packages", "dsh_game_core",
)
SYSTEM_PYTHON_CANDIDATES = [
    r"D:\Program Files\Python310\python.exe",
    r"C:\Program Files\Python310\python.exe",
    "python",
]
PATCH_MARK = "本地兼容补丁（非上游代码）"


def find_system_python() -> Optional[str]:
    """找一个 numpy 能正常工作的本机 Python（优先 3.10）。"""
    for cand in SYSTEM_PYTHON_CANDIDATES:
        exe = shutil.which(cand) if not os.path.isabs(cand) else cand
        if not exe or not os.path.isfile(exe):
            continue
        ok = subprocess.run(
            [exe, "-c", "import numpy, cv2; print(numpy.__version__)"],
            capture_output=True, text=True, timeout=60,
        )
        if ok.returncode == 0:
            return exe
    return None


def user_site(py: str) -> Optional[str]:
    r = subprocess.run([py, "-c", "import site; print(site.getusersitepackages())"],
                       capture_output=True, text=True, timeout=30)
    return r.stdout.strip() if r.returncode == 0 else None


def patch_capture(capture_py: str) -> bool:
    """给 capture.py 打 dxcam 兼容补丁（幂等）。"""
    src = open(capture_py, "r", encoding="utf-8").read()
    if PATCH_MARK in src:
        return False
    old = '        frame = self._cam.grab(new_frame_only=False)\n'
    if old not in src:
        return False
    new = (
        '        # ' + PATCH_MARK + '：老版本 dxcam 的 grab() 不接受\n'
        '        # new_frame_only 关键字，直接传会抛 TypeError，这里回退到无参调用。\n'
        '        frame = None\n'
        '        try:\n'
        '            frame = self._cam.grab(new_frame_only=False)\n'
        '        except TypeError:\n'
        '            frame = None\n'
        '        if frame is None:\n'
        '            frame = self._cam.grab()\n'
        '        if frame is None:\n'
        '            frame = self._cam.grab()\n'
    )
    # 原文件在 .grab(new_frame_only=False) 之后还有 `if frame is None: frame = self._cam.grab()`
    # 为免重复，先把那两行一起替换掉
    old_block = (
        '        frame = self._cam.grab(new_frame_only=False)\n'
        '        if frame is None:\n'
        '            frame = self._cam.grab()\n'
    )
    if old_block not in src:
        return False
    src = src.replace(old_block, new, 1)
    open(capture_py, "w", encoding="utf-8", newline="\n").write(src)
    return True


def do_check() -> int:
    print("=== dsh-game-bridge 修复前检查 ===")
    ok = True
    print(f"[1] 引擎源码 dsh_game_core: {ENGINE_SRC} 存在={os.path.isdir(ENGINE_SRC)}")
    ok &= os.path.isdir(ENGINE_SRC)
    py = find_system_python()
    print(f"[2] 可用系统 Python（numpy 正常）: {py}")
    ok &= py is not None
    if py:
        us = user_site(py)
        print(f"[3] user site: {us}")
        dst = os.path.join(us, "dsh_game_core") if us else None
        print(f"[4] 已安装到 user site: {os.path.isdir(dst) if dst else False}")
        if dst and os.path.isdir(dst):
            cap = os.path.join(dst, "capture.py")
            src = open(cap, encoding="utf-8").read() if os.path.isfile(cap) else ""
            print(f"[5] capture.py 兼容补丁已打: {PATCH_MARK in src}")
    print("\n提示：让 DSH 用上它需设置环境变量")
    print(f'  DSH_GAME_BRIDGE_PYTHON = {py or "<系统python路径>"}')
    print("（在 desktop profile 的 cordis.patch.yml 给 dsh-game-bridge 加 env，或系统环境变量）")
    return 0 if ok else 1


def do_fix() -> int:
    py = find_system_python()
    if not py:
        print("[!] 找不到 numpy 可用的系统 Python（试过 3.10 路径 / PATH）")
        return 1
    us = user_site(py)
    if not us:
        print("[!] 取不到 user site 路径")
        return 1
    os.makedirs(us, exist_ok=True)
    dst = os.path.join(us, "dsh_game_core")
    if os.path.isdir(dst):
        shutil.rmtree(dst)
    shutil.copytree(ENGINE_SRC, dst)
    print(f"[1] 已复制 dsh_game_core -> {dst}")
    cap = os.path.join(dst, "capture.py")
    patched = patch_capture(cap)
    print(f"[2] capture.py dxcam 兼容补丁: {'已打' if patched else '无需/已存在'}")
    ok = subprocess.run([py, "-c", "from dsh_game_core import engine; print('engine import OK')"],
                        capture_output=True, text=True, timeout=60)
    print(f"[3] 导入验证: {ok.stdout.strip() or ok.stderr.strip()[:200]}")
    print("\n完成。接下来需要把 DSH 的引擎指向这个 Python：")
    print(f'  DSH_GAME_BRIDGE_PYTHON = {py}')
    print("设置后重启 DSH 生效（或：本脚本 --verify 可先在 DSH 外验证整条链路）。")
    return 0 if ok.returncode == 0 else 1


def do_restore() -> int:
    py = find_system_python()
    if not py:
        print("[!] 找不到系统 Python")
        return 1
    us = user_site(py)
    dst = os.path.join(us, "dsh_game_core") if us else None
    if dst and os.path.isdir(dst):
        shutil.rmtree(dst)
        print(f"已移除 {dst}")
    else:
        print("未安装，无需移除")
    return 0


def do_verify() -> int:
    """在 DSH 之外完整验证：ping / selftest / attach / snapshot。"""
    py = find_system_python()
    if not py:
        print("[!] 找不到系统 Python")
        return 1
    script = r'''
import json, subprocess, sys, os, time, base64
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
env = {**os.environ, "PYTHONIOENCODING": "utf-8"}
p = subprocess.Popen([sys.executable, "-m", "dsh_game_core", "serve"],
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE, text=True, encoding="utf-8", env=env)
def call(i, m, a=None):
    p.stdin.write(json.dumps({"id": i, "method": m, "params": a or {}}) + "\n"); p.stdin.flush()
    return json.loads(p.stdout.readline().strip())
ok = True
r = call(1, "ping"); print("[1] ping:", r.get("ok")); ok &= bool(r.get("ok"))
s = call(2, "selftest").get("result", {})
deps = s.get("deps", {})
print("[2] selftest: python=", s.get("python"), "numpy=", deps.get("numpy"),
      "cv2=", deps.get("cv2"), "dxcam=", deps.get("dxcam"),
      "ocr_ready=", s.get("ocr_ready"))
ok &= str(deps.get("numpy","")).startswith("1.")
for wname in ("ddragon", "MAME"):
    a = call(3, "attach", {"window": wname})
    if a.get("ok"):
        print("[3] attach ok:", (a["result"]["attached"]["window"])[:60],
              "hwnd=", a["result"]["attached"]["hwnd"])
        break
else:
    print("[3] attach: 未找到 MAME 窗口（游戏可能没开），仍可抓全屏")
time.sleep(0.3)
snap = call(4, "snapshot", {"ocr": False})
r2 = snap.get("result") or {}
print("[4] snapshot ok=", snap.get("ok"), "w/h=", r2.get("width"), r2.get("height"))
ok &= bool(snap.get("ok"))
if r2.get("png_b64"):
    out = os.path.join(os.getcwd(), "_mame_probe", "engine_snapshot.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    b64 = r2["png_b64"]
    if b64.startswith("data:image"): b64 = b64.split(",",1)[1]
    open(out, "wb").write(base64.b64decode(b64))
    print("[5] 截图已存:", out)
p.stdin.close()
try: p.wait(timeout=8)
except Exception: p.kill()
print("=== VERIFY", "PASS" if ok else "FAIL", "===")
sys.exit(0 if ok else 1)
'''
    tmp = os.path.join(os.environ.get("TEMP", "."), "_gb_verify.py")
    open(tmp, "w", encoding="utf-8").write(script)
    try:
        return subprocess.call([py, tmp])
    finally:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="mame_2p.fix_game_bridge")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--restore", action="store_true")
    a = ap.parse_args(argv)
    if a.check:
        return do_check()
    if a.verify:
        return do_verify()
    if a.restore:
        return do_restore()
    return do_fix()


if __name__ == "__main__":
    raise SystemExit(main())
