# MAME_2P v5.0.1 截图

<img width="1337" height="1033" alt="image" src="https://github.com/user-attachments/assets/58a69d14-0cfd-4ca6-af09-3544a32c8f55" />

<img width="1337" height="1033" alt="image" src="https://github.com/user-attachments/assets/9aa218d2-cf8e-4c18-84d6-1e7191617115" />

<img width="1337" height="1033" alt="image" src="https://github.com/user-attachments/assets/c711415f-4182-4b53-8ccd-de26a4a85ae2" />

# MAME 多玩家输入镜像插件 copilot2p 完全指南

### —— 从零基础到高级应用的详尽说明书

---

**作者**：杜玛
**版权**：永久 © 杜玛　保留所有权利
**开源许可证**：MIT
**项目地址**：https://github.com/duma520/mame_2p
**GitHub**：https://github.com/duma520
**网站**：https://github.com/duma520
**问题报告**：通过 GitHub Issues 提交
**文档版本**：对应软件 `mame_2p v1.4.0` + `copilot2p 插件 v5.0.1`
**开发/整理时间**：2026-11-08

> **版权声明**：本文档内容未经书面许可不得转载或用于商业用途。
> **技术支持说明**：本项目不提供私人邮箱支持，所有技术支持均通过 GitHub Issues 等公开渠道进行，以便其他用户也能检索受益。

---

## 目录

