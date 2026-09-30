<p align="center">
  <img src="https://ormus.solutions/mascot/pixellab_liquid_to_cube.gif" alt="LibreEmbed Claude Code" width="128" style="image-rendering: pixelated;" />
</p>

<h1 align="center">LibreEmbed Claude Code</h1>

<p align="center">
  <em>借助 Claude Code 开发嵌入式系统、固件与 IoT：从裸机到 RTOS 的 15 个专业插件</em>
</p>

<p align="center">
  <a href="https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/stargazers"><img src="https://img.shields.io/github/stars/HermeticOrmus/LibreEmbed-Claude-Code?style=flat-square&color=aa8142" alt="Stars" /></a>
  <a href="https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/blob/main/LICENSE"><img src="https://img.shields.io/github/license/HermeticOrmus/LibreEmbed-Claude-Code?style=flat-square&color=aa8142" alt="License" /></a>
  <a href="https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/commits"><img src="https://img.shields.io/github/last-commit/HermeticOrmus/LibreEmbed-Claude-Code?style=flat-square&color=aa8142" alt="Last Commit" /></a>
  <img src="https://img.shields.io/badge/C-aa8142?style=flat-square&logo=c&logoColor=white" alt="C" />
  <img src="https://img.shields.io/badge/Embedded-aa8142?style=flat-square&logo=arm&logoColor=white" alt="Embedded" />
  <img src="https://img.shields.io/badge/Claude_Code-aa8142?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code" />
</p>

[English](README.md) | 简体中文

---

> **用于 Claude Code 嵌入式系统开发的技能、代理、命令与工作流。**

大多数借助 LLM 编程的模式都默认你在做 Web 开发。嵌入式开发不是 Web。工具链是 GCC + OpenOCD + 硬件调试器，运行环境是裸机或 32 KB 的 RTOS，bug 藏在你手里那颗芯片的某个寄存器里，反馈循环是“编译、烧录、看 LED、做判断”。

**LibreEmbed 就是为这类工作准备的 Claude Code 工具集。** 十五个插件，覆盖你在做板级 bring-up、编写驱动、通过 SWD 调试，或交付必须经得起现场重新烧录的固件时真正关键的各个层面。

---

## 这套工具回应的变化

Andrej Karpathy 在 2025 年 12 月这样描述更大范围的变化：

> *“作为程序员，我从未感到如此落后。这个职业正在被大幅重构。”*
>
> *“新词汇：agents、subagents、它们的 prompts、contexts、memory、modes、permissions、tools、plugins、skills、hooks、MCP、LSP、slash commands、workflows、IDE integrations……”*

嵌入式开发比大多数领域更久地抵御了这场重构。原因是真实存在的（专有工具链、硬件在环测试、安全约束、厂商锁定），但结果是嵌入式团队在采用代理辅助工作流方面落后了。LibreEmbed 的存在就是为了缩小这一差距。每个插件都把一部分嵌入式专业知识编码为代理提示词、命令和技能，这样当你想弄清楚芯片为什么无法通过 USB 枚举时，代理可以和你一起思考。

### LibreEmbed 在 Claude Code 体系中的位置

| Claude Code 组件 | LibreEmbed 提供的内容 |
|---|---|
| **插件（Plugins）** | 15 个领域插件（RTOS、ARM Cortex-M、通信总线、IoT、FPGA、安全关键等），全部从同一个名为 `libre-embed` 的插件市场安装 |
| **代理（Agents）** | 每个插件都有一个领域专家代理，例如 RTOS 工程师、ARM Cortex-M 专家、IoT 协议设计师 |
| **命令（Commands）** | 每个插件的快捷斜杠命令（`/rtos`、`/comm-bus`、`/iot`、`/cortex-m` 等） |
| **技能（Skills）** | 可复用的模式库：标定流程、传感器融合、Bootloader 模式、OTA 工作流 |
| **钩子（Hooks）** | 作为安全网的工具调用前/后钩子，打包为可选的 `libre-embed-hooks` 插件：在烧录、擦除和访问密钥类文件之前请求确认 |
| **模板（Templates）** | 一个项目级 `CLAUDE.md` 模板（`templates/CLAUDE.md`） |

---

## 包含内容

