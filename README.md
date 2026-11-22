# OptiScaler F5（v0.1.39）简体中文汉化资产移植说明

> 上游：`janblade/OptiScaler-F5-DLSSNR-Multipass` tag **v0.1.39**（commit `956bb71`，NR_RELEASE 0.1.39）
> 参照基线：`Owiilnice/OptiScaler-dlssnr-F5-ZH` v0.1.37.2 汉化包（基线同步到 release/0.1.38 @ `20dccfaa`）
> 本包只含**汉化资产、脚本与云端编译配置**，不含上游源码，也不含编译后的 `OptiScaler.dll`。

---

## 一、37.2 汉化包的汉化机制（本次移植学习到的方法）

这套汉化**不是替换 DLL 二进制，也没有外置语言文件**，而是「上游源码 + 汉化资产重放 + Windows MSBuild 编译」：

| 资产 | 文件 | 作用 | 上游更新后 |
| --- | --- | --- | --- |
| 英译中词典 | `dict/strings.json` | 锚点是**英文原文**（不是行号/地址），命中即替换 C 字符串字面量 | 不动，跨版本复用 |
| 上下文例外 | `dict/overrides.json` | 按文件 + 行上下文分派的例外译法 | 不动 |
| 结构规则 | `dict/structural.json` | 以原文片段为锚点，插入/替换代码块（中文字体表 include、CJK 字体回退块、vcxproj UTF-8 与字体拷贝、仓库 URL） | 锚点失效时报错，人工改锚点 |
| 作用范围 | `dict/targets.json` | 只改 `menu/`、`dlssnr/`、`shaders/dlssnr/` 下的源码，防止误译 ini 键名、DLL 名、日志串 | 不动 |
| 外置覆盖 | `overlay/` | 中文字体 `wqy-microhei.ttc`、CJK 字形范围表 `ChineseGlyphRanges.h` | 不动 |

重放器 `scripts/apply_patch.py` 三步，全部幂等（重复跑不会二次替换）：

1. **结构规则** —— 原文片段锚点替换成汉化版代码；
2. **字面量改写** —— C 字符串扫描器切出字面量组（相邻 `"a" "b"` 合成一个逻辑串），拿逻辑串查词典；
3. **覆盖文件** —— 把 `overlay/` 拷进源码树。

锚点未命中 = 报错退出（exit 2），不静默跳过，避免发出半汉化包。

### 中文字体是怎么生效的

编译进 DLL 的 Hack / Inter 字体只有拉丁字形。补丁在 `menu_common.cpp` 注入字体回退链，运行时按顺序找：

1. ini 里的 `TTFFontPath`
2. `font\wqy-microhei.ttc`（DLL / exe 旁）
3. `wqy-microhei.ttc`（DLL / exe 旁）
4. `font\wqy-microhei.ttc`（工作目录）
5. `C:\Windows\Fonts\msyh.ttc`（微软雅黑）
6. `msyh.ttf` → `simhei.ttf` → `Deng.ttf` → `simsun.ttc`

都找不到才回退拉丁字体，中文显示为方块。

---

## 二、本次对 v0.1.39 已完成的工作（沙箱预检 / 重放层面）

在 Linux 沙箱拉取 v0.1.39 源码，套用 37.2 汉化资产并复核：

| 项目 | 结果 |
| --- | --- |
| 目标源码文件 | 137 个 |
| 结构规则 | 7 条全部命中，0 失败 |
| overlay 覆盖 | 3 个文件 |
| 词典命中 | 1971 条；未命中 307 条（上游已删除/改写的旧串，属正常闲置条目） |
| 39 新增待译串 | 75 条 → **70 条补译入词典**，3 条与现有词条重复，2 条版本诊断行按规则保留英文 |
| 复扫剩余待译 | **0 条** |
| 占位符 / `##` 控件后缀 / 花括号校验 | 0 处不一致 |
| 正式重放 | 菜单 / NR 文本已写入中文，字形范围表已更新，无二次替换 |

补译脚本：`tools/fill_zh39.py`（按 `pending.json` 索引落盘，可重复执行）。

### 刻意保留英文的 2 条（`dict/untranslated.json`）

- `In use: %s (nvngx_dlssg %u.%u.%u)` —— 运行时名称 + 版本号诊断行
- `In use: %s` —— 运行时名称诊断行

