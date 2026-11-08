# MAME 2P 跟随守护 v1.1.0

你玩 1P，本程序控制 2P。**第一步实现（纯外部按键模拟）**：不重启 MAME、不修改任何 MAME 文件、随时可停、失焦自动释放所有按键。

## 解决什么

| 需求 | 本版做法 |
|---|---|
| 2P 跟上卷轴、不卡图 | MAME 前台时持续按住 2P 前进方向（双截龙按 `G` 右，雷电按 `R` 上） |
| 2P 被 NPC 抓住/控制，需连打按键挣脱解围 | 画面停滞（帧差）判定 → 自动高频交替连打 `A/S/Q/W`；另有保底周期连打，视觉不可用时也生效 |
| 不干扰你玩 1P / 不误按别的窗口 | **前台门控**：仅当 MAME 窗口确实处于前台时才发键；切到浏览器/微信即待命并释放所有键 |
| 设置不丢 | 任何改动即时写 `mame_2p_runtime/config.json`，重启自动加载 |

## 环境前提（已实测）

- 目标：`MAMEUI64 Plus! 0.289 (Jul 31 2026)`，pid `57472`，当前游戏 `双截龙 (世界 第1套) [ddragon]`。
- Python：`D:\Program Files\Python310\python.exe` 3.10.11（PATH 中优先），`PIL / PySide6 / psutil / numpy` 可用。
- 键位依据：`cfg\default.cfg` 未覆盖 2P 方向/按钮 → 走 MAME 0.289 官方默认（[官方文档](https://docs.mamedev.org/usingmame/defaultkeys.html)）：
  - **2P**：上 `R` / 下 `F` / 左 `D` / 右 `G` / 按钮1 `A` / 按钮2 `S` / 按钮3 `Q` / 按钮4 `W` / 按钮5 `E`
  - 1P 为方向键 + `Left Ctrl`/`Left Alt`/`Space`，与 2P 不冲突
  - Start2 `2`，投币 `5`
- ⚠️ **已知坑**：`default.cfg` 把 `P2_JOYSTICK_UP` 显式绑成了 `JOYCODE_2_YAXIS_UP_SWITCH OR JOYCODE_2_HAT1UP`（只有手柄）。横版用 `G` 不受影响；**纵版（雷电）按「上」的 `R` 可能失效**，故提供 `raiden_diag`（`R+G` 斜向）预设保底，实机请确认。
- MAME 加载 `DINPUT8.dll`，且 `mame.ini` 为 `global_inputs=0`（失焦不读输入）→ 必须用 `SendInput` 驱动级注入 + 前台门控；`PostMessage`/`SendMessage` 发 `WM_KEY*` 对 RawInput 无效。

## 两套方案

| | 方案一 · 外部按键 | 方案二 · 游戏内插件（推荐） |
|---|---|---|
| 原理 | Python `SendInput` 往 MAME 窗口发 2P 按键 | MAME 官方 Lua 插件在模拟器内部直接写 ioport |
| 依赖窗口前台 | **是**（切走就停） | **否**（不受焦点影响） |
| 占用物理键盘 | 是 | 否 |
| 跟随 1P | 读不到 1P，只能「持续前进 + 停滞挣脱」 | **逐帧镜像 1P 输入**：你按右它按右、你跳它跳、你被抓狂按它也狂按 |
| 生效条件 | 立即可用 | 需**完全退出 MAMEUI 前端再启动**（见下方「生效时机」） |

方案二通过 `python -m mame_2p.install_plugin` 安装（幂等、自动备份 `plugin.ini`、可 `--uninstall` 回滚）。

## 启动

```powershell
cd G:\Python_Code\mame_2p      # 项目已迁到此处（2026-11-06）
python -m mame_2p                       # 中文 GUI（两个标签页：方案一 / 方案二）
python -m mame_2p --no-gui              # 方案一：无界面守护
python -m mame_2p --bridge              # 方案二：无界面外部决策桥（写插件命令）
python -m mame_2p --selftest            # 只读自检，不发送任何按键
python -m mame_2p --status              # 查看方案一状态
python -m mame_2p --enable / --disable  # 方案一热启停

python -m mame_2p.install_plugin        # 安装/更新方案二插件
python -m mame_2p.install_plugin --status     # 检查安装状态
python -m mame_2p.install_plugin --uninstall  # 卸载并还原 plugin.ini
python -m mame_2p.verify_plugin_load    # 零侵入校验插件能否被 MAME 加载
python -m mame_2p.check_lua             # Lua 静态校验（本机无 luac 时的替代）
python -m mame_2p.fix_game_bridge --verify    # 验证视觉引擎（ping/selftest/snapshot）
```

也可直接双击 `run.bat`（默认开 GUI），或 `run.bat status / check / install / fixbridge`。

GUI 里点「启动守护」→ **切到 MAME 窗口**即可生效。切回来跟我说话时自动待命，不会往聊天框里打 `G/A/S`。

## 运行时文件（均在 `mame_2p_runtime/`）

| 文件 | 作用 |
|---|---|
| `config.json` | 全部设置，改动即落盘（规则 3） |
| `status.json` | 状态/心跳/帧差/按键统计，供核验 |
| `command.json` | 写字段热控制：`enabled`、`profile`、`stop`、时序字段；处理完自动清空动作字段（`enabled` 只影响本次运行，不写回 `config.json`，所以「停用」不会污染下次的默认启动行为） |
| `daemon.lock` | 单实例锁 |

## 状态机

- `IDLE` 未激活 → 不发键
- `STANDBY` MAME 不在前台 → **释放所有键**，待命
- `ACTIVE` MAME 前台 → 持续按住前进键 + 保底周期连打
- `ESCAPE` 连续 N 帧画面停滞 → 高频交替连打挣脱，再恢复前进

## 验证过的硬证据（2026-11-06）

- `python -m py_compile` 全模块通过；`--selftest` **PASS**：`INPUT sizeof=40`、`G` 扫描码 34 / flags `0x8`、PIL 抓帧 5184 字节成功。
- 无 GUI 守护实测：前台为 Chrome 时 `state=STANDBY`、`gate_open=false`、`held_keys=[]`、循环帧数 `47→134→282→860` 正常推进、**零按键发送**；写 `stop` 后进程干净退出、无残留、无按键残留。
- ⚠️ 尚未在 MAME 前台实测「2P 真的动了」——当前模型无图像输入能力，最终效果**需你肉眼确认**。

## 已知限制

1. 方案一**读不到 1P 状态**，只是「持续前进 + 停滞挣脱」；要真跟随请用方案二。
2. 方案一 `SendInput` 要求 MAME 前台，切走即停。
3. **插件生效时机（实测纠正）**：MAMEUI 前端是**单进程跑所有游戏**，`boot.lua` 只在进程启动时执行一次，`require('copilot2p')` 的结果缓存在 `package.loaded` 里。因此**只退出/切换游戏不会重新加载插件代码**，必须**完全退出 MAMEUI 前端再启动**。
   - 判断当前实际运行的版本：看 `\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui\copilot2p\plugin_status.json` 的 `version` 字段。
   - 实测教训：曾部署 4.8.1 后切换游戏（ddragon→xmen），状态文件仍报 `version=4.5.0`，即因 require 缓存未刷新。
4. 方案二**尚未在真实 ROM 上运行验证过**：本机无 `luac/lua`，Lua 只做了静态校验；「2P 是否真的动、被抓能否挣脱」需实机确认。
5. MAMEUI 前端是否透传 `-autoboot_script` / `-plugin` 未查证；本方案走 `plugin.ini` + 目录扫描，不依赖命令行透传。

## 方案二排查工具

- `copilot2p/plugin_status.json`（在 MAME `homepath` 下）：插件自写的运行态证明，含 `rom / pairs / frame / enabled / last_error`。**有这个文件 = 插件真的加载并跑起来了**。
- `mame_2p_runtime/copilot_bridge_status.json`：桥接侧状态，含 `gate_open / stuck / force_forward / burst / last_diff`。

## 合规

仅用于**离线单机、本人所有、正当用途**的模拟器陪玩；不改 ROM、不改 `default.cfg`、不动反作弊。在线游戏、反作弊绕过、多人作弊 ESP、DRM 绕过不在授权范围内。