```
LibreEmbed-Claude-Code/
├── .claude-plugin/         # libre-embed 插件市场的 marketplace.json
├── plugins/                # 15 个插件（每个嵌入式子领域一个），外加 libre-embed-hooks
│   ├── arm-cortex-m        # ARM Cortex-M0/M3/M4/M7/M33 编程
│   ├── bare-metal          # 寄存器操作、链接脚本、最小运行时
│   ├── bootloader-design   # Bootloader 架构、安全启动、A/B 分区
│   ├── communication-buses # I2C、SPI、UART、CAN、USB 协议与驱动
│   ├── debug-trace         # JTAG、SWD、ITM、ETM、printf 调试、逻辑分析仪
│   ├── embedded-linux      # Yocto、Buildroot、设备树、内核模块
│   ├── embedded-testing    # 目标板单元测试、HIL 测试、硬件 mock
│   ├── firmware-update     # OTA 升级、双 bank Flash、回滚机制
│   ├── fpga-integration    # MCU+FPGA 集成、软核、HDL 基础
│   ├── iot-protocols       # MQTT、CoAP、LwM2M、BLE、LoRaWAN、Zigbee、Thread
│   ├── memory-management   # 静态分配、内存池、栈/堆分析
│   ├── power-management    # 睡眠模式、功耗预算、能量采集
│   ├── rtos-patterns       # FreeRTOS、Zephyr、任务设计、IPC、优先级反转
│   ├── safety-critical     # IEC 61508、DO-178C、MISRA C、认证模式
│   ├── sensor-integration  # 驱动 bring-up、标定、滤波、融合
│   └── libre-embed-hooks   # 可选安全钩子：烧录、擦除、访问密钥文件前先确认
├── learning-paths/         # 3 条学习路径：入门 → 进阶 → 高级
├── templates/              # 项目 CLAUDE.md 模板
└── setup.sh                # 通过 Claude Code CLI 安装插件
```

---

## 15 个插件

每个插件都包含一个**代理**（具备深厚领域知识的专家角色）、一个**命令**（快捷斜杠调用）和一个**技能**（可复用的模式库）。

### 微控制器内核

| 插件 | 代理 / 命令 | 功能 |
|---|---|---|
| **arm-cortex-m** | `cortex-m-engineer` / `/cortex-m` | CMSIS、HAL 与 LL 对比、启动代码、向量表、MPU 配置、与 Cortex-A 交界处的 MMU。覆盖 ARM Cortex-M0+/M3/M4/M7/M33。 |
| **bare-metal** | `bare-metal-engineer` / `/bare-metal` | 寄存器级编程、链接脚本、最小运行时（不依赖 libc）、嵌入式 C++、freestanding 构建。 |
| **memory-management** | `memory-engineer` / `/memory` | 静态分配策略、内存池、借助 GCC `-fstack-usage` 做栈分析、无堆设计、内存碎片模式。 |
| **power-management** | `power-engineer` / `/power` | 睡眠模式（run / sleep / stop / standby）、外设时钟门控、唤醒源、功耗预算、能量采集设计。 |

### 通信与 I/O

| 插件 | 代理 / 命令 | 功能 |
|---|---|---|
| **communication-buses** | `bus-driver-engineer` / `/comm-bus` | I2C（主/从、时钟延展、多主机）、SPI（模式、DMA、片选处理）、UART（DMA、环形缓冲区、流控）、CAN（帧格式、过滤器、错误状态）、USB CDC/HID。 |
| **sensor-integration** | `sensor-engineer` / `/sensor` | 传感器驱动 bring-up、出厂标定、Allan 方差、互补滤波与卡尔曼滤波、传感器融合（IMU + 磁力计 + GPS）。 |
| **iot-protocols** | `iot-protocol-engineer` / `/iot` | MQTT（QoS 等级、保留消息、LWT）、CoAP、LwM2M 设备管理、BLE GATT、LoRaWAN Class A/B/C、Zigbee、Thread。 |

### 运行时与系统

| 插件 | 代理 / 命令 | 功能 |
|---|---|---|
| **rtos-patterns** | `rtos-engineer` / `/rtos` | FreeRTOS 与 Zephyr 任务设计、IPC 原语（队列、互斥锁、信号量、事件组）、优先级反转与优先级继承、看门狗模式、延迟中断处理。 |
| **embedded-linux** | `embedded-linux-engineer` / `/embedded-linux` | Yocto 与 Buildroot、设备树编写、内核模块模式、init 系统（systemd、OpenRC 与 BusyBox init 的对比）、用户态驱动模式。 |
| **bootloader-design** | `bootloader-engineer` / `/bootloader` | 一级与二级 Bootloader、安全启动链、签名校验、A/B 分区设计、故障安全回滚、与 ROM Bootloader 的交互。 |
| **firmware-update** | `fota-engineer` / `/firmware-update` | OTA 升级协议、双 bank Flash、差分升级（bsdiff/Heatshrink）、版本协商、防回滚、强制厂商签名。 |