保留英文是为了便于对照 `OptiScaler.log` 和网上排错资料，与上游汉化规则一致。

---

## 三、为什么不能在本会话直接产出 DLL

- 工程是 **MSVC + Windows SDK + 10 个 git 子模块**（FidelityFX-SDK、nvapi、magic_enum、simpleini、spdlog、vulkan、freetype、nlohmann、nvngx_dlss_sdk 等），Linux 沙箱无法编译 x64 Windows DLL；当前会话也没有开通可操作的 Windows 云桌面。
- **37.2 的汉化 DLL 不能直接覆盖到 39 包**：它按 37.2 代码编译，缺少 39 新增功能的代码路径，覆盖后会崩溃或功能缺失/灰显。
- DLL 只能在 **Windows（VS2022 / Build Tools）** 环境，或 **GitHub Actions 的 windows-latest runner** 上产出。

---

## 四、出包路径 A：GitHub Actions 云端编译（推荐，本机不装 VS）

汉化仓库原本就有这条流水线，本包已附锁定到 v0.1.39 的工作流。

### 步骤

1. 浏览器登录 GitHub， fork 汉化仓库 `Owiilnice/OptiScaler-dlssnr-F5-ZH`（或新建一个空仓库）。
2. 把本包内容按目录拷进 fork 仓库根：
   - `dict/`、`overlay/`、`scripts/`、`tools/` 原样；
   - `workflows/localize.yml` 放到仓库的 `.github/workflows/localize.yml`。
3. 工作流里 `UPSTREAM_BRANCH` 已锁定 `release/0.1.39`（见 `workflows/localize.yml` 第 48 行）；如上游发了更新版，改这里或留空走 auto 解析。
4. 仓库 **Actions** 页面 → 选「汉化同步与发布」→ **Run workflow**。流水线自动：
   - `sync`：取 v0.1.39 源码 → 预检锚点 → 扫描新串（本包词典已覆盖，无需 `DEEPSEEK_API_KEY` 补译）；
   - `build`：windows-latest 上 MSBuild 编译，并从上游 39 官方 zip 提取 F5Low 帧生成器 5 个文件；
   - `release`：打包 `OptiScaler-ZH-v0.1.39.7z` 发 Release。
5. 从 Release 下载 7z 即可。

> 若 fork 的是原汉化仓库，它的 `dict/strings.json` 是 37.2/0.1.38 基线，记得用本包 `dict/` 整体覆盖，带上 39 的 70 条补译。

## 五、出包路径 B：云 Windows / 本地 Windows 编译

适用：你有一台 Windows 云主机、云电脑，或本机装了 VS2022。

### 前置

- Git、Python 3；
- Visual Studio 2022 或 Build Tools，含「使用 C++ 的桌面开发」、MSVC、Windows SDK、ATL。

### 步骤

```bat
:: 1. 拉上游 39 源码（含子模块）
git clone --recurse-submodules -b v0.1.39 ^
  https://github.com/janblade/OptiScaler-F5-DLSSNR-Multipass.git
cd OptiScaler-F5-DLSSNR-Multipass

:: 2. 把本包 dict\ overlay\ scripts\ 拷进仓库根目录

:: 3. 一键重放汉化 + 编译 + 打包（第三参数给 39 官方 zip，提取 F5Low）
..\OptiScaler-ZH-assets-v0.1.39\build-windows.bat . dist\ZH "C:\path\v0.1.39-Optiscaler-F5.zip"
```

`build-windows.bat` 内部先跑 `apply_patch.py` 重放，再调 `scripts\build.ps1` 做 MSBuild 编译、剔除 PDB/LIB/EXP/ILK、补根目录文档、生成 `SHA256SUMS.txt`，并从官方 zip 提取 `plugins\f5low.dll`、`libxess_fg.dll` 等 5 个文件。

不传第三个参数也能编译，只是产物不含 F5Low 帧生成器。

### 手动分步（不用 bat 时）

```bat
python scripts\apply_patch.py . --report apply-report.json
python scripts\scan_strings.py . --out pending.json
msbuild OptiScaler.sln /m /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
```