- [阅读指南：不同的人该怎么读这份文档](#阅读指南)
- [第一章　这是什么？——零基础的第一课](#第一章)
- [第二章　它解决什么问题、不解决什么问题](#第二章)
- [第三章　核心概念词典（通俗 ↔ 专业对照）](#第三章)
- [第四章　安装前必读：环境与前提](#第四章)
- [第五章　安装部署：三种路径](#第五章)
- [第六章　第一次使用：手把手走一遍](#第六章)
- [第七章　菜单逐项详解（v5.0.1 全项）](#第七章)
- [第八章　配置文件完全解析](#第八章)
- [第九章　高级用法与场景实战](#第九章)
- [第十章　原理深潜：为什么这样做才有效](#第十章)
- [第十一章　源码导读：给想改代码的人](#第十一章)
- [第十二章　故障排查手册（症状 → 原因 → 处方）](#第十二章)
- [第十三章　性能、限制与已知问题](#第十三章)
- [第十四章　版本历史与每次更新的一句话简报](#第十四章)
- [第十五章　开发、测试与贡献](#第十五章)
- [第十六章　常见问题 FAQ（50 问）](#第十六章)
- [附录 A　术语表](#附录A)
- [附录 B　速查卡（打印贴墙版）](#附录B)
- [附录 C　文件名与路径速查](#附录C)
- [法律、许可与联系](#法律许可)

---

<a name="阅读指南"></a>
## 阅读指南：不同的人该怎么读这份文档

这份文档刻意写得"又长又全"，因为它要同时服务完全不同的读者。你**不需要从头读到尾**。请按你的身份挑着读：

| 你的身份 | 建议阅读路径 | 预计耗时 |
|---|---|---|
| **完全不懂技术的玩家**，只想让朋友一起玩 | 第一章 → 第二章 → 第六章 → 第七章 → 第十二章 | 30 分钟 |
| **有点电脑基础、会装软件**的玩家 | 第一章 → 第四章 → 第五章 → 第六章 → 第八章 → 第十二章 | 1 小时 |
| **想深度定制**（改默认值、按游戏分别配置）| 第七章 → 第八章 → 第九章 | 1.5 小时 |
| **程序员 / 想改 Lua 源码** | 第三章 → 第八章 → 第十章 → 第十一章 → 第十五章 | 3 小时 |
| **遇到问题来查手册的** | 直接跳 [第十二章 故障排查](#第十二章) 或 [第十六章 FAQ](#第十六章) | 5 分钟 |
| **想看版本演进的** | 直接跳 [第十四章 版本历史](#第十四章) | 10 分钟 |

> **一个重要的阅读提示**：本文档里凡是出现 `⚠️` 的地方，都是"**实测踩过的坑**"或"**容易误解的地方**"，是最值钱的部分。时间紧的话，先读这些。

---

<a name="第一章"></a>
## 第一章　这是什么？——零基础的第一课

### 1.1 一句话说明

**这是一个让 MAME 街机模拟器里的"1 号玩家"能同时操控"2 号、3 号、4 号玩家"的插件。**

### 1.2 用生活场景解释

想象一下这个画面：

> 周末，你打开电脑玩《X战警》（X-Men，1992 年的 6 人街机格斗游戏）。你只有一个人，一个键盘，一副手柄。但是游戏里 4 个角色都站在那不动——因为没有人"喂"给 2P、3P、4P 按键信号。
>
> 你想：**要是我按 1P 的"向右"，2P、3P、4P 也跟着往右走，那该多热闹。**

这个插件干的就是这件事。它像一个"分身术"——你按下的每一个键，会被复制一份（或几份）送到 2P、3P、4P 身上。

再打个比方：

```
你（1P） ──按下"右"──► 键盘
                        │
                        ▼
              ┌─────────────────┐
              │  copilot2p 插件  │  ← 就是本项目的核心
              └─────────────────┘
                  │    │    │
                  ▼    ▼    ▼
                2P   3P   4P   ← 它们同时收到"右"
```

### 1.3 为什么需要它？

街机游戏原本设计是"一个玩家一套摇杆"。但当你：

- **单人玩多人游戏**，想让其他角色不傻站着；
- **带孩子玩**，孩子只按 1P，你想让 2P 也动起来当"副驾驶"；
- **演示/直播**，需要多个角色同步动作；
- **做自动化测试**，想验证多玩家输入逻辑；

—— 你就会需要这样一个"输入复制器"。

### 1.4 它是怎么"安装"的？

它不是一个独立软件，而是 **MAME 模拟器的一个"插件"（Plugin）**。你可以把它理解成手机上的"扩展应用"：MAME 是系统，插件是装进系统里的一个功能模块。

安装后的文件长这样（在 MAME 的插件目录下）：

```
MAMEUI64 Plus!\mameui\plugins\copilot2p\
    ├── init.lua      ← 核心代码（1074 行 Lua）
    └── plugin.json   ← 身份证（名字、版本、描述）
```

MAME 启动时读到这个文件夹，就把插件"点亮"。

### 1.5 它能用在哪些游戏上？

**理论上所有 MAME 游戏**，但有前提：

- 必须是**多人游戏**（2 人、3 人或 4 人）——单人游戏没有 2P 字段可镜像；
- 游戏的 2P/3P/4P 输入字段必须被 MAME 识别（绝大多数街机游戏都满足）；
- 必须是**离线单机、本人所有**的正当用途（详见[法律章节](#法律许可)）。

实测验证过的游戏：

| 游戏 | 玩家数 | 说明 |
|---|---|---|
| 双截龙（ddragon） | 2 人 | 只有 P1/P2，镜像到 P3/P4 不会生效（正常行为） |
| X战警（xmen） | 4 人 | 完整支持 P1→P2/P3/P4 |

### 1.6 它做不到什么？（先泼冷水，避免误会）

**必须一开始就讲清楚**，这是用户最容易误解的地方：

| 你以为它能做 | 实际上 |
|---|---|
| 让我物理按住的 1P 键自动连发 | ❌ **做不到**。插件层无法覆盖"玩家正在物理按住的键"的每帧刷新（详见第十章）。**请改用 MAME 官方「连发」插件**（Tab 菜单第一项）。 |
| 把 1P 的摇杆动作"翻译"成 2P 的招式 | ❌ 做不到。它只做"按键状态镜像"，不理解游戏语义。 |
| 让 2P/3P/4P 有独立 AI | ❌ 做不到。那是 AI，本项目只做输入复制。 |
| 支持手柄/摇杆的镜像 | ⚠️ 部分支持。它镜像的是 MAME 内部的"输入字段"，只要手柄绑定到了字段上就能镜像；但物理设备的细节（力反馈、摇杆精度）不处理。 |
| 通过外部程序模拟按键（SendInput）来操控 MAME | ❌ 已证明**对 MAME 无效**，相关代码已在 v1.4.0 删除。原因见第十章的"RawInput"一节。 |

> ⚠️ **重要澄清**：v5.0.0 起，**连发功能已彻底移除**。本插件现在是**纯镜像**插件。连发需求请使用 MAME 官方自带的 `autofire` 插件（Tab 菜单 → 插件选项 → 连发）。这个决定是经过两轮实测验证后做出的，不是功能退步，而是"把做不到的事做诚实的说明"。

---

<a name="第二章"></a>
## 第二章　它解决什么问题、不解决什么问题

### 2.1 问题背景：街机游戏的"输入孤岛"

街机游戏的设计哲学是"每个玩家一套独立的输入设备"。在真实街机厅里，1P 摇杆、2P 摇杆是**物理分离**的两套硬件，各自接线到主板的不同端口。

MAME 忠实还原了这一点：它把每个玩家的输入建模为独立的"输入字段"（input field），互不干扰。

```
MAME 内部（简化示意）
┌──────────────────────────────────────────┐
│  IOPort（输入端口组）                       │
│  ┌────────────────┐  ┌────────────────┐  │
│  │ P1 端口         │  │ P2 端口         │  │
│  │  UP   field    │  │  UP   field    │  │
│  │  DOWN field    │  │  DOWN field    │  │
│  │  LEFT field    │  │  LEFT field    │  │
│  │  RIGHT field   │  │  RIGHT field   │  │
│  │  BTN1..BTNn    │  │  BTN1..BTNn    │  │
│  └────────────────┘  └────────────────┘  │
└──────────────────────────────────────────┘
         ↑ 物理键盘                     ↑ 没有设备连接
       你在这里                      所以角色不动
```

**问题**：当只有一个人在玩时，P2 的字段全是"未按下"状态，角色就傻站着。

**目标**：让 P1 字段的状态"流"到 P2 字段去。

### 2.2 三种可能的解决方案（以及为什么前两种不行）

在讲本插件之前，值得先讲清楚"为什么不能用更简单的办法"。这段是理解整个项目史的钥匙。

#### 方案 A：外部程序模拟键盘按键（SendInput）

**思路**：写个 Python 程序，检测到 1P 按了"右"，就调用 Windows API `SendInput` 发送一个"2P 的右"按键（比如 `G` 键）。

**为什么失败**：MAME 在 Windows 上默认使用 **RawInput**（原始输入）机制读取键盘。RawInput 从**设备驱动层**直接读取硬件事件，而 `SendInput` 注入的是**Windows 消息队列**里的合成事件。两者不在同一个通道里：

```
真实键盘硬件 ──► 设备驱动 ──► RawInput ──► MAME  ✅ 能收到
SendInput 注入 ──► 消息队列 ──► (绕过 RawInput) ──► MAME  ❌ 收不到
```

**结论**：方案 A 对 MAME **从根本上不可行**。项目曾经实现了完整的方案 A（`daemon.py`、`wininput.py` 等 5 个模块），v1.4.0 时全部删除，仅在 `version/20261107-v16-pre-cleanup/` 留有可回滚备份。

> 唯一的例外是：如果某个前端或模拟器**不使用 RawInput**（比如某些使用普通 Windows 消息的老程序），方案 A 可能有效。但 MAME 不行。

#### 方案 B：修改游戏 ROM 或内存

**思路**：直接改 ROM 代码，让 P2 读取 P1 的内存地址。

**为什么不做**：侵入性极强、违反 MAME 的设计哲学、可能触发反作弊、无法通用。**不推荐，本项目不采用**。

#### 方案 C：MAME 官方 Lua 插件（本项目采用）

**思路**：MAME 自带 Lua 脚本接口，官方插件如 `inputmacro`（宏按键）、`autofire`（连发）就是用这个接口写的。它们能通过 `field:set_value()` 直接**写**输入字段的值。

**为什么成功**：

- 它在 MAME **进程内部**运行，不依赖 RawInput 通道；
- 它读写的是 MAME 的**抽象字段**，与物理设备无关；
- 它是**官方支持的扩展机制**，稳定、安全、通用。

**这就是本项目的技术路线**：写一个 MAME Lua 插件，在每一帧（约 1/60 秒）读取 P1 字段状态，写到 P2/P3/P4 字段。

### 2.3 能力边界表（详细版）

| 能力 | 支持情况 | 说明 |
|---|---|---|
| P1 → P2 镜像 | ✅ 完整支持 | 基础功能 |
| P1 → P3 镜像 | ✅ 完整支持 | 需游戏有 P3 字段 |
| P1 → P4 镜像 | ✅ 完整支持 | 需游戏有 P4 字段 |
| P1 → P2+P3+P4 同时 | ✅ 完整支持 | v4.1.0 起 |
| P2 → P3 镜像（任意源） | ✅ 完整支持 | v4.8.0 起，多源 |
| 多源 OR 合成 | ✅ 完整支持 | 同一目标被多个源控制时取"任一按下" |
| 按游戏独立配置 | ✅ 完整支持 | v4.7.0 起，每个 ROM 一个配置文件 |
| 默认值模板 | ✅ 完整支持 | v4.3.0 起 |
| 逐键开关 | ✅ 完整支持 | 每个方向/按钮独立控制 |
| 按钮数量限制 | ✅ 完整支持 | 1~16 可调 |
| 连发（自己按住的键） | ❌ 不支持 | 插件层物理上做不到，用官方 autofire |
| 手柄镜像 | ⚠️ 间接支持 | 手柄绑定到字段即可镜像 |
| 模拟量（摇杆轴）镜像 | ❌ 不支持 | 只处理数字量 |
| 组合键/宏 | ❌ 不支持 | 请用官方 inputmacro |
| 反向镜像（2P 控制 P1） | ⚠️ 理论可配，不推荐 | 会与 1P 物理输入冲突 |
| 网络/远程联机 | ❌ 不支持 | 完全本地 |

---

<a name="第三章"></a>
## 第三章　核心概念词典（通俗 ↔ 专业对照）

这一章是**全书最重要的章节**。因为后面的所有内容都建立在这些概念上。请务必读懂。

### 3.1 输入字段（Input Field）

| 层面 | 说明 |
|---|---|
| **通俗** | 游戏里"一个键位"的抽象。比如"1P 的上"是一个字段，"1P 的按钮 1"是另一个字段。 |
| **专业** | MAME 的 `ioport_field` 对象。每个字段有 `type`（类型枚举）、`player`（玩家号）、`mask`（端口位掩码）、`defvalue`（默认值）、`input_seq()`（绑定的按键序列）等属性。 |
| **代码位置** | `init.lua` 中 `collect_all()` 收集所有 field，存入 `entries[].fields[playerIndex]`。 |
| **举例** | 双截龙里，"1P 向右"对应一个字段，其 `type=50`（IPT_RIGHT）、`player=0`（零基，即 P1）。 |

### 3.2 玩家索引（Player Index）

**这是最容易搞混的地方，请重点看。**

MAME 内部用**零基索引**表示玩家：

```
player = 0  →  P1（1 号玩家）
player = 1  →  P2
player = 2  →  P3
player = 3  →  P4
```

但在**菜单显示**和**配置的"目标"字段**里，本插件用了**两套不同的约定**：

| 使用场景 | 索引约定 | 举例 | 说明 |
|---|---|---|---|
| MAME field.player | `0=P1, 1=P2, 2=P3, 3=P4` | `field.player == 0` | MAME 原生，不可改 |
| `sources[src]` 的 src | `0=P1, 1=P2, 2=P3, 3=P4` | `sources[0]` = P1 的配置 | 与 MAME 一致 |
| `sources[src][sem][dst]` 的 dst | `1=P2, 2=P3, 3=P4` | `[1]=true` 表示镜像到 P2 | **不含 P1**，因为"自己镜像到自己"无意义 |
| 菜单显示 `PLAYER_LABEL` | `[1]='P2', [2]='P3', [3]='P4'` | | 只显示目标 |
| 菜单显示 `PLAYER_FULL` | `[0]='P1'..[3]='P4'` | | 源和目标都用 |

> ⚠️ **坑点提示**：如果你直接改 `settings_<rom>.json`，请务必记住：`sources` 的**外键**是 0 基（0=P1），**内键**是 1 基（1=P2）。这个不对称是历史原因造成的（v4.0 时只有 P1→P2 单向，dst 用 1 基；v4.8 加入多源时 src 沿用了 MAME 的 0 基）。

### 3.3 语义键（Semantic Key / sem）

**通俗**：不管游戏内部字段叫什么名字（有的叫"P1_JOYSTICK_UP"，有的叫"IN0_BIT3"），统一翻译成人类能懂的"上、下、左、右、按钮1~16"。

**专业**：通过 `field.type`（数字枚举）反向查表得到语义键。

```lua
-- 来自 init.lua 的 IPT 枚举表
local IPT = {
    UP = 47, DOWN = 48, LEFT = 49, RIGHT = 50,   -- 方向
    BUTTON1 = 60, BUTTON2 = 61, ... BUTTON16 = 75, -- 按钮
}
```

**为什么这样做**：MAME 的字段**名字**在不同游戏、不同语言环境下会变（中文 UI 下甚至乱码），但 `type` 是**纯数字**，永远稳定。

**举例**：

| 游戏内字段名 | field.type | 翻译成语义键 |
|---|---|---|
| `P1_JOYSTICK_UP` | 47 | `UP` |
| `IN0_BIT0` | 47 | `UP`（一样！） |
| `P2_BUTTON1` | 60 | `BUTTON1` |
| `P3_START` | 不匹配 | `nil`（不处理，Start 键不镜像） |

> ⚠️ **注意**：本插件**不镜像 Start 键**、**不镜像投币键**、**不镜像 DIP 开关**。这是刻意的——镜像 Start 会导致你按 1P Start 时 2P 也"进场"，投币同理。所以 `sem_of_type()` 只认方向（47-50）和按钮（60-75），其他一律返回 `nil`。

### 3.4 目标集合（Destination Set）

**通俗**："这个键要镜像给谁"的清单。

**数据表示**：一个 Lua 表（table），键是目标玩家索引（1=P2, 2=P3, 3=P4），值是 `true`。

```lua
-- 表示"镜像到 P2 和 P3，不镜像到 P4"
{ [1] = true, [2] = true }
```

**代码位置**：`settings.sources[src][sem]` 的值就是这样一个表。

### 3.5 源（Source）

**通俗**："谁在控制别人"。

**专业**：`src` 索引，`0=P1, 1=P2, 2=P3, 3=P4`。每个源有独立的 `src_enabled` 开关。

**v4.8 之前**：只有一个源（固定 P1）。那时数据结构是 `settings.targets[sem] = {dst...}`。
**v4.8 之后**：支持任意源。数据结构升级为 `settings.sources[src][sem] = {dst...}`。

> 旧配置会自动迁移：`targets[sem]` → `sources[0][sem]`。迁移在 `apply_settings_obj()` 里完成，会在 `menu_verify` 字段标记 `migrated_targets_to_sources`。

### 3.6 覆盖（Override）与清除（clear_value）

**这是理解连发为什么做不到的关键。**

MAME 输入字段有两种"值来源"：

1. **物理来源**：玩家真的按了键盘/手柄，MAME 每帧从设备读取；
2. **程序化来源**：插件调用 `field:set_value(n)` 强制赋值。

两者关系：

| 操作 | 效果 | 对物理输入的影响 |
|---|---|---|
| `field:set_value(1)` | 程序化"按下" | 无（物理输入仍在） |
| `field:set_value(0)` | 程序化"松开" | 无（物理输入仍在） |
| `field:clear_value()` | **恢复**由物理输入决定 | 解除程序化覆盖 |

**关键洞察**：

- `set_value(0)` ≠ `clear_value()`。
- `set_value(0)` 是"我强行告诉游戏：这个键没按"。
- `clear_value()` 是"我不再插手，让物理输入说了算"。

> ⚠️ **v4.9.3 的惨痛教训**：早期版本在连发"松开相"时用了 `clear_value()`，本意是"松开"，结果因为玩家正物理按住该键，`clear_value()` 一执行，物理输入立刻又把字段顶回"按下"——"松开"永远无效，连发整体失效。**这是本项目最经典的一个坑。**

**代码位置**：

```lua
-- init.lua 中的 set_field（v5.0.1）
local function set_field(field, on)
    if on then
        field:set_value(1)
        overridden[field] = true
    else
        field:clear_value()          -- ← 注意：这里是"归还物理"
        overridden[field] = nil
    end
end
```

### 3.7 两阶段快照（Two-Phase Snapshot）

**通俗**：先"拍照"（读完所有源的状态），再"施工"（统一写入所有目标）。不要边读边写。

**为什么**：防止"互控振荡"。

**举例**：假设 P1→P2 和 P2→P1 同时开启（A 控 B，B 控 A）。如果代码这样写：

```lua
-- ❌ 错误写法（边读边写）
for each entry:
    p1_val = read(P1)
    write(P2, p1_val)      -- 此时 P2 可能已经被改
    p2_val = read(P2)      -- 读到的是刚写的值！
    write(P1, p2_val)      -- 反馈回去，形成回路
```

那么 A 和 B 会无限互相驱动，画面狂抖。

**正确写法**（本插件采用）：

```lua
-- ✅ 正确写法（两阶段）
for each entry:
    for pi = 0, 3: snap[pi] = read(pi)   -- 阶段1：全读
for each entry:
    for dst = 1, 3: write(dst, ...)      -- 阶段2：全写
```

先读完所有源，再统一写。这样即使 A↔B 互控，也只是"互换按键"，不会振荡。

### 3.8 ROM 名（rom_name）与配置隔离

**通俗**：每个游戏有自己的一套设置，互不污染。

**专业**：`emu.romname()` 返回当前 ROM 的短名（如 `ddragon`、`xmen`）。插件用它拼出配置文件名 `settings_<rom>.json`。

**为什么需要**：如果你在双截龙里设了"P1→P2"，然后切换到 X战警，不应该把双截龙的设置带过去（因为 X战警可能有不同的按钮布局）。

> ⚠️ **坑点**：MAMEUI 是**单进程跑所有游戏**。切换游戏时，插件代码**不会重新加载**（`require` 缓存在 `package.loaded`）。所以 `rom_name` 必须在每次 `prestart` 时重置，否则会继续读写上一个游戏的配置。这个修复在 v4.7.0 完成。

### 3.9 三层配置文件

| 文件 | 作用 | 何时读写 |
|---|---|---|
| `settings_default.json` | **全局模板**：跨所有游戏共用的默认值 | 每次加载时先读，作为起点 |
| `settings_<rom>.json` | **本游戏配置**：覆盖模板 | 每次加载时读，覆盖模板值 |
| `settings.json` | **旧版遗留**（v4.7 之前） | 只在首次遇到时读取并迁移，之后不再读 |

**加载顺序**：模板 → ROM 覆盖 → 都没有则从旧文件迁移。

**详见第八章。**

### 3.10 菜单动作表（Action Table）

**通俗**：菜单每一项都自带一个"按钮编号"，按下哪行就执行哪行的动作，不靠"数第几行"。

**专业**：`menu_items()` 在生成菜单的同时，把每项的动作描述写进 `actions[index]`；`menu_callback(index, event)` 直接查 `actions[index]`，不做任何偏移计算。

**为什么需要**：早期版本用硬编码 `FIXED_COUNT = 14` 计算索引，一旦菜单项数量变化（比如某游戏没有第 4 个按钮），整体错位——**按当前行，改的是上一行**。v4.6.0 用动作表根治了这个问题。

> ⚠️ **v4.9.1 的坑**：`local last_actions = {}` 被**声明了两次**（L686 和 L844）。Lua 的重复 `local` 会**遮蔽**前一个变量。结果 `menu_items` 里赋值的是 L686 那个，`menu_callback` 读的是 L844 那个永远为空的表——**所有菜单项都无响应**。这个 bug 静默、不报错，靠运行时探针才定位到。

---

<a name="第四章"></a>
## 第四章　安装前必读：环境与前提

### 4.1 你需要什么

| 项目 | 要求 | 说明 |
|---|---|---|
| **MAME** | 0.289 或更高 | 插件 API 在 0.2xx 系列稳定；官方文档建议最新版 |
| **MAMEUI64 Plus!** | 任意近期版本 | 本项目实测环境是 MAMEUI64 Plus! 0.289 |
| **操作系统** | Windows（实测） | Linux/macOS 理论上可用，未实测 |
| **磁盘** | 几十 KB | 插件本体极小 |
| **网络** | 不需要 | 完全离线运行 |
| **Python** | 仅在用脚本安装时需要 | 手动安装不需要 Python |

### 4.2 你的 MAME 插件系统必须已启用

MAME 有一个"插件总开关"。检查方法：

1. 打开 MAME；
2. 按 **Tab** 打开配置菜单；
3. 找 **Plugin Options** / **插件选项**；
4. 确认 `plugin` 全局开关是 **ON**（或者 `plugin.ini` 里没有全局禁用）。

**插件目录结构**（典型）：

```
MAMEUI64 Plus!\mameui\
    ├── mameui64.exe
    ├── mame.ini
    ├── plugin.ini          ← 插件启用状态表
    └── plugins\
        ├── boot.lua        ← 插件加载入口
        ├── inputmacro\     ← 官方插件
        ├── autofire\       ← 官方插件
        └── copilot2p\      ← ★ 本插件（安装后出现）
            ├── init.lua
            └── plugin.json
```

### 4.3 `plugin.ini` 必须有 `copilot2p 1`

打开 `plugin.ini`，里面应该有这样的行：

```ini
copilot2p 1
```

- `1` = 启用
- `0` = 禁用

如果没有这一行，MAME 不会加载插件。安装脚本会自动加，手动安装时需要自己加。

> ⚠️ **注意**：`plugin.ini` 里的名字必须与 `plugin.json` 的 `name` 字段**完全一致**（都是 `copilot2p`）。这也是为什么 v4.3.1 "菜单改中文"时，**只改了显示文本，没改 `name` 和目录名**——改了会直接加载失败。

### 4.4 关于"必须完全退出 MAMEUI 前端"

**这是本项目最容易被忽视、最容易导致"改了没效果"的坑。**

MAMEUI 的架构是：

```
MAMEUI 前端进程（启动一次，常驻）
    │
    ├─ 游戏 A（ROM 启动）
    ├─ 游戏 B（切换）
    └─ 游戏 C（切换）
```

`plugins/boot.lua` **只在进程启动时执行一次**，`require('copilot2p')` 的结果被缓存在 `package.loaded` 里。之后：

- 切换游戏 → **不会重新加载插件代码**；
- 退出游戏再进 → **不会重新加载**（进程没死）；
- 只有**完全退出 MAMEUI 前端进程再启动** → 才会重新加载。

> ⚠️ **文档历史上的错误更正**：早期文档说"退出游戏重进即可生效"，这是**错误的**。v4.8.1 实测发现：部署了 4.8.1，但 `plugin_status.json` 显示 `version=4.5.0`，证明跑的是旧代码。**正确做法：完全退出 MAMEUI 前端（任务栏图标消失）再启动。**

**如何判断当前实际运行的插件版本？**

看 `homepath/copilot2p/plugin_status.json` 里的 `version` 字段。如果是你部署的版本号，说明新代码生效了；如果不是，说明还在跑旧代码。

### 4.5 关于配置目录

插件会把状态和配置写到：

```
<homepath>/copilot2p/
```

其中 `<homepath>` 是 MAME 的 home 目录（通常是 MAME 可执行文件所在目录，或者是 `mame.ini` 里配置的 `homepath`）。

在本项目实测环境中：

```
\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui\copilot2p\
```

> ⚠️ **坑点（v4.8.1 修复）**：早期版本**不创建这个目录**，导致所有 `io.open(..., 'w')` 静默失败——状态文件不生成、配置保存不生效。v4.8.1 起，插件启动时会主动 `mkdir` 并用"写入探针"验证目录可写。如果目录不可写，错误会写进 `last_error` 并打印到 MAME 日志。

---

<a name="第五章"></a>
## 第五章　安装部署：三种路径

### 5.1 路径一：用 Python 脚本（推荐）

项目里有一个 `install_plugin.py`，可以一键安装/卸载/检查。

**前提**：Python 3.8+，且 `mame_2p` 包可被 Python 找到。

**命令**：

```bash
# 进入项目目录
cd G:\Python_Code\mame_2p

# 安装插件
python -m mame_2p install

# 检查状态
python -m mame_2p status

# 卸载插件
python -m mame_2p uninstall

# 自检（不安装，只检查环境）
python -m mame_2p selftest
```

**脚本做了什么**：

1. 检查 MAME 插件目录是否存在；
2. 把 `init.lua` 和 `plugin.json` 复制到 `<MAME>\plugins\copilot2p\`；
3. 确保 `plugin.ini` 里有 `copilot2p 1`（没有就加，已有则备份为 `plugin.ini.bak-copilot2p`）；
4. 打印结果。

> ⚠️ **v5.0.1 的重要修复**：旧版 `install_plugin.py` 在 **UNC 网络路径**上会**删掉插件**。原因是它先 `rmtree(dst)` 再 `copytree(src, dst)`，但 SMB 上 rmtree 后有目录句柄/缓存延迟，紧跟的 copytree 撞 `FileExistsError`——结果**旧目录已删、新目录没建成**，插件凭空消失（本次实测真实踩中）。
>
> 新实现改为**逐文件覆盖写入**（幂等、无删除窗口、含 3 次重试）。

### 5.2 路径二：手动复制（适合不想装 Python 的人）

**步骤**：

1. **找到 MAME 插件目录**。在 MAME 里按 Tab → Plugin Options 能看到路径，或者直接看 MAME 安装目录下的 `plugins\` 文件夹。

2. **创建子目录**：

   ```
   <MAME>\plugins\copilot2p\
   ```

3. **复制两个文件进去**：

   ```
   copilot2p\
       ├── init.lua
       └── plugin.json
   ```

4. **编辑 `plugin.ini`**（在 MAME 根目录或 `plugins\` 目录，看你的 MAME 版本）：

   用记事本打开，加一行：

   ```ini
   copilot2p 1
   ```

5. **完全退出 MAMEUI 前端，再启动**。

6. **验证**：进入任意游戏，按 Tab → Plugin Options，应该能看到 `1P联动多玩家` 这一项。

### 5.3 路径三：从备份恢复（回滚用）

项目里的 `version/` 目录保存了每个版本的完整备份：

```
version/
    ├── 20261107-v1/       ← v4.0.0 时代
    ├── 20261107-v5/       ← v4.0.0
    ├── ...
    ├── 20261107-v26/      ← v5.0.1（当前）
    └── ...
```

**回滚步骤**：

1. 从 `version/<目标版本>/` 里找到 `init.lua` 和 `plugin.json`；
2. 复制覆盖到 `<MAME>\plugins\copilot2p\`；
3. 完全退出 MAMEUI 前端再启动。

### 5.4 安装后的验证清单

安装完成后，请按这个清单逐项确认：

| # | 检查项 | 怎么查 | 期望结果 |
|---|---|---|---|
| 1 | 文件存在 | 看 `<MAME>\plugins\copilot2p\` | `init.lua` 和 `plugin.json` 都在 |
| 2 | plugin.ini 启用 | 打开 `plugin.ini` | 有 `copilot2p 1` |
| 3 | 插件被识别 | Tab → Plugin Options | 看到 `1P联动多玩家` |
| 4 | 插件真的在跑 | 看 `homepath/copilot2p/plugin_status.json` | 文件存在，`version` 是 `5.0.1` |
| 5 | 菜单能开 | 进游戏后 Tab → Plugin Options → 1P联动多玩家 | 菜单正常显示 |
| 6 | 菜单能响应 | 按上下键移动光标，左右键改值 | 值会变 |

**如果第 4 项失败**（`plugin_status.json` 不存在）：

- 检查配置目录是否存在、可写；
- 检查 MAME 日志有没有 `[copilot2p]` 开头的错误；
- 检查是否**完全退出过 MAMEUI 前端**。

---

<a name="第六章"></a>
## 第六章　第一次使用：手把手走一遍

假设你刚装好插件，要玩《X战警》（4 人版），想让 P1 控制 P2、P3。

### 第 1 步：启动游戏

1. 完全退出 MAMEUI 前端（如果已经开着）；
2. 重新启动 MAMEUI；
3. 选择《X战警》（xmen）；
4. 进入游戏画面。

> 为什么强调"完全退出"？见 [4.4 节](#44-关于必须完全退出-mameui-前端)。切换游戏不会重新加载插件代码。

### 第 2 步：让 3P/4P 进场

**这一步很多人会漏掉。** 镜像只是"喂按键"，但游戏里 3P/4P 角色要**先投币、按 Start 进场**才会出现。

1. 在游戏里按 **5**（投币键，默认）；
2. 按 **3P 的 Start 键**（默认是 `2` 或 `3`，看 MAME 默认键位）；
3. 重复投币，按 **4P 的 Start 键**。

> 如果你只看到 1P 和 2P 两个角色，说明 3P/4P 还没进场。镜像了也看不见。

### 第 3 步：打开插件菜单

1. 按 **Tab** 打开 MAME 配置菜单；
2. 找 **Plugin Options**（插件选项）；
3. 找 **1P联动多玩家**；
4. 回车进入。

### 第 4 步：认识菜单

菜单长这样（v5.0.1 典型结构）：

```
┌────────────────────────────────────────────────────────────┐
│ 1P 联动多玩家              游戏有 32 类输入                 │
│ 总开关（左右键切换）                        ON              │
│ 全部启用                    打开所有源的镜像               │
│ 全部停用                    关闭所有源的镜像               │
│ 按钮数量（左右键调整）                    4 个              │
│ ---                                                        │
│ 镜像源（谁控制谁）          先选源，再逐键设置目标         │
│ 当前编辑源（左右键切换）                   P1              │
│ 启用此源的镜像                             ON              │
│ ---                                                        │
│ 默认值（新开局/恢复默认时按此初始化）  改完立即同步到上面  │
│ 默认总开关                                 ON              │
│ 默认镜像到                                镜像到 P2        │
│ 默认按钮数量                              4 个              │
│ 恢复默认（套用上面三项）    把默认值应用到当前设置         │
│ 保存当前为默认模板          写入 settings_default.json     │
│ 重置本 ROM 配置             删除 settings_xmen.json        │
│ ---                                                        │
│ 逐项（源 P1 → 目标）    回车=开/关　左右键=选目标(可多选)  │
│ 上                                        P1 → P2          │
│ 下                                        P1 → P2          │
│ 左                                        P1 → P2          │
│ 右                                        P1 → P2          │
│ 按钮 1                                    P1 → P2          │
│ 按钮 2                                    P1 → P2          │
│ 按钮 3                                    P1 → P2          │
│ 按钮 4                                    P1 → P2          │
│ ---                                                        │
│ 状态                rom=xmen  frame=1234  err=-            │
└────────────────────────────────────────────────────────────┘
```

### 第 5 步：设置 P1 → P2+P3

1. 光标移到「**当前编辑源**」，左右键确认显示 `P1`（默认就是 P1）；
2. 光标移到「**启用此源的镜像**」，确认是 `ON`；
3. 光标移到「**上**」这一行，按**左右键**循环目标组合：

   ```
   P1 → 无  →  P1 → P2  →  P1 → P3  →  P1 → P4
        →  P1 → P2+P3  →  P1 → P2+P4  →  P1 → P3+P4
        →  P1 → P2+P3+P4  →  （循环回"无"）
   ```

4. 选到 `P1 → P2+P3`；
5. 对「下、左、右、按钮 1~4」重复同样操作。

> **小技巧**：如果所有键都要镜像到同样的人，可以先在「默认镜像到」里设好 `P2+P3`，然后按「恢复默认」——所有逐项都回落到默认值。

### 第 6 步：回到游戏测试

1. 按 **Esc** 退出插件菜单（MAME 的 Tab 菜单）；
2. 回到游戏；
3. 让 1P 按"右"；
4. 观察 2P、3P 是否也往右走。

**如果动**：成功！🎉
**如果不动**：跳转 [第十二章 故障排查](#第十二章)。

### 第 7 步：退出时保存

正常情况下插件会自动保存（每次改菜单都会 `save_settings()`）。退出游戏时 `add_machine_stop_notifier` 会再保存一次并清理覆盖。

如果你想让这套设置成为**所有游戏的默认**：

1. 进插件菜单；
2. 按「**保存当前为默认模板**」；
3. 下次新游戏会自动用这套默认值。

---

<a name="第七章"></a>
## 第七章　菜单逐项详解（v5.0.1 全项）

本章逐项解释菜单里每一个条目。请对照第六章的菜单示意图看。

### 7.1 菜单项总表

| # | 显示文本 | 类型 | 作用 | 操作 |
|---|---|---|---|---|
| 1 | 1P 联动多玩家 | 标题 | 显示游戏输入字段数量 | 无 |
| 2 | 总开关（左右键切换） | 开关 | 全局启用/禁用镜像 | 回车/左右 |
| 3 | 全部启用 | 动作 | 打开当前编辑源的镜像 | 回车 |
| 4 | 全部停用 | 动作 | 关闭当前编辑源的镜像 | 回车 |
| 5 | 按钮数量（左右键调整） | 数值 | 1~16，限制逐项显示范围 | 左右 |
| 6 | --- | 分隔 | 视觉分隔 | 无 |
| 7 | 镜像源（谁控制谁） | 标题 | 分组标题 | 无 |
| 8 | 当前编辑源（左右键切换） | 枚举 | 在 P1~P4 间切换编辑对象 | 左右 |
| 9 | 启用此源的镜像 | 开关 | 单独启用/禁用当前源 | 回车/左右 |
| 10 | --- | 分隔 | 视觉分隔 | 无 |
| 11 | 默认值（新开局/恢复默认时按此初始化） | 标题 | 分组标题 | 无 |
| 12 | 默认总开关 | 开关 | 模板层的总开关 | 回车/左右 |
| 13 | 默认镜像到 | 枚举 | 模板层的目标组合 | 左右 |
| 14 | 默认按钮数量 | 数值 | 模板层的按钮数量 | 左右 |
| 15 | 恢复默认（套用上面三项） | 动作 | 把模板应用到当前 | 回车 |
| 16 | 保存当前为默认模板 | 动作 | 把当前存为模板 | 回车 |
| 17 | 重置本 ROM 配置 | 动作 | 删除本游戏配置，回落模板 | 回车 |
| 18 | --- | 分隔 | 视觉分隔 | 无 |
| 19 | 逐项（源 P1 → 目标） | 标题 | 分组标题，显示当前源 | 无 |
| 20+ | 上/下/左/右/按钮 1..N | 枚举 | 每个键的目标组合 | 回车/左右 |
| 末 | 状态 | 展示 | rom/frame/err | 无 |

### 7.2 逐项详解

#### 7.2.1 「1P 联动多玩家」（标题行）

**显示**：`游戏有 N 类输入`，N 是 `#entries`，即识别到的方向+按钮条目总数。

**怎么读这个数字**：

- 通常 4 方向 + 若干按钮；
- 双截龙：4 + 3 = 7 左右（只有 3 个按钮）；
- X战警：4 + 8 左右（更多按钮）。

**如果 N = 0**：说明插件没识别到任何字段。原因可能是：
- 游戏还没开始（在 MAME 菜单里）；
- 游戏不是标准街机 ROM；
- `collect_all()` 出错了（看 `last_error`）。

#### 7.2.2 「总开关（左右键切换）」

**作用**：全局镜像开关。关掉时 `clear_all()` 会释放所有覆盖，物理输入恢复原样。

**操作**：回车 / 左键 / 右键 都能切换（这是刻意设计的，因为 v4.0.0 之前用 `'off'` flags 导致关掉后整行变灰、无法再选，改成了 `'lr'` + 文字 `ON/OFF`）。

**保存**：切换后立即 `save_settings()`。

#### 7.2.3 「全部启用」/「全部停用」

**作用**：作用于**当前编辑源**（`ui_src`），不是全局。

- **全部启用**：把 `settings.master = true`，`settings.src_enabled[ui_src] = true`，并清空 `settings.sources[ui_src] = nil`（让该源所有键回到"跟随默认目标"）。
- **全部停用**：把 `settings.src_enabled[ui_src] = false`，`clear_all()`，但不影响其他源和总开关。

> ⚠️ 注意"全部停用"只关**当前源**，不是关所有源。要关所有源，请用「总开关」。

#### 7.2.4 「按钮数量（左右键调整）」

**作用**：限制逐项列表显示到第几个按钮。

**范围**：1~16。

**为什么需要**：有些游戏只有 3 个按钮，但 MAME 可能声明了更多字段（比如 DIP 开关被误判）。限制数量可以让菜单更清爽。

**注意**：这只影响**显示**，不影响数据。如果你把按钮数量设成 3，但配置里按钮 4 有设置，按钮 4 的配置**仍然存在**，只是不显示，也**不会被 tick 应用**（因为 `entry_active(e)` 返回 false）。

**事实说明**：双截龙实际只有 **3 个按钮**（`type=60/61/62`），把按钮数量设成 4 或 16，第 4 个以后的按钮**不会凭空出现**——游戏本身没有那些字段。

#### 7.2.5 「镜像源（谁控制谁）」（标题行）

纯展示标题，提示下面两块是"镜像源"设置。

#### 7.2.6 「当前编辑源（左右键切换）」

**作用**：切换你正在编辑哪个源的映射。

**取值**：只在游戏里**真实存在**的玩家之间轮换。比如：
- 双截龙（2 人）：只能在 P1、P2 间切；
- X战警（4 人）：P1~P4 都能切。

**判断依据**：`exist` 列表由 `for s = 0, 3 do if any entry has e.fields[s] then ... end` 生成。

**这是 UI 游标，不持久化**。重启 MAME 后默认回到 P1。

#### 7.2.7 「启用此源的镜像」

**作用**：单独启用/禁用当前编辑源的镜像。

**数据**：`settings.src_enabled[ui_src]`。

**默认**：P1 = `true`，P2/P3/P4 = `false`。

**为什么 P2 默认关**：防止用户无意中打开 P2→P1 造成反向控制（P2 没有物理输入，等于什么都不发生，但容易困惑）。

#### 7.2.8 「默认值」区（5 项）

这一区是**模板层**，对应 `settings_default.json`。

**核心思想**：模板是"新开局时按此初始化"的默认值。改模板会**立即同步**到当前生效值。

| 项 | 数据字段 | 作用 |
|---|---|---|
| 默认总开关 | `default_master` | 新游戏的初始总开关状态 |
| 默认镜像到 | `default_targets` | 新游戏的初始目标组合 |
| 默认按钮数量 | `default_button_count` | 新游戏的初始按钮数量 |
| 恢复默认 | （动作） | 把上述三项套用到当前 |
| 保存当前为默认模板 | （动作） | 把当前生效值写成模板 |

**「默认镜像到」的循环序列**（4 人游戏）：

```
P2 → P3 → P4 → P2+P3 → P2+P4 → P3+P4 → P2+P3+P4 → （循环）
```

2 人游戏只有 `P2` 一种（正确行为，因为 P3/P4 不存在）。

> ⚠️ **坑点（v4.2.0 修复）**：早期 `entry_target_set()` 有"兜底补 P2"逻辑，导致组合枚举**永远是含 P2 的子集**，`P3`、`P4`、`P3+P4` 永远切不到。修复方法是拆成两个函数：`entry_stored_set()`（原样返回，不补全）和 `entry_target_set()`（仅生效时补全）。

#### 7.2.9 「恢复默认（套用上面三项）」

**作用**：把 `default_master` / `default_button_count` 套用到当前，并**清空所有逐项覆盖**（`settings.sources = {}`）。

**效果**：所有键回落到默认目标组合。

**典型用法**：你做了很多逐项调整，想一键重来，按这个。

#### 7.2.10 「保存当前为默认模板」

**作用**：把当前 `master` / `button_count` 存为模板，并从 `settings.sources[ui_src]` 取第一个非空目标组合存为 `default_targets`。

> ⚠️ **坑点（v4.8.0 修复）**：旧实现遍历已废弃的 `settings.targets`（恒为空），导致这个动作**静默失效**——按了没反应。新实现从 `sources[ui_src]` 取。

#### 7.2.11 「重置本 ROM 配置」

**作用**：删除 `settings_<rom>.json`，重新套用模板。

**效果**：本游戏的所有设置清空，回到默认模板。

**典型用法**：你把某个游戏玩坏了，想恢复出厂。

#### 7.2.12 「逐项（源 X → 目标）」

**标题会变**：显示当前编辑源，比如 `逐项（源 P1 → 目标）`。

**每一行**：显示一个键（上/下/左/右/按钮 N）和它当前的目标组合。

**操作语义**：

- **回车**：在当前组合序列里**前进一格**（和右键一样）；
- **左键**：后退一格；
- **右键**：前进一格。

**组合序列**（对每个键）：

```
无 → P2 → P3 → P4 → P2+P3 → P2+P4 → P3+P4 → P2+P3+P4 → （循环）
```

**"无"的含义**：该键不镜像到任何人。

**显示格式**：`P1 → P2+P3` 表示"源 P1 的键镜像到 P2 和 P3"。

**自动启用源**：如果从"无"切到任何非空组合，会自动 `settings.src_enabled[src] = true`——避免"配了但没开"的困惑。

#### 7.2.13 「状态」

**显示**：`rom=<ROM名>  frame=<帧号>  err=<错误>`

**用途**：快速判断插件是否在跑。

- `frame` 在增长 → 插件在跑；
- `err` 是 `-` → 没错误；
- `err` 有内容 → 看 [第十二章](#第十二章)。

---

<a name="第八章"></a>
## 第八章　配置文件完全解析

### 8.1 文件位置

所有配置文件在：

```
<homepath>/copilot2p/
```

典型路径：

```
\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui\copilot2p\
```

文件清单：

| 文件 | 作用 | 是否必须 |
|---|---|---|
| `plugin_status.json` | 运行时状态（插件自动写） | 自动生成 |
| `settings_default.json` | 全局默认模板 | 可选 |
| `settings_<rom>.json` | 每个游戏独立配置 | 可选 |
| `settings.json` | 旧版遗留（仅迁移用） | 迁移后不再读 |
| `.write_probe` | 写入探针（临时，写完即删） | 临时 |
| `command.json` | 旧版遗留（v1.x 时代的外部桥接用） | v1.4.0 起不再用 |

### 8.2 `plugin_status.json` 详解

这是**插件自动生成**的状态文件，每 60 帧（约 1 秒）刷新一次，是排查问题的第一手资料。

**示例**：

```json
{
  "plugin": "copilot2p",
  "version": "5.0.1",
  "rom": "xmen",
  "frame": 12345,
  "entries": 12,
  "master": true,
  "button_count": 4,
  "menu_verify": "OK 28 项",
  "last_error": "",
  "ts": 1731000000,
  "diag": {
    "records": 32,
    "players_found": [1, 2, 3, 4],
    "sem_found": ["P1:UP", "P1:DOWN", ...],
    "skipped_by_class": 0,
    "samples": ["P1_JOYSTICK_UP|t=47|p=0", ...]
  },
  "phase": "built"
}
```

**字段含义**：

| 字段 | 含义 | 排查用途 |
|---|---|---|
| `version` | 当前**实际运行**的插件版本 | 判断是否跑了新代码 |
| `rom` | 当前 ROM 名 | 判断是否切换了游戏 |
| `frame` | 帧计数器 | 判断插件是否在跑（不增长 = 卡死） |
| `entries` | 识别到的条目数 | 0 = 字段识别失败 |
| `master` | 总开关状态 | |
| `button_count` | 按钮数量 | |
| `menu_verify` | 菜单自检结果 | `OK N 项` 正常；`FAIL ...` 有问题 |
| `last_error` | 最后错误 | 空 = 无错 |
| `diag.records` | 收集到的字段记录数 | |
| `diag.players_found` | 识别到的玩家（1基） | 双截龙应为 `[1,2]`，X战警应为 `[1,2,3,4]` |
| `diag.samples` | 前 20 个字段样本 | 看字段名/type/player |
| `phase` | 生命周期阶段 | `prestart` / `built` / `stopped` |

### 8.3 `settings_default.json` 详解

**作用**：全局模板，跨所有游戏共用。

**结构**（只存三项）：

```json
{
  "default_master": true,
  "default_targets": { "1": true },
  "default_button_count": 4
}
```

**字段**：

| 字段 | 类型 | 说明 |
|---|---|---|
| `default_master` | boolean | 新游戏的初始总开关 |
| `default_targets` | object | 新游戏的初始目标组合，键是 1/2/3（1=P2, 2=P3, 3=P4） |
| `default_button_count` | number | 新游戏的初始按钮数量（1~16） |

**注意**：JSON 的键必须是**字符串**（`"1"` 不是 `1`）。Lua 读取时用 `tonumber(k)` 转换。

### 8.4 `settings_<rom>.json` 详解

**作用**：每个游戏独立配置。

**文件名**：`settings_` + ROM 名 + `.json`。ROM 名里的非法字符会被替换成 `_`：

```lua
r = r:gsub('[/\\:*?"<>|]', '_')
```

**完整示例**（X战警，P1 控制 P2+P3）：

```json
{
  "master": true,
  "button_count": 4,
  "default_master": true,
  "default_targets": { "1": true },
  "default_button_count": 4,
  "sources": {
    "0": {
      "UP":     { "1": true, "2": true },
      "DOWN":   { "1": true, "2": true },
      "LEFT":   { "1": true, "2": true },
      "RIGHT":  { "1": true, "2": true },
      "BUTTON1": { "1": true, "2": true },
      "BUTTON2": { "1": true, "2": true },
      "BUTTON3": { "1": true, "2": true },
      "BUTTON4": { "1": true, "2": true }
    }
  },
  "src_enabled": {
    "0": true,
    "1": false,
    "2": false,
    "3": false
  }
}
```

**字段详解**：

| 字段 | 类型 | 说明 |
|---|---|---|
| `master` | boolean | 当前总开关 |
| `button_count` | number | 当前按钮数量 |
| `default_*` | | 模板值（本 ROM 覆盖用） |
| `sources` | object | `sources[src][sem][dst] = true` |
| `sources.<src>` | object | src: `"0"`=P1, `"1"`=P2, `"2"`=P3, `"3"`=P4 |
| `sources.<src>.<sem>` | object | sem: `"UP"`, `"DOWN"`, `"LEFT"`, `"RIGHT"`, `"BUTTON1"`~`"BUTTON16"` |
| `sources.<src>.<sem>.<dst>` | boolean | dst: `"1"`=P2, `"2"`=P3, `"3"`=P4（**不含 P1**） |
| `src_enabled` | object | `src_enabled[src] = true/false` |

**空表 vs 缺失的语义区别**（重要）：

| 情况 | 含义 | 行为 |
|---|---|---|
| `"UP": {}` | **显式配置过**，目标为空 | 该键**不镜像**（"关不掉"问题已修复） |
| `"UP"` 键不存在 | **未配置** | 回落到 `default_targets` |

> ⚠️ **坑点（v4.8.0 修复）**：早期版本把空表当"未配置"，回落到默认，导致**关不掉**。修复后：只要 `sources[src][sem]` 是 table（哪怕空表），就算显式配置。

### 8.5 `settings.json`（旧版遗留）

**作用**：v4.7 之前的全局配置文件。

**结构**（v4.x 时代）：

```json
{
  "master": true,
  "button_count": 4,
  "enabled": { "UP": true, ... },
  "targets": { "UP": { "1": true } },
  "target": { "UP": 1 },
  "default_master": true,
  "default_targets": { "1": true },
  "default_button_count": 4
}
```

**迁移逻辑**（v4.7+）：

1. 如果 `settings_<rom>.json` 不存在，读 `settings.json`；
2. 迁移为新格式，写 `settings_<rom>.json` 和 `settings_default.json`；
3. 之后不再读旧文件。

**迁移标记**：`menu_verify = 'migrated_from_settings.json'`。

> ⚠️ **旧格式迁移规则**：
> - `targets[sem][dst]` → `sources[0][sem][dst]`
> - `enabled[sem] = false` → `sources[0][sem] = {}`（显式空表，表示关闭）
> - `target[sem] = n`（v4.0 单值） → `sources[0][sem] = { [n]=true }`

### 8.6 手动编辑配置文件的安全规则

如果你想绕过菜单直接改 JSON：

**必须做的**：

1. **先完全退出 MAMEUI 前端**（否则插件正在运行，你的修改会被覆盖）；
2. 改完后**再启动 MAMEUI**。

**必须遵守的**：

1. JSON 必须是**合法 JSON**（不能有注释、不能有尾逗号、双引号不能换成单引号）；
2. 键必须是**字符串**（`"1"` 不是 `1`）；
3. 布尔值必须是 `true` / `false`（小写，不是 `True` / `False`）；
4. 保存时用 **UTF-8 无 BOM** 编码。

**推荐做法**：改完后用任意 JSON 校验器（比如 VS Code 打开会自动提示）验证一遍。

---

<a name="第九章"></a>
## 第九章　高级用法与场景实战

### 9.1 场景一：单人玩 4 人游戏，全员同步

**需求**：一个人玩 X战警，想让 4 个角色一起行动。

**配置**：

1. 让 2P/3P/4P 都投币进场；
2. 打开插件菜单；
3. 「当前编辑源」= P1；
4. 「启用此源的镜像」= ON；
5. 对每个方向/按钮，右键切到 `P1 → P2+P3+P4`；
6. 退出菜单，开始玩。

**效果**：你按"右"，4 个角色一起往右走。

**注意**：4 个角色会**完全重叠**在同一个位置。这在某些游戏里会导致碰撞/卡位。如果游戏允许，可以考虑只镜像方向、不镜像按钮，让角色能分散。

### 9.2 场景二：两人合作，P1 控 P2 做"副驾驶"

**需求**：你和朋友玩双截龙（2 人），朋友只按 1P，你想让 2P 跟着做动作。

**配置**：

1. P2 投币进场；
2. 「当前编辑源」= P1；
3. 「默认镜像到」= `P2`；
4. 「恢复默认」——所有键回落到 P2；
5. 如果某个键不想镜像（比如你想让 P2 站着不动），单独改那个键为"无"。

**进阶**：如果朋友想在某些时候**手动**控制 2P（而不是跟随 P1），可以：
- 把「总开关」关掉 → 2P 恢复物理输入；
- 或者只关闭特定键的镜像。

### 9.3 场景三：多源合成（P1 和 P2 都能控 P3）

**需求**：你玩 3 人游戏，P3 是"公共角色"，P1 和 P2 都能控制它。

**配置**：

1. 「当前编辑源」= P1，设「启用此源的镜像」= ON，逐项设 `P1 → P3`；
2. 「当前编辑源」切到 P2，设「启用此源的镜像」= ON，逐项设 `P2 → P3`；
3. 退出。

**效果**：P3 收到的是 P1 和 P2 的 **OR 合成**——任一源按下，P3 就动。

**原理**：`sources_for_dst(e, dst)` 会收集所有控制该目标的源，tick 里取 OR。

**注意**：如果 P1 按"右"、P2 按"左"，P3 会**同时**收到右和左，游戏可能表现为"抖动"或"优先某一方向"（取决于游戏内部逻辑）。这是预期行为。

### 9.4 场景四：按游戏独立配置

**需求**：双截龙里想 P1→P2，X战警里想 P1→P2+P3+P4。

**配置**：

1. 在双截龙里设好 → 自动存 `settings_ddragon.json`；
2. 切换到 X战警 → 自动读 `settings_xmen.json`（如果没有，用默认模板）；
3. 在 X战警里设好 → 自动存 `settings_xmen.json`；
4. 之后再切换，各自读各自的。

> ⚠️ **必须完全退出 MAMEUI 前端才能切换生效**吗？不需要——**配置文件是按 ROM 名读写的**，切换游戏时 `prestart` 会重置 `rom_name` 并重新 `load_settings()`。但**插件代码本身**（`init.lua`）不会重新加载。所以：
> - 改**配置**（菜单里改）：切换游戏即生效；
> - 改**代码**（init.lua）：必须完全退出 MAMEUI 前端。

### 9.5 场景五：临时禁用

**需求**：玩到一半，不想镜像了。

**做法**：Tab → 插件菜单 → 「总开关」按回车切到 OFF。

**效果**：`clear_all()` 释放所有覆盖，2P/3P/4P 立刻恢复物理输入状态。

**恢复**：再切回 ON。

### 9.6 场景六：反向镜像（不推荐）

**需求**：让 P2 控制 P1。

**配置**：

1. 「当前编辑源」切到 P2；
2. 「启用此源的镜像」= ON；
3. 逐项设 `P2 → P1`……**等等，这里有个问题**。

**问题**：`sources[src][sem][dst]` 的 dst 范围是 1~3（P2/P3/P4），**不含 P1**。所以**无法通过菜单让 P2 控制 P1**。

**为什么这样设计**：P1 通常有物理输入（你在按键），让 P2 控制 P1 会和物理输入打架。而且 v4.8 的设计目标是"多源镜像到其他玩家"，不是"任意双向"。

**如果你真的需要**：只能改代码（`entry_stored_dst` 和 `entry_dst_set` 里 `pi = 1, 3` 改成 `pi = 0, 3` 并处理 `pi ~= src` 逻辑）。**不推荐**，容易出 bug。

### 9.7 场景七：用 Python 脚本批量改配置

如果你有很多游戏要配置，手动点菜单太累。可以写脚本直接生成 JSON：

```python
import json
import os

CONFIG_DIR = r"\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui\copilot2p"

def make_config(rom, targets):
    """
    targets: dict, sem -> list of dst (1=P2, 2=P3, 3=P4)
    """
    sources = {"0": {}}
    for sem, dsts in targets.items():
        sources["0"][sem] = {str(d): True for d in dsts}

    config = {
        "master": True,
        "button_count": 4,
        "default_master": True,
        "default_targets": {"1": True},
        "default_button_count": 4,
        "sources": sources,
        "src_enabled": {"0": True, "1": False, "2": False, "3": False},
    }

    path = os.path.join(CONFIG_DIR, f"settings_{rom}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)
    print(f"written: {path}")

# 示例：X战警，所有键镜像到 P2+P3+P4
sems = ["UP", "DOWN", "LEFT", "RIGHT",
        "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4"]
make_config("xmen", {sem: [1, 2, 3] for sem in sems})
```

> ⚠️ **运行前必须完全退出 MAMEUI 前端**，否则插件会覆盖你的修改。

---

<a name="第十章"></a>
## 第十章　原理深潜：为什么这样做才有效

本章给想理解"为什么"的读者。如果你只想用，可以跳过。

### 10.1 MAME 插件生命周期

```
MAME 进程启动
    │
    ├─ boot.lua 执行
    │     └─ require('copilot2p')  ← 只执行一次！结果缓存
    │           └─ 返回 exports 表
    │
    ├─ 用户选择 ROM，启动游戏
    │     ├─ emu.register_prestart(cb) 触发  ← 每次开游戏
    │     │     └─ 我们的 cb：重置 built=false、rom_name=nil、load_settings()
    │     │
    │     ├─ 第一帧
    │     │     └─ add_machine_frame_notifier 首次回调
    │     │           └─ tick()：built=false → build_entries() → built=true
    │     │
    │     ├─ 后续每帧
    │     │     └─ tick()：镜像逻辑
    │     │
    │     └─ 游戏结束
    │           └─ add_machine_stop_notifier 触发
    │                 └─ clear_all() + save_settings()
    │
    └─ 用户切换游戏 → 回到"启动游戏"步骤（代码不重新加载）
```

**关键点**：

1. `require` 只执行一次，代码缓存在 `package.loaded`；
2. `prestart` 每次开游戏都触发，所以**配置可以按 ROM 隔离**；
3. **改代码必须完全退出 MAMEUI 前端**。

### 10.2 为什么 `build_entries` 放在第一帧而不是 prestart

**历史教训（v1.2.0）**：

早期版本在 `emu.register_prestart` 里调 `build_pairs()`，结果 `pairs=0`——一个字段都没配上。

**根因**：`prestart` 时点，ioport 未必完整初始化。field 的 `enabled`、`type_class` 等属性可能还是默认值。

**修复**：改到**第一帧**执行。此时 `machine` 已完整初始化，所有字段属性就绪。

**代码位置**：

```lua
-- tick() 里
if not built then
    built = true
    local ok, err = pcall(build_entries)
    if not ok then last_error = 'build_entries: ' .. tostring(err) end
    write_status({ phase = 'built' })
end
```

### 10.3 字段筛选的三层过滤

`collect_all()` 收集字段时，有三层过滤：

```lua
-- 第1层：类型类（type_class）
--   MAME 的字段有 type_class 属性，'controller' 是真正的控制器输入
--   DIP 开关、配置项等不是
if tc ~= nil then
    is_ctrl = TYPE_CLASS_ALLOW[tostring(tc)] == true
end

-- 第2层：模拟量
--   摇杆轴是 analog，我们只处理数字量（按钮式方向）
if is_ctrl and (not analog) then ...

-- 第3层：启用状态
--   未启用的字段（用户禁用的）跳过
if ... and enabled then ...
```

**为什么去掉"强求 `type_class == 'controller'`"**：

v1.2.0 之前强求 `type_class == 'controller'`，结果**所有字段都被滤掉**——因为实测部分驱动此字段为 `nil` 或其他值。

**修复**：改成"如果 `type_class` 存在就检查，不存在则用 `type` 数字兜底"：

```lua
elseif ty ~= nil and TYPE_BLOCK[tonumber(ty)] then
    is_ctrl = false
end
```

`TYPE_BLOCK = { [5]=true, [6]=true, [7]=true }` 是已知的非控制器类型（DIP 等）。

### 10.4 为什么读 `input_seq` 而不是 `port:read()`

**v4.9.11 的尝试（方案B）**：

曾经试过用 `port:read()` 读端口原始值 + `defvalue` 判断极性。

**为什么失败**：

1. **极性判断不可靠**：`defvalue` 在 xmen 方向键上判反了。快照振荡经镜像传给被控者，表现为"2P 方向像被连发乱走"。
2. **自锁**：读回自己刚写的覆盖值，off 相后脉冲起不来，主控连发全废。

**v4.9.12 回退**：恢复 `input_seq + seq_pressed` 物理绑定读取。

```lua
-- 现在的 src_pressed
local function src_pressed(e, src)
    local f = e.fields[src]
    if not f then return false end
    local seq = safe(function() return f:input_seq('standard') end, nil)
    if not seq then return false end
    return safe(function() return input_manager:seq_pressed(seq) end, false)
end
```

**为什么这样读是对的**：

- `input_seq('standard')` 返回该字段绑定的**物理按键序列**（比如"右方向键"）；
- `input_manager:seq_pressed(seq)` 返回这个序列**当前是否被按下**；
- 这是**物理状态**，不是字段值，所以**不会被 `set_value` 覆盖影响**；
- 两阶段快照避免了互控振荡。

### 10.5 为什么主控连发在插件层做不到

这是本项目最重要的技术结论之一，值得详细解释。

**场景**：P1 物理按住"射击键"，想让这个键自动连发。

**天真做法**：每帧检测到 P1 按住，就交替 `set_value(1)` / `set_value(0)`。

**为什么失败**：

MAME 每帧的输入处理顺序大致是：

```
1. 从物理设备读取输入 → 更新字段的"物理值"
2. 执行插件的 frame_notifier
3. 游戏逻辑读字段值
```

问题出在**第 1 步和第 2 步之间**：

- 第 1 步：物理键按住，字段物理值 = 1；
- 第 2 步：插件 `set_value(0)`，程序化覆盖 = 0；
- **但是**：下一帧第 1 步，物理键还是按住，字段物理值又是 1；
- 如果插件在"松开相"用了 `clear_value()`，物理值立刻顶回 1。

**实测证据（v4.9.10 探针）**：

```
af_set1=127 与按住时长精确 1:2
```

意思是：插件调用了 127 次 `set_value(1)`，但游戏实际看到的按下时长是物理按住时长的 2 倍——说明 `set_value(0)` **完全没起作用**，每次都被物理输入顶回。

**结论**：

- **被控者**（P2/P3/P4）连发**有效**——它们没有物理竞争，`set_value` 脉冲能落地；
- **主控**（P1 自己按住的键）连发**无效**——每帧物理刷新把 `set_value(0)` 顶回按下态。

**官方 autofire 为什么能行**：它连发的是"**没被按住的另一个热键**"（你按一个键触发，它连发另一个键）。目标键无物理竞争，所以有效。

**最终决定**：v5.0.0 彻底移除连发功能，主控连发需求引导到 MAME 官方 autofire 插件。这是**诚实的产品决策**——把做不到的事说清楚，比留个半残功能好。

### 10.6 为什么需要 `overridden` 表

`overridden[field] = true` 记录"这个字段被我们程序化覆盖过"。

**作用**：退出/停用时，`clear_all()` 遍历 `overridden`，对每个字段 `clear_value()`，把控制权还给物理输入。

**为什么需要**：

- 如果不记录，退出时不知道该清理哪些字段；
- 如果对所有字段都 `clear_value()`，会误伤那些我们从没碰过的字段（虽然理论上无害，但多此一举）。

**代码**：

```lua
local function clear_all()
    for field in pairs(overridden) do
        pcall(function() field:clear_value() end)
    end
    overridden = {}
end
```

### 10.7 为什么 `pcall` 到处都是

Lua 的 `pcall` 是"保护调用"——出错不崩，返回 `false, err`。

**为什么用**：

- MAME 的 API 在某些时点（比如游戏退出中）会抛错；
- 如果不用 `pcall`，一个错误就会让整个 tick 崩掉，后续帧都不执行；
- 用了 `pcall`，出错只影响当前操作，下一帧继续。

**代价**：错误被静默吞掉，排查困难。所以关键地方会写 `last_error`：

```lua
local ok, err = pcall(tick)
if not ok then last_error = 'tick: ' .. tostring(err) end
```

### 10.8 菜单动作表的完整数据流

```
menu_items() 被 MAME 调用
    │
    ├─ 生成 items 列表（显示用）
    ├─ 同时生成 actions 列表（动作描述）
    │     actions[1] = nil          （标题，无动作）
    │     actions[2] = {kind='master'}
    │     actions[3] = {kind='all_on'}
    │     ...
    │     actions[20] = {kind='mirror', sem='UP', src=0}
    │
    ├─ last_actions = actions
    ├─ 自检：actions 与 items 一一对应
    └─ return items

用户按回车/左右
    │
menu_callback(index, event) 被 MAME 调用
    │
    ├─ a = last_actions[index]
    ├─ if not a then return false end
    ├─ if a.kind == 'master' then ...
    ├─ elseif a.kind == 'mirror' then ...
    └─ return true
```

**为什么这样设计**：

- 菜单项数量是**动态的**（不同游戏按钮数不同）；
- 任何硬编码 `FIXED_COUNT` 都会在增删菜单项后错位；
- 动作表让"第几行 = 什么动作"自动对应，永远不错。

---

<a name="第十一章"></a>
## 第十一章　源码导读：给想改代码的人

### 11.1 文件结构

`init.lua` 共 1074 行（v5.0.1），大致分区：

| 行号范围 | 内容 |
|---|---|
| 1-30 | 头部注释、exports 定义、版本号 |
| 31-60 | 局部变量、IPT 枚举、标签表 |
| 61-120 | `settings` 默认值表 |
| 121-180 | 工具函数（`safe`, `sem_of_type`, `collect_all`）|
| 181-260 | `build_entries`（构建条目） |
| 261-450 | 持久化（路径、读写、迁移） |
| 451-520 | `save_settings` / `save_defaults` / `apply_defaults` / `reset_rom_settings` |
| 521-560 | `write_status` |
| 561-620 | 镜像核心（`clear_all`, `set_field`, `entry_active`） |
| 621-720 | 多源逻辑（`src_active`, `entry_stored_dst`, `entry_dst_set`, `sources_for_dst`, `src_pressed`） |
| 721-800 | `tick`（主循环） |
| 801-900 | 菜单（`menu_items`） |
| 901-1074 | `menu_callback` + `startplugin` |

### 11.2 关键函数速查

| 函数 | 作用 | 调用时机 |
|---|---|---|
| `sem_of_type(ty)` | 数字 type → 语义键 | `build_entries` 里 |
| `collect_all()` | 收集所有 field | `build_entries` 里 |
| `build_entries()` | 构建有序条目 | 第一帧 |
| `load_settings()` | 加载配置 | prestart |
| `save_settings()` | 保存配置 | 菜单改动、退出 |
| `write_status()` | 写状态文件 | 每 60 帧、生命周期节点 |
| `tick()` | 主循环 | 每帧 |
| `menu_items()` | 生成菜单 | MAME 请求时 |
| `menu_callback()` | 处理菜单事件 | 用户按键时 |
| `startplugin()` | 插件入口 | MAME 加载时 |

### 11.3 想加新功能？改哪里

#### 想加一个"镜像延迟 N 帧"

在 `tick()` 里维护一个环形缓冲，`snap` 不直接用当前值，而是 N 帧前的值。

**改点**：

```lua
-- 在 tick 外定义
local history = {}  -- history[pi][sem] = 环形缓冲

-- 在 tick 里，读快照时
if not history[pi] then history[pi] = {} end
if not history[pi][e.sem] then history[pi][e.sem] = {} end
table.insert(history[pi][e.sem], src_pressed(e, pi))
if #history[pi][e.sem] > DELAY then table.remove(history[pi][e.sem], 1) end
snap[pi] = history[pi][e.sem][1]
```

#### 想加"只在特定游戏生效"

在 `build_entries` 或 `tick` 里检查 `emu.romname()`：

```lua
local ALLOWED_ROMS = { xmen = true, ddragon = true }
if not ALLOWED_ROMS[emu.romname()] then return end
```

#### 想加"镜像到 Start 键"

在 `IPT` 表里加 `START = 51`（IPT_START），但**不推荐**——镜像 Start 会导致玩家进场混乱。

#### 想加"组合键"

这个超出本插件范围，建议用官方 `inputmacro` 插件。

### 11.4 改代码的注意事项

1. **改完必须完全退出 MAMEUI 前端**才生效；
2. **改完先备份**（复制到 `version/YYYYMMDD-vN/`）；
3. **改完做语法检查**（项目有 `check_lua.py`，虽然本机无 luac，但能做词法平衡检查）；
4. **版本号同步改**：`exports.version` 和 `plugin.json.version` 两处；
5. **不要在 `menu_items` 外写 `local last_actions`**（v4.9.1 的坑）；
6. **前向声明的函数用赋值而非 `local function`**（v4.7.0 的坑）。

### 11.5 静态检查工具

项目里有 `check_lua.py`（无 luac 时的替代品）：

```bash
python -m mame_2p check_lua <init.lua>
```

它检查：

- 括号平衡（剥离注释/字符串后）；
- 字符串引号配对；
- 长字符串 `[[...]]` 配对；
- 块关键字统计（`function` / `if` / `for` / `while` / `do` vs `end`）。

**局限**：不做真实语法分析，不能替代 `luac -p`。如果本机装了 Lua，建议：

```bash
luac -p init.lua
```

### 11.6 部署到 MAME 的流程

```bash
# 1. 改 G 盘源码
#    G:\Python_Code\mame_2p\plugins\copilot2p\init.lua

# 2. 词法检查
python -m mame_2p check_lua plugins/copilot2p/init.lua

# 3. 复制到 MAME
python -m mame_2p install

# 4. 验证 SHA256 一致
#    （脚本会打印）

# 5. 完全退出 MAMEUI 前端，再启动

# 6. 进游戏，看 plugin_status.json 的 version
```

---

<a name="第十二章"></a>
## 第十二章　故障排查手册（症状 → 原因 → 处方）

本章按"症状"组织。找到你的症状，按处方排查。

### 12.1 症状：插件菜单里看不到「1P联动多玩家」

| 可能原因 | 检查方法 | 处方 |
|---|---|---|
| 插件没装 | 看 `<MAME>\plugins\copilot2p\` 是否存在 | 重新安装（第五章） |
| `plugin.ini` 没启用 | 打开看有没有 `copilot2p 1` | 加上 |
| 插件全局开关关了 | Tab → Plugin Options | 打开全局 plugin |
| MAME 版本太老 | 看 MAME 版本 | 升级到 0.289+ |
| 没完全退出 MAMEUI 前端 | | 完全退出再启动 |

### 12.2 症状：菜单能显示，但所有项按回车/左右都没反应

**历史 bug（v4.9.1 已修复）**：`local last_actions = {}` 被声明了两次，导致 `menu_callback` 读到永远为空的表。

**检查**：

```bash
# 搜 last_actions 声明次数
grep -c "local last_actions" init.lua
# 应该是 1
```

**如果不是 1**：你用的是旧版本，升级到 v4.9.1+。

### 12.3 症状：菜单能改值，但游戏里 2P/3P/4P 不动

**按顺序排查**：

1. **2P/3P/4P 是否进场？**
   - 投币、按 Start，确认角色出现在画面上。
   - 如果只有 1P 角色，镜像了也看不见。

2. **`plugin_status.json` 的 `entries` 是否 > 0？**
   - 如果 0：字段识别失败。看 `diag` 字段。
   - `diag.players_found` 应该是 `[1,2]`（双截龙）或 `[1,2,3,4]`（X战警）。

3. **`diag.players_found` 里有没有目标玩家？**
   - 双截龙是 2 人游戏，`players_found` 只有 `[1,2]`。镜像到 P3/P4 当然不生效（正常行为）。

4. **`src_enabled[0]` 是不是 `true`？**
   - 看 `settings_<rom>.json`。

5. **`sources` 里有没有该键的配置？**
   - 如果没有，会回落到 `default_targets`。检查默认值。

6. **游戏是不是不接受程序化输入？**
   - 极少数游戏可能对 `set_value` 不敏感。换游戏测试。

7. **`last_error` 有没有内容？**
   - 有的话，按错误信息排查。

### 12.4 症状：`plugin_status.json` 不存在

**历史 bug（v4.8.1 已修复）**：配置目录不创建，`io.open(..., 'w')` 静默失败。

**检查**：

1. `<homepath>/copilot2p/` 目录存在吗？
2. 目录可写吗？（在网络盘上，权限可能有问题）

**处方**：

- 升级到 v4.8.1+；
- 手动创建目录；
- 检查网络盘权限。

**验证**：`plugin_status.json` 里的 `last_error` 如果是 `dir not writable: ...`，说明目录不可写。

### 12.5 症状：改了菜单，但下次进来又变回去了

**可能原因**：

1. **配置目录不可写**（见 12.4）；
2. **`settings_<rom>.json` 被手动改坏了**（JSON 非法）；
3. **用的是旧版本**（v4.8.1 之前的保存有 bug）。

**排查**：

1. 看 `plugin_status.json` 的 `last_error`；
2. 检查 `settings_<rom>.json` 是否能被 JSON 解析器读取；
3. 升级版本。

### 12.6 症状：`plugin_status.json` 的 `version` 是旧版本号

**根因**：没有完全退出 MAMEUI 前端，`require` 缓存还在。

**处方**：完全退出 MAMEUI 前端（任务栏图标消失），再启动。

**验证**：`plugin_status.json` 的 `version` 应该等于你部署的版本。

### 12.7 症状：切换游戏后设置错乱

**根因**：`rom_name` 没重置，继续读写上一个游戏的配置。

**检查**：`plugin_status.json` 的 `rom` 字段是不是当前游戏。

**处方**：升级到 v4.7.0+（`prestart` 里会重置 `rom_name`）。

### 12.8 症状：2P 方向"像被连发乱走"

**历史 bug（v4.9.11~v4.9.12）**：方案B 用 `port:read()` + `defvalue` 判极性，在 xmen 方向键上判反。

**处方**：升级到 v4.9.12+（回退到 `input_seq` 读取）。

### 12.9 症状：连发不生效

**说明**：v5.0.0 起**连发已移除**。本插件不做连发。

**处方**：用 MAME 官方 autofire 插件（Tab → Plugin Options → 连发）。

**为什么**：见 [10.5 节](#105-为什么主控连发在插件层做不到)。主控连发在插件层物理上做不到。

### 12.10 症状：`install_plugin.py` 把插件删没了

**历史 bug（v5.0.1 已修复）**：`rmtree(dst)` + `copytree(src, dst)` 在 UNC 路径上有删除窗口，旧目录删了、新目录没建成。

**处方**：升级到 v5.0.1+（改为逐文件覆盖写入）。

**急救**：从 `version/` 备份目录手动复制回来。

### 12.11 症状：菜单里 `menu_verify` 显示 `FAIL`

**含义**：菜单自检发现"可操作项没有动作"或"动作表为空"。

**排查**：

- `FAIL actions空 items=N`：`last_actions` 是空表。检查是否重复声明（见 12.2）。
- `FAIL N 个可操作项无动作`：某个 `push` 漏登记动作。这是代码 bug，需要修 `menu_items`。

### 12.12 症状：MAME 日志里有 `[copilot2p]` 错误

**看错误内容**：

| 错误 | 原因 | 处方 |
|---|---|---|
| `dir not writable: ...` | 配置目录不可写 | 检查权限 |
| `build_entries: ...` | 字段收集出错 | 看 `diag` |
| `tick: ...` | 主循环出错 | 看具体错误 |

### 12.13 症状：游戏崩溃或卡死

**极罕见**，但要排查：

1. 关闭插件，看是否恢复 → 确认是插件问题；
2. 看 MAME 日志最后几行；
3. 换游戏测试，确认是否特定游戏。

**注意**：本插件只读写输入字段，理论上不会导致游戏崩溃。如果确实崩溃，请提交 GitHub Issue，附上 MAME 日志和 `plugin_status.json`。

### 12.14 通用排查流程

```
1. 看 plugin_status.json 是否存在
   ├─ 不存在 → 12.4
   └─ 存在 → 2
2. 看 version 是否正确
   ├─ 不对 → 12.6
   └─ 对 → 3
3. 看 entries 是否 > 0
   ├─ 0 → 12.3 步骤2
   └─ >0 → 4
4. 看 last_error 是否为空
   ├─ 不为空 → 12.12
   └─ 空 → 5
5. 看 menu_verify 是否 OK
   ├─ FAIL → 12.11
   └─ OK → 6
6. 看 diag.players_found
   ├─ 缺目标玩家 → 游戏本身不支持
   └─ 齐全 → 7
7. 看 settings_<rom>.json 的 sources
   ├─ 空 → 配置没存
   └─ 有 → 8
8. 看游戏里 2P/3P/4P 是否进场
   ├─ 没进场 → 投币、Start
   └─ 进场了 → 提交 Issue
```

---

<a name="第十三章"></a>
## 第十三章　性能、限制与已知问题

### 13.1 性能

| 指标 | 数值 | 说明 |
|---|---|---|
| 每帧开销 | 微秒级 | 只遍历几十个字段，读写很轻 |
| 状态文件写入 | 每 60 帧一次 | 约 1 秒一次，IO 很小 |
| 配置保存 | 只在菜单改动时 | 不影响游戏帧率 |
| 内存 | 几 MB | Lua 表很小 |

**实测**：在 MAMEUI 0.289 + 双截龙上，未观察到帧率下降。

### 13.2 已知限制

| 限制 | 说明 | 能否绕过 |
|---|---|---|
| 必须完全退出 MAMEUI 前端才加载新代码 | `require` 缓存 | 无 |
| 主控连发做不到 | 物理刷新顶回 | 用官方 autofire |
| 不支持模拟量 | 只处理数字量 | 无 |
| 不支持反向（P2→P1） | dst 范围 1~3 | 改代码（不推荐） |
| 不镜像 Start/投币 | 刻意设计 | 无 |
| 只在插件加载时识别字段 | 运行时新增字段不识别 | 重启游戏 |
| 多显示器环境未验证 | | 理论无影响 |
| Linux/macOS 未实测 | | 理论可用 |

### 13.3 已知问题（截至 v5.0.1）

| # | 问题 | 状态 | 备注 |
|---|---|---|---|
| 1 | 主控连发 | ❌ 设计上不支持 | v5.0.0 移除 |
| 2 | 反向镜像（P2→P1） | ⚠️ 不支持 | 需改代码 |
| 3 | 组合同帧振荡（P1↔P2 互控） | ⚠️ 可能出现 | 两阶段快照已缓解 |
| 4 | 未做运行时验证（本机无 luac） | ⚠️ 静态检查 | 见 13.4 |

### 13.4 关于"运行时验证"的诚实说明

**必须如实告知**：

1. 本项目开发环境**没有 Lua 解释器**（无 `luac` / `lua` / `lupa` / `luaparser`）；
2. 所有 Lua 代码只做了**静态词法检查**（括号平衡、块关键字统计）；
3. **未做真实语法/运行时验证**；
4. 部署后靠 `plugin_status.json` 和实机表现验证。

**这意味着**：理论上存在"静态检查通过但运行时报错"的可能。如果你遇到运行时错误，请把 `last_error` 和 MAME 日志提交到 GitHub Issue。

### 13.5 版本兼容性

| MAME 版本 | 兼容性 | 说明 |
|---|---|---|
| 0.289 | ✅ 实测通过 | 开发环境 |
| 0.2xx | ✅ 理论可用 | 插件 API 稳定 |
| 0.1xx | ⚠️ 未测试 | API 可能有差异 |
| 0.3xx+ | ⚠️ 未测试 | 未来版本 |

---

<a name="第十四章"></a>
## 第十四章　版本历史与每次更新的一句话简报

### 14.1 全版本时间线（一句话简报版）

> 这一节是给"想快速了解演进"的读者。详细记录见项目根目录的 `软件升级迭代记录.md`。

#### Python 主线（mame_2p 包）

| 版本 | 日期 | 一句话简报 |
|---|---|---|
| v1.0.0 | 2026-11-06 | 首次交付，方案一：外部按键守护（Python SendInput） |
| v1.1.0 | 2026-11-06 | 新增方案二：MAME 官方 Lua 插件 copilot2p，真跟随 1P |
| v1.2.0 | 2026-11-06 | 修复视觉通道（CPU 不支持 SSE4.2 导致 numpy 崩），插件首次跑通但 `pairs=0` |
| v1.3.0 | 2026-11-06 | 项目迁移到 `G:\Python_Code`，修复可移植性 |
| **v1.4.0** | 2026-11-07 | **移除方案一（SendInput 对 MAME 无效），项目聚焦插件** |

#### 插件主线（copilot2p）

| 版本 | 日期 | 一句话简报 |
|---|---|---|
| v4.0.0 | 2026-11-07 | 多路镜像 + 按钮数量可配 + 菜单重构（从 v3.x 跳到 v4.0） |
| v4.1.0 | 2026-11-07 | 1P 同时控 P2+3P+4P（多选目标） |
| v4.2.0 | 2026-11-07 | 修复玩家组合枚举不全（P3/P4 被吞） |
| v4.3.0 | 2026-11-07 | 新增三项默认值配置（默认总开关/默认镜像到/默认按钮数量） |
| v4.3.1 | 2026-11-07 | 菜单名改中文（`Copilot` → `1P联动多玩家`） |
| v4.4.0 | 2026-11-07 | 新增按键连发（逐键开关 + 节奏可调） |
| v4.5.0 | 2026-11-07 | 连发支持"统一开关 + 按玩家独立" |
| v4.6.0 | 2026-11-07 | 菜单动作表分发（根治索引错位"按当前行改上一行"） |
| v4.7.0 | 2026-11-07 | 按 ROM 独立配置 + 菜单索引自检 |
| v4.8.0 | 2026-11-07 | 多源镜像（任意玩家→任意玩家） |
| v4.8.1 | 2026-11-07 | 修复配置目录缺失导致保存全部失效 |
| v4.9.1 | 2026-11-07 | 修复菜单全部无响应（重复 local 声明） |
| v4.9.2 | 2026-11-07 | 连发纳入 P1 + 被控不给开关（防环路） |
| v4.9.3 | 2026-11-07 | 修复连发整体失效（`clear_value` 被物理顶回） |
| v4.9.12 | 2026-11-07 | 回退方案B读取，恢复物理绑定读取（`input_seq`） |
| v5.0.0 | 2026-11-07 | 移除连发，纯镜像（主控连发插件层做不到，引导官方 autofire） |
| **v5.0.1** | **2026-11-07** | **清除删连发遗留的语法残渣（修复插件加载失败）+ 修复 install_plugin.py UNC 路径删插件** |

### 14.2 各版本的关键教训汇总

> 这一节是**给开发者看的**。每个教训都是"踩过的坑"。

| 版本 | 教训 | 类型 |
|---|---|---|
| v1.2.0 | `prestart` 时 ioport 未就绪，字段收集应放第一帧 | 生命周期 |
| v1.4.0 | `SendInput` 不进入 RawInput 流，对 MAME 无效 | 架构 |
| v4.2.0 | "兜底补 P2"污染了组合枚举，导致 P3/P4 永远切不到 | 逻辑 |
| v4.6.0 | 硬编码 `FIXED_COUNT` 在动态菜单下必然错位 | 架构 |
| v4.7.0 | `local function f()` 会遮蔽前向声明 `local f`，要用 `f = function()` | Lua 陷阱 |
| v4.8.1 | `io.open(..., 'w')` 在目录缺失时**静默失败**，必须主动 `mkdir` + 写探针 | 持久化 |
| v4.9.1 | 重复 `local` 声明是**静默失效**的典型成因，排查优先统计声明次数 | Lua 陷阱 |
| v4.9.3 | `clear_value()` 是"归还物理"，不是"松开"；连发松开相必须用 `set_value(0)` | MAME API |
| v4.9.12 | `port:read()` + `defvalue` 判极性不可靠，`input_seq` 才是物理真值 | MAME API |
| v5.0.1 | 删代码要删干净，残留的孤立 `}` 会让整个文件非法 | 工程 |
| v5.0.1 | `rmtree` + `copytree` 在 UNC 路径上有删除窗口，要改逐文件覆盖 | 工程 |

### 14.3 版本号规则

本项目用 `主版本.次版本.修订号`：

- **主版本**：架构级变更（如 v4→v5 移除连发）；
- **次版本**：新功能（如 v4.7→v4.8 多源镜像）；
- **修订号**：bug 修复（如 v5.0.0→v5.0.1）。

**注意**：v3.x 到 v4.0 是一次大跨越（多路镜像重构），中间有备份 `version/20261107-v5-pre-v4/`。

---

<a name="第十五章"></a>
## 第十五章　开发、测试与贡献

### 15.1 项目结构

```
G:\Python_Code\mame_2p\
    ├── mame_2p\                    ← Python 包
    │   ├── __init__.py             ← APP_VERSION
    │   ├── __main__.py             ← CLI 入口
    │   ├── config.py               ← 配置模型
    │   ├── install_plugin.py       ← 安装脚本
    │   ├── check_lua.py            ← Lua 静态检查
    │   ├── verify_plugin_load.py   ← 插件加载前置校验
    │   └── ...
    ├── plugins\copilot2p\          ← 插件源
    │   ├── init.lua                ← 核心代码
    │   └── plugin.json             ← 元数据
    ├── version\                    ← 版本备份
    │   ├── 20261107-v1\
    │   ├── ...
    │   └── 20261107-v26\           ← v5.0.1
    ├── run.bat                     ← Windows 一键入口
    └── 软件升级迭代记录.md           ← 完整迭代日志
```

### 15.2 开发流程

```
1. 改 G 盘源码
   G:\Python_Code\mame_2p\plugins\copilot2p\init.lua
   ↓
2. 词法检查
   python -m mame_2p check_lua plugins/copilot2p/init.lua
   ↓
3. 备份
   复制到 version/YYYYMMDD-vN/
   ↓
4. 版本号同步
   init.lua 的 exports.version
   plugin.json 的 version
   ↓
5. 部署
   python -m mame_2p install
   ↓
6. 验证 SHA256
   ↓
7. 完全退出 MAMEUI 前端，启动
   ↓
8. 看 plugin_status.json
   ↓
9. 实机测试
   ↓
10. 更新迭代记录
```

### 15.3 提交 Issue 的规范

通过 GitHub Issues 提交。**请包含**：

1. **版本号**（`plugin_status.json` 的 `version`）；
2. **MAME 版本**（如 `MAMEUI64 Plus! 0.289`）；
3. **游戏 ROM 名**（如 `ddragon`、`xmen`）；
4. **`plugin_status.json` 完整内容**；
5. **MAME 日志中 `[copilot2p]` 开头的行**；
6. **复现步骤**（1. 2. 3. ...）；
7. **期望行为 vs 实际行为**。

**不要**：

- 只发一句"不生效"（无法排查）；
- 发私人邮箱（项目不提供私人支持）；
- 发游戏 ROM 文件（版权问题）。

### 15.4 贡献代码

欢迎 PR。建议：

1. 先开 Issue 讨论，避免白做；
2. 保持代码风格（现有代码用 tab 缩进、`local` 优先、`pcall` 保护）；
3. 更新 `软件升级迭代记录.md`；
4. 更新版本号；
5. 在 PR 描述里写明"改了什么、为什么、怎么验证"。

### 15.5 测试建议

由于本机无 luac，建议贡献者：

1. 在本地装 Lua 5.4，用 `luac -p init.lua` 做语法检查；
2. 用 `lua` 跑一个最小测试环境，mock 掉 MAME API；
3. 至少在一个 2 人游戏和一个 4 人游戏上实测。

---

<a name="第十六章"></a>
## 第十六章　常见问题 FAQ（50 问）

### 安装与启动

**Q1：我需要装 Python 吗？**
A：只有用 `install_plugin.py` 脚本安装时需要。手动复制文件不需要。

**Q2：支持 Linux/Mac 吗？**
A：理论支持（MAME 跨平台），但未实测。路径和 `lfs` 行为可能有差异。

**Q3：为什么装完没效果？**
A：99% 是因为没完全退出 MAMEUI 前端。`require` 缓存导致代码不重新加载。

**Q4：怎么确认插件在跑？**
A：看 `<homepath>/copilot2p/plugin_status.json`。文件存在且 `version` 正确 = 在跑。

**Q5：能装在便携版 MAME 上吗？**
A：可以。插件的路径基于 `homepath`，便携版也有这个目录。

**Q6：`plugin.ini` 在哪？**
A：通常在 MAME 根目录，或 `plugins/` 目录。看 MAME 版本。

**Q7：怎么卸载？**
A：`python -m mame_2p uninstall`，或手动删 `plugins\copilot2p\` 目录。

**Q8：卸载后配置还在吗？**
A：在。配置在 `<homepath>/copilot2p/`，卸载插件不会删配置。

### 配置与使用

**Q9：设置会保存吗？**
A：会。每次菜单改动立即 `save_settings()`，退出时再存一次。

**Q10：每个游戏配置独立吗？**
A：是。`settings_<rom>.json` 按 ROM 名隔离。

**Q11：怎么让所有游戏用同样设置？**
A：按「保存当前为默认模板」，新游戏会用它初始化。

**Q12：怎么恢复出厂设置？**
A：按「重置本 ROM 配置」（只影响当前游戏），或删 `settings_default.json`（影响所有新游戏）。

**Q13：「按钮数量」设 16 会怎样？**
A：只显示游戏实际有的按钮。双截龙只有 3 个，设 16 也不会多出 13 个。

**Q14：为什么双截龙镜像到 P3 不生效？**
A：双截龙是 2 人游戏，没有 P3 字段。这是正常行为。

**Q15：能镜像 Start 键吗？**
A：不能。刻意设计。镜像 Start 会导致玩家进场混乱。

**Q16：能镜像投币吗？**
A：不能。同上。

**Q17：能镜像手柄吗？**
A：间接可以。手柄只要绑定到了 MAME 字段，就随字段一起镜像。

**Q18：能镜像摇杆轴（模拟量）吗？**
A：不能。只处理数字量。

**Q19：能连发吗？**
A：本插件不做连发（v5.0.0 移除）。用 MAME 官方 autofire 插件。

**Q20：为什么主控连发做不到？**
A：物理刷新会把 `set_value(0)` 顶回按下态。详见第十章。

**Q21：能让 P2 控制 P1 吗？**
A：不支持。dst 范围是 1~3（P2/P3/P4）。

**Q22：多个源控同一个目标会怎样？**
A：OR 合成。任一源按下，目标就动。

**Q23：P1 和 P2 互相控制会振荡吗？**
A：不会。两阶段快照（先读后写）避免振荡，表现为"互换按键"。

**Q24：镜像有延迟吗？**
A：有一帧延迟（读快照 → 下一帧写）。约 16ms，肉眼不可察。

**Q25：能只镜像方向不镜像按钮吗？**
A：能。逐项设置，每个键独立。

**Q26：能按游戏自动切换配置吗？**
A：能。`settings_<rom>.json` 自动按 ROM 读写。

**Q27：配置文件能用文本编辑器改吗？**
A：能，但要先完全退出 MAMEUI 前端，且必须是合法 JSON。

**Q28：JSON 里的键是 `"1"` 还是 `1`？**
A：必须是字符串 `"1"`。JSON 标准要求。

**Q29：`sources` 的 `"0"` 是什么意思？**
A：源玩家 P1（0 基）。`"1"`=P2, `"2"`=P3, `"3"`=P4。

**Q30：`dst` 的 `"1"` 是什么意思？**
A：目标玩家 P2（1 基）。`"1"`=P2, `"2"`=P3, `"3"`=P4。**不含 P1**。

**Q31：为什么 src 和 dst 的基不一样？**
A：历史原因。src 沿用 MAME 的 0 基，dst 从 v4.0 就是 1 基。

### 故障排查

**Q32：菜单显示但按键没反应？**
A：可能是重复 `local last_actions` 的 bug（v4.9.1 已修）。升级。

**Q33：`plugin_status.json` 不生成？**
A：配置目录不存在或不可写。v4.8.1 已修，升级。

**Q34：`version` 显示旧版本？**
A：没完全退出 MAMEUI 前端。

**Q35：`entries` 是 0？**
A：字段识别失败。看 `diag`。可能游戏还没开始。

**Q36：`menu_verify` 显示 FAIL？**
A：菜单自检发现问题。看第十二章 12.11。

**Q37：`last_error` 有内容？**
A：看错误信息。常见是 `dir not writable`。

**Q38：2P 方向乱走？**
A：v4.9.11 的极性 bug，v4.9.12 已修。升级。

**Q39：插件把文件删了？**
A：v5.0.1 之前的 `install_plugin.py` UNC bug。从 `version/` 恢复，升级。

**Q40：游戏崩溃？**
A：极罕见。关插件测试，看日志，提交 Issue。

**Q41：MAME 日志在哪？**
A：通常在 MAME 根目录的 `error.log` 或启动时控制台输出。

**Q42：怎么回滚到旧版本？**
A：从 `version/<版本>/` 复制 `init.lua` + `plugin.json` 覆盖。

### 开发与高级

**Q43：能加新功能吗？**
A：能。看第十一章"源码导读"。

**Q44：能加延迟镜像吗？**
A：需要改 `tick`，加环形缓冲。第十一章有思路。

**Q45：能只在特定游戏生效吗？**
A：改 `tick` 或 `build_entries`，检查 `emu.romname()`。

**Q46：改代码后怎么测试？**
A：`python -m mame_2p check_lua` + 完全退出 MAMEUI 前端 + 实机测试。

**Q47：为什么用 `pcall` 到处都是？**
A：防止一个错误崩掉整个 tick。代价是错误静默，所以关键处写 `last_error`。

**Q48：为什么 `settings` 里字段那么多？**
A：历史演进。`targets`/`enabled`/`target` 是旧字段（已废弃），`sources`/`src_enabled` 是新字段。加载时会迁移。

**Q49：项目为什么叫 `copilot2p`？**
A：`copilot`（副驾驶）+ `2p`（2 号玩家）。原意是"1P 的副驾驶"。

**Q50：为什么版本号从 v3.x 跳到 v4.0？**
A：v4.0 是架构重构（多路镜像 + 动作表菜单），变化太大，跳大版本。中间有备份 `version/20261107-v5-pre-v4/`。

---

<a name="附录A"></a>
## 附录 A　术语表

| 术语 | 英文 | 通俗解释 | 专业解释 |
|---|---|---|---|
| 输入字段 | Input Field | 游戏里的"一个键位" | MAME `ioport_field` 对象 |
| 输入端口 | IOPort | 一组键位的集合 | MAME `ioport_port` 对象 |
| 语义键 | Semantic Key | 上/下/左/右/按钮N | 由 `field.type` 映射的字符串 |
| 源 | Source | 谁在控制别人 | `src` 索引（0=P1..3=P4） |
| 目标 | Destination | 被控制的玩家 | `dst` 索引（1=P2..3=P4） |
| 镜像 | Mirror | 复制按键 | 读源字段 → 写目标字段 |
| 覆盖 | Override | 强行赋值 | `field:set_value(n)` |
| 清除 | Clear | 归还物理控制 | `field:clear_value()` |
| 两阶段快照 | Two-Phase Snapshot | 先读后写 | 防互控振荡 |
| OR 合成 | OR Synthesis | 任一源按下即生效 | 多源控制同一目标 |
| 动作表 | Action Table | 菜单项自带动作编号 | `actions[index]` |
| 前向声明 | Forward Declaration | 先占位再赋值 | `local f; f = function()...` |
| 遮蔽 | Shadowing | 内层变量盖住外层 | 重复 `local` 导致 |
| ROM 名 | rom_name | 游戏短名 | `emu.romname()` |
| Home 路径 | homepath | MAME 数据目录 | `manager.options.entries.homepath` |
| 原始输入 | RawInput | 从驱动层读键 | Windows 输入机制 |
| SendInput | | 注入消息队列 | Windows API，对 MAME 无效 |

---

<a name="附录B"></a>
## 附录 B　速查卡（打印贴墙版）

### 安装速查

```
1. 复制 init.lua + plugin.json 到 <MAME>\plugins\copilot2p\
2. plugin.ini 加一行：copilot2p 1
3. 完全退出 MAMEUI 前端
4. 重启，进游戏，Tab → Plugin Options → 1P联动多玩家
```

### 验证速查

```
配置目录：<homepath>\copilot2p\
状态文件：plugin_status.json
看 version 字段 → 是否为 5.0.1
看 entries 字段 → 是否 > 0
看 last_error → 是否为空
```

### 菜单操作速查

```
上下键    = 移动光标
左右键    = 改值 / 切组合
回车      = 切换 / 执行
Esc       = 退出菜单
```

### 常见问题速查

```
菜单看不到        → 检查 plugin.ini、完全退出前端
菜单没反应        → 升级到 v4.9.1+
设置不保存        → 升级到 v4.8.1+，检查目录权限
2P 不动           → 2P 进场了吗？entries > 0 吗？
版本号是旧的      → 完全退出 MAMEUI 前端
连发不生效        → 用官方 autofire，本插件不做连发
```

### 配置文件速查

```json
{
  "master": true,
  "button_count": 4,
  "sources": {
    "0": {
      "UP": { "1": true, "2": true },
      "BUTTON1": { "1": true }
    }
  },
  "src_enabled": { "0": true, "1": false, "2": false, "3": false }
}
```

`sources["0"]["UP"]["1"] = true` 意思是：**源 P1 的"上"镜像到 P2**。

---

<a name="附录C"></a>
## 附录 C　文件名与路径速查

| 文件/目录 | 位置 | 作用 |
|---|---|---|
| `init.lua` | `plugins\copilot2p\` | 核心代码 |
| `plugin.json` | `plugins\copilot2p\` | 元数据 |
| `plugin.ini` | MAME 根目录或 `plugins\` | 启用表 |
| `plugin_status.json` | `<homepath>\copilot2p\` | 运行时状态 |
| `settings_default.json` | `<homepath>\copilot2p\` | 全局模板 |
| `settings_<rom>.json` | `<homepath>\copilot2p\` | 本游戏配置 |
| `settings.json` | `<homepath>\copilot2p\` | 旧版遗留 |
| `软件升级迭代记录.md` | 项目根目录 | 完整迭代日志 |
| `version\` | 项目根目录 | 版本备份 |

**实测环境路径**：

```
项目：G:\Python_Code\mame_2p
部署：\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui\plugins\copilot2p
配置：\\Ds1821\hd\ROM 街机\MAMEUI64 Plus!\mameui\copilot2p
备份：version\20261107-v26\（v5.0.1）
```

---

<a name="法律许可"></a>
## 法律、许可与联系

### 开源许可证

本项目采用 **MIT 许可证**。

```
MIT License

Copyright (c) 永久 杜玛

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 使用边界（重要）

本项目**仅限**：

- ✅ 离线单机
- ✅ 本人所有的游戏
- ✅ 正当娱乐、学习、研究用途

本项目**禁止**：

- ❌ 在线多人游戏作弊
- ❌ 绕过反作弊系统
- ❌ 商业用途（未经书面许可）
- ❌ 侵犯 DRM

### 版权声明

© 永久 杜玛 保留所有权利。
本文档内容未经书面许可不得转载或用于商业用途。

### 技术支持

**不提供私人邮箱支持。** 所有技术支持通过公开渠道：

- **问题报告**：https://github.com/duma520/mame_2p/issues
- **项目主页**：https://github.com/duma520/mame_2p
- **作者主页**：https://github.com/duma520

**提交 Issue 前请先读第十二章和第十六章**，很多问题已有答案。

**提交 Issue 请包含**：

1. 版本号（`plugin_status.json` 的 `version`）；
2. MAME 版本；
3. 游戏 ROM 名；
4. `plugin_status.json` 完整内容；
5. MAME 日志中 `[copilot2p]` 开头的行；
6. 复现步骤；
7. 期望 vs 实际。

### 致谢

- MAME 开发团队，提供了强大的插件 API；
- 官方 `inputmacro` / `autofire` 插件，提供了技术参考；
- 所有提交 Issue、帮助测试的用户。

---

**文档结束**

> 这份文档对应 `mame_2p v1.4.0` + `copilot2p v5.0.1`。
> 如果你读到这里，说明你已经比 99% 的用户更懂这个项目了。
> 祝你玩得开心。

**—— 杜玛　2026-11-08**