### 软硬件集成

| 插件 | 代理 / 命令 | 功能 |
|---|---|---|
| **fpga-integration** | `fpga-engineer` / `/fpga` | MCU + FPGA 设计、AXI 总线集成、软核 CPU（FPGA 上的 RISC-V）、跨越软硬件边界的 DMA、面向嵌入式开发者的 HDL 基础。 |
| **debug-trace** | `debug-engineer` / `/debug-embedded` | JTAG 与 SWD 配置、OpenOCD 与 pyOCD、ITM（Instrumentation Trace Macrocell）、ETM（Embedded Trace Macrocell）、通过 SWO 输出 printf、逻辑分析仪抓取、示波器与逻辑分析仪的取舍。 |

### 质量与合规

| 插件 | 代理 / 命令 | 功能 |
|---|---|---|
| **embedded-testing** | `embedded-test-engineer` / `/embedded-test` | 目标板上的单元测试（Unity、CMocka、Ceedling）、硬件在环（HIL）测试台、硬件外设 mock、黄金镜像回归测试、嵌入式 CI。 |
| **safety-critical** | `safety-engineer` / `/safety` | IEC 61508 SIL 等级、DO-178C 航空、ISO 26262 汽车、MISRA C 合规、形式化验证基础、免干扰（freedom from interference）。 |

### 可选安全钩子

| 插件 | 钩子 | 功能 |
|---|---|---|
| **libre-embed-hooks** | SessionStart、PreToolUse、PostToolUse | 在烧录和擦除命令（OpenOCD `program`、`st-flash write`、`west flash`、`idf.py flash`、`pyocd flash`、`nrfjprog --program` 等）之前，以及文件工具访问 `.env`、`.pem`、`.key`、credentials 或 secrets 类文件之前请求确认。会话在固件项目中打开时输出一行上下文提示，并标记编辑后变为空的文件。不含代理，不写日志。详见[它的 README](plugins/libre-embed-hooks/README.md)。 |

---

## 快速开始

### 在 Claude Code 中安装

```text
/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code
/plugin install rtos-patterns@libre-embed
```

用同样的方式安装 15 个插件中的任意一个：`/plugin install <plugin>@libre-embed`，插件名见上方表格，然后重启 Claude Code。在终端中，对应的两步是：

```bash
claude plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code
claude plugin install rtos-patterns@libre-embed
```

安全钩子是一个独立的可选插件：`/plugin install libre-embed-hooks@libre-embed`（或 `claude plugin install libre-embed-hooks@libre-embed`）。

### 在 Grok Build 中安装

Grok Build 加载的是同样的插件目录。在终端中添加插件市场并安装插件：

```bash
grok plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code
grok plugin install rtos-patterns@LibreEmbed-Claude-Code
```

也可以不经过插件市场，直接从插件目录安装单个插件：

```bash
grok plugin install HermeticOrmus/LibreEmbed-Claude-Code#plugins/rtos-patterns
```

在本地克隆中，`./setup.sh --grok` 会通过 `grok` CLI 安装全部插件；`--only`、`--list` 和 `--uninstall` 的用法不变。`libre-embed-hooks` 插件使用的钩子格式 Grok Build 支持，但尚未在真实的 Grok 会话中验证。

### 用 setup.sh 一次安装全部

```bash
# 克隆
git clone https://github.com/HermeticOrmus/LibreEmbed-Claude-Code.git ~/projects/LibreEmbed-Claude-Code

# 将全部 15 个插件及 libre-embed-hooks 安装到 Claude Code
cd ~/projects/LibreEmbed-Claude-Code
./setup.sh

# 或者只安装你需要的插件
./setup.sh --only rtos-patterns,communication-buses,iot-protocols

# 列出插件、跳过钩子插件，或卸载整个插件包
./setup.sh --list
./setup.sh --no-safety-hooks
./setup.sh --uninstall
```