编译产物在 `x64\Release\a\`。再从 `v0.1.39-Optiscaler-F5.zip` 拷回不参与编译的二进制：

- `OptiScaler\plugins\f5low.dll`
- `OptiScaler\libxess_fg.dll`、`libxess.dll`、`libxell.dll`、`libxess_dx11.dll`
- `OptiScaler\amd_fidelityfx_*`（dx12 / vk 各文件）
- `OptiScaler\streamline\*`（sl.interposer / sl.common / sl.dlss_g / sl.reflex / sl.pcl / nvngx_dlssg）
- `OptiScaler\D3D12_OptiScaler\D3D12Core.dll`
- `OptiScaler\LUTs\*.cube`
- `overlay\font\wqy-microhei.ttc` → 产物 `font\wqy-microhei.ttc`

### 安装

全部文件解压到游戏 exe 旁；自备神经渲染模型 `nvngx_dlssnr.dll`（按显卡选兼容版，不在发布包内）；进游戏按 `Insert` 开菜单。

---

## 六、目录与文件对照

```
OptiScaler-ZH-assets-v0.1.39/
├── README-ZH39.md                  本说明
├── build-windows.bat               Windows / 云 Windows 一键重放 + 编译 + 打包
├── dict/
│   ├── strings.json                主词典 en -> zh（2348 条，含 39 补译 70 条）
│   ├── overrides.json              按文件 + 上下文分派的例外
│   ├── structural.json              7 条代码/构建配置结构规则
│   ├── targets.json                字面量改写作用范围（menu/ dlssnr/ shaders/dlssnr/）
│   ├── glossary.json               术语表 + 文风要求（喂翻译模型用）
│   ├── accepted_diffs.json          与参考汉化版已接受的差异（verify 用）
│   └── untranslated.json           判定保持英文的串（15 条，附理由）
├── overlay/
│   ├── OptiScaler/menu/font/ChineseGlyphRanges.h   CJK 字形范围表
│   ├── font/wqy-microhei.ttc       文泉驿微米黑（外置中文字体）
│   └── font/README.txt             字体回退链说明
├── workflows/
│   └── localize.yml                GitHub Actions 工作流（已锁 release/0.1.39）
├── scripts/
│   ├── apply_patch.py              汉化重放器（结构 + 字面量 + 覆盖）
│   ├── scan_strings.py             扫描未翻译界面串
│   ├── translate.py                调模型补译（需 DEEPSEEK_API_KEY，本次未用）
│   ├── verify.py                   与参考汉化版对账
│   ├── sync_upstream.sh            同步上游源码（保留汉化资产）
│   └── build.ps1                   MSBuild 编译 + 产物自检打包
└── tools/
    └── fill_zh39.py                本次 39 新增串补译落盘脚本
```

---

## 七、故障对照

| 现象 | 排查 |
| --- | --- |
| 中文显示方块/缺字 | 产物 `font\wqy-microhei.ttc` 缺失；或 `TTFFontPath` 指向无中文字体；检查字体回退链是否命中系统雅黑/黑体 |
| 重放报「结构锚点未命中」exit 2 | 上游改过补丁动过的代码；按 `apply-report.json` / precheck 日志的 rule id 改 `dict/structural.json` 锚点 |
| 编译缺头文件 / 子模块为空 | 子模块没拉全：`git submodule update --init --recursive --depth 1`，或用 `SYNC_SUBMODULES=1 bash scripts/sync_upstream.sh <repo> release/0.1.39` |
| 菜单某段仍是英文 | `scan_strings.py` 扫出的新串未入词典；补进 `strings.json`，或确属诊断/版本行则加入 `untranslated.json` |
| 编译出的包没有 F5Low 帧生成器 | 未传 `-F5LowSourceZip`；从上游 39 官方 zip 提取 `plugins\f5low.dll` 与 `libxess_fg.dll` |
| Actions 构建在 sync 步报锚点未命中 | 上游 39 之后又改了结构代码；按 precheck 日志 rule id 修 `dict/structural.json`，再重跑 |

---

## 八、注意事项

- 神经渲染模型 `nvngx_dlssnr.dll` 受 NVIDIA 授权限制，不在任何发布包内，需自备并按显卡架构选兼容版（RTX 20/30/40 用 ShortFuse 兼容版，RTX 50 用原版）。
- 本汉化只改界面文字，不改任何设置项、默认值与渲染路径。
- 仅限单机使用；不要在带反作弊的联机游戏中注入。
- NFS Heat（DX11、无原生超分/帧生成）在各 NR/FG 项目官方兼容列表中均无专门条目，相关表现属实测性质。