`setup.sh` 需要 `claude` CLI 和 `jq`。它把本地仓库注册为 `libre-embed` 插件市场，并对每个插件执行 `claude plugin install`，因此安装的内容与上面的 `/plugin` 命令完全相同。全部十五个插件合计会给每个会话增加约 4.7k token 的插件描述（`claude plugin details <plugin>@libre-embed` 可查看每个插件的开销），所以如果你只做其中几个方向，用 `--only` 更划算。

从 0.x 升级：旧版 `setup.sh` 会把目录复制到 `~/.claude/plugins/`、把脚本复制到 `~/.claude/hooks/`，而 Claude Code 并不会从这些位置加载。用上面任一方式安装后，删除残留的 `~/.claude/plugins/libre-embed-*` 目录和 `~/.claude/hooks/libre-embed-*.sh` 脚本即可。

### 第一个提示词

然后在固件项目根目录打开任意 Claude Code 会话：

```text
/rtos 为一个传感器记录器设计任务结构：以 1 kHz 采样 4 个通道，每 100 ms 写入一次 QSPI Flash
```

如果另一个插件也定义了 `/rtos`，请使用带命名空间的形式 `/rtos-patterns:rtos`。

完整的真实开发板演练（STM32F4 Discovery + ICM-20948 IMU）见 [QUICK_START.md](QUICK_START.md)（英文）。

---

## 学习路径

仓库按经验水平组织，选择你的起点：

### 入门：*“我的第一个 Claude Code 单片机项目”*

你写过 C，也许在 Arduino 上点亮过 LED。现在你想进阶到真正的 MCU + GCC 工具链 + 硬件调试器，并让 Claude Code 帮你避开那些显而易见的坑。

→ [`learning-paths/beginner.md`](learning-paths/beginner.md)（英文）

### 进阶：*“为定制电路板做 bring-up”*

你的桌上有一份原理图和一块已贴片的 PCB。晶振频率正确，电源轨测得干净。现在你需要写出第一版确认电路板工作正常的固件。Claude Code 就是你的 bring-up 搭档。

→ [`learning-paths/intermediate.md`](learning-paths/intermediate.md)（英文）

### 高级：*“交付能在现场存活的固件”*

不会让设备变砖的 OTA 升级。能捕获真实故障的看门狗模式。固件的 CI/CD。长期支持模式。正是这些工作让固件具备量产可信度。

→ [`learning-paths/advanced.md`](learning-paths/advanced.md)（英文）

---

## 兼容性

- **Claude Code**：支持插件市场（`/plugin`）的版本；本次发布已在 Claude Code 2.1.285 上验证。`setup.sh` 和钩子插件还需要 `jq`。
- **Grok Build**：`grok` 1.0.44 可以校验并安装全部 16 个插件。钩子插件尚未在真实的 Grok 会话中验证。
- **工具链**：GCC ARM（任何较新版本）、带嵌入式目标的 Clang/LLVM、Zephyr SDK、ESP-IDF、STM32CubeIDE、Microchip XC32、Renesas e² studio
- **覆盖的 MCU 系列**：ARM Cortex-M0/M0+/M3/M4/M7/M33（STM32、NXP LPC + Kinetis + i.MX RT、Nordic nRF、Microchip SAM、RP2040、ESP32、Renesas RA），MSP430（少量），AVR（少量）
- **RTOS 覆盖**：FreeRTOS（深入）、Zephyr（深入）、ThreadX（中等）、RT-Thread（少量）
- **构建系统**：Make、CMake、PlatformIO、Zephyr west、ESP-IDF idf.py
- **调试器**：SEGGER J-Link（推荐）、ST-Link、CMSIS-DAP、Black Magic Probe、JLink-OB
- **操作系统**：开发主机使用 Linux / macOS（Windows 也能用，推荐 WSL2）

LibreEmbed 不会回传任何数据，除了工具链本身需要的账号之外，不要求任何厂商账号。

---

## 反馈

觉得有用并点了 Star？告诉我们哪些好用、还缺什么：[提交反馈 issue](https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/issues/new?template=feedback.yml)。每一条反馈都会得到回复，由反馈带来的改动会在发布说明中致谢。

我们发现并修补过的裂痕：[LEDGER.md](LEDGER.md)（英文）。

---

## 贡献入口

- 从 [Menu（任务菜单）](pantry/MENU.md) 领取下一项工作，或者从 [good first issue](https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/contribute) 开始。
- Claude 选错了代理或技能？提交一份 [路由错误报告（routing miss）](https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/issues/new?template=routing-miss.yml)。
- 想到了新插件？提交 [插件提案](https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/issues/new?template=plugin-proposal.yml)。其他意见请用 [反馈表单](https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/issues/new?template=feedback.yml)。
- 在 [Discussions](https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/discussions) 展示你的开发板和固件。

如何认领任务、如何在本地测试改动：见 [Ways to contribute](CONTRIBUTING.md#ways-to-contribute)（英文）。

---

## 参与贡献

嵌入式领域很广。十五个插件只是起点，各插件的深度不一（每个插件的成熟度矩阵见 [CHANGELOG.md](CHANGELOG.md)）。特别欢迎以下方面的 PR：

- **RTOS**：FreeRTOS 和 Zephyr 以外的 RTOS（ThreadX、RT-Thread、NuttX、ChibiOS 的更深入覆盖）
- **厂商 HAL**（目前以 CMSIS 为主；各厂商的 HAL 约定需要各自的插件或子插件）
- **地区性认证**（中国 CCC、韩国 KC 等）：safety-critical 插件目前以欧美认证为主
- **工具链支持**（Microchip XC32、Renesas e²、IAR、Keil；目前以 GCC 为主）
- **基于真实硬件的完整示例**：真实开发板演示越多，这套工具就越可信

贡献方式见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## Libre 开源 Claude Code 工具家族

本仓库属于一个不断壮大的 Claude Code 开源工具家族。

### Libre 套件：完整的插件包

- [LibreUIUX-Claude-Code](https://github.com/HermeticOrmus/LibreUIUX-Claude-Code)：UI/UX 开发（152 个代理、70 个插件、76 个命令、74 个技能）
- [LibreArch-Claude-Code](https://github.com/HermeticOrmus/LibreArch-Claude-Code)：软件架构与系统设计
- [LibreCopy-Claude-Code](https://github.com/HermeticOrmus/LibreCopy-Claude-Code)：技术写作与文档工程
- [LibreDevOps-Claude-Code](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code)：DevOps 工程与基础设施自动化
- [LibreFinTech-Claude-Code](https://github.com/HermeticOrmus/LibreFinTech-Claude-Code)：金融科技开发
- [LibreGEO-Claude-Code](https://github.com/HermeticOrmus/LibreGEO-Claude-Code)：AI 搜索优化（ChatGPT、Perplexity、Gemini、Google AI Overviews）
- [LibreGameDev-Claude-Code](https://github.com/HermeticOrmus/LibreGameDev-Claude-Code)：横跨 Godot、Unity、Unreal 的游戏开发
- [LibreMLOps-Claude-Code](https://github.com/HermeticOrmus/LibreMLOps-Claude-Code)：机器学习工程与 AI 运维
- [LibreMobileDev-Claude-Code](https://github.com/HermeticOrmus/LibreMobileDev-Claude-Code)：移动应用开发（Flutter、React Native、原生 iOS、原生 Android）
- [LibreSecOps-Claude-Code](https://github.com/HermeticOrmus/LibreSecOps-Claude-Code)：安全运营
- [LibreSessionFlow-Claude-Code](https://github.com/HermeticOrmus/LibreSessionFlow-Claude-Code)：会话生命周期：handoff、pickup、absorb、explore、close

### Skills 迷你仓库：单文件 CLAUDE.md 即放即用

- [vibe-engineer-skills](https://github.com/HermeticOrmus/vibe-engineer-skills)：用好 AI 代码生成：先有假设再求助、限定范围的提示词、先验证再采纳
- [markdown-discipline-skills](https://github.com/HermeticOrmus/markdown-discipline-skills)：清除 Markdown 中的 AI 套话（不用破折号，不写营销腔）
- [shell-safety-skills](https://github.com/HermeticOrmus/shell-safety-skills)：`set -euo pipefail` 规范，外加 15 个故障模式示例
- [commit-standard-skills](https://github.com/HermeticOrmus/commit-standard-skills)：Ormus 提交规范 v1.0，附 commit-msg 钩子与 commitlint
- [unwoke-skills](https://github.com/HermeticOrmus/unwoke-skills)：去掉 AI 表演腔（需要消除的十宗罪，对称式交流）
- [python-conventions-skills](https://github.com/HermeticOrmus/python-conventions-skills)：现代 Python 3.11+（类型、pathlib、async、ruff、mypy、uv）
- [typescript-conventions-skills](https://github.com/HermeticOrmus/typescript-conventions-skills)：TypeScript 严格模式、可辨识联合、Result 类型
- [hermetic-laws-skills](https://github.com/HermeticOrmus/hermetic-laws-skills)：将赫尔墨斯七大原则应用于工程
- [riper-workflow-skills](https://github.com/HermeticOrmus/riper-workflow-skills)：研究 / 创新 / 规划 / 执行 / 评审的系统化开发
- [six-day-cycle-skills](https://github.com/HermeticOrmus/six-day-cycle-skills)：带强制休息的可持续交付节奏
- [token-optimization-skills](https://github.com/HermeticOrmus/token-optimization-skills)：Claude Code 的 token 与上下文优化
- [osint-skills](https://github.com/HermeticOrmus/osint-skills)：OSINT 调研方法论（多轮递进的调查螺旋）
- [calcinate-skills](https://github.com/HermeticOrmus/calcinate-skills)：Magnum Opus 第一阶段（烧掉项目冗余）
- [claude-md-overhaul-skills](https://github.com/HermeticOrmus/claude-md-overhaul-skills)：对照上限审计 CLAUDE.md 与 MEMORY.md
- [session-handoff-skills](https://github.com/HermeticOrmus/session-handoff-skills)：会话交接与接续规范
- [naming-skills](https://github.com/HermeticOrmus/naming-skills)：产品命名方法论（从品牌自身的词汇中挖掘）
- [magnum-opus-skills](https://github.com/HermeticOrmus/magnum-opus-skills)：将七阶段炼金术应用于项目改造
- [mem-search-skills](https://github.com/HermeticOrmus/mem-search-skills)：检索 claude-mem 跨会话记忆：搜索、过滤、获取
- [hypothesis-debugging-skills](https://github.com/HermeticOrmus/hypothesis-debugging-skills)：假设驱动的调试：复现、隔离、验证、修复
- [vibe-proof-skills](https://github.com/HermeticOrmus/vibe-proof-skills)：为 vibe coding 写出的全栈应用做安全加固
- [tdd-skills](https://github.com/HermeticOrmus/tdd-skills)：面向 JS/TS 与 Python 的测试驱动开发（红-绿-重构）
- [mars-skills](https://github.com/HermeticOrmus/mars-skills)：生产就绪审计：vibe coding MVP 的五宗致命罪
- [git-workflow-skills](https://github.com/HermeticOrmus/git-workflow-skills)：整洁的 git 工作流：分支、原子提交、便于评审的 PR
- [code-review-skills](https://github.com/HermeticOrmus/code-review-skills)：领域感知的代码评审：先给代码分类，再聚焦重点
- [code-comprehension-skills](https://github.com/HermeticOrmus/code-comprehension-skills)：快速读懂陌生代码库
- [dx-audit-skills](https://github.com/HermeticOrmus/dx-audit-skills)：审计开发者体验：文档、上手流程、工具摩擦
- [setup-env-skills](https://github.com/HermeticOrmus/setup-env-skills)：搭建项目的开发环境
- [automate-skills](https://github.com/HermeticOrmus/automate-skills)：把重复性任务变成可靠的自动化脚本
- [quick-fix-skills](https://github.com/HermeticOrmus/quick-fix-skills)：常见问题的快速排查
- [prime-context-skills](https://github.com/HermeticOrmus/prime-context-skills)：在会话开始时预载项目上下文
- [auto-docs-skills](https://github.com/HermeticOrmus/auto-docs-skills)：生成并维护项目文档
- [learning-skills](https://github.com/HermeticOrmus/learning-skills)：学习任何技术：路线图、讲解、练习、速查表、对比
- [linux-sysadmin-skills](https://github.com/HermeticOrmus/linux-sysadmin-skills)：Linux 系统管理：安全、性能、诊断、监控、维护

### 模板来源

- [andrej-karpathy-skills](https://github.com/HermeticOrmus/andrej-karpathy-skills)：经典的单文件 CLAUDE.md 模式（fork 自 jiayuan_jy 的原作）

为整个家族点 Star，而不只是其中一个：整套工具正是这样保持一致的。
