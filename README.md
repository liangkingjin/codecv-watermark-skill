# remove-codecv-watermark

去除 [CodeCV](https://codecv.top)（codecv.top）免费版导出简历 PDF 中的全页平铺图案水印，封装为可直接安装到 AI 编程工具的 Skill。

不转图片、不涂白，直接改写 PDF 内容流，因此原始文本、头像、排版和页面尺寸全部保留（文本仍可选中复制）。

## 效果

| | |
|---|---|
| 输入 | CodeCV 导出的带水印简历 PDF |
| 输出 | 无水印 PDF，页数 / 尺寸 / 可选中文本不变 |
| 处理耗时 | 秒级，纯本地运行，无需联网 |

## 一键安装（推荐）

在任意终端执行一条命令即可（需要已安装 Node.js）：

```bash
npx github:liangkingjin/codecv-watermark-skill
```

> 无需发布到 npm 注册表，npx 直接从 GitHub 仓库拉取并运行安装器。若日后发布到 npm，则可以直接 `npx remove-codecv-watermark`。

安装器会自动检测本机已安装的 AI 编程工具，把 skill 复制到对应的技能目录；一台机器上装了几个工具就装几份：

| 工具 | 安装位置 |
|---|---|
| WorkBuddy | `~/.workbuddy/skills/remove-codecv-watermark/` |
| Claude Code | `~/.claude/skills/remove-codecv-watermark/` |
| CodeBuddy Code | `~/.codebuddy/skills/remove-codecv-watermark/` |
| Cursor | `~/.cursor/skills/remove-codecv-watermark/` |

常用参数：

```bash
# 安装到所有支持的工具（而不只是已检测到的）
npx github:liangkingjin/codecv-watermark-skill --all

# 安装到自定义目录
npx github:liangkingjin/codecv-watermark-skill --dir /path/to/skills

# 覆盖已有安装（升级时用）
npx github:liangkingjin/codecv-watermark-skill --force
```

### 备选：脚本安装（无 Node.js 环境时）

macOS / Linux：

```bash
curl -fsSL https://raw.githubusercontent.com/liangkingjin/codecv-watermark-skill/main/install.sh | bash
```

Windows（PowerShell）：

```powershell
irm https://raw.githubusercontent.com/liangkingjin/codecv-watermark-skill/main/install.ps1 | iex
```

## 使用方法

### 方式一：在 AI 编程工具里对话使用（安装 skill 后）

直接说：

> 帮我去掉这份 CodeCV 简历的水印 `@简历.pdf`

Skill 会自动触发，安装依赖并执行脚本，完成后返回干净版 PDF。触发词包括「CodeCV 水印」「简历去水印」「codecv.top 水印」等。

### 方式二：命令行直接运行

```bash
# 安装依赖
pip install -r skill/remove-codecv-watermark/scripts/requirements.txt

# 指定输出文件
python skill/remove-codecv-watermark/scripts/remove_codecv_watermark.py "带水印简历.pdf" "去水印简历.pdf"

# 不指定输出时，默认生成 *.clean.pdf
python skill/remove-codecv-watermark/scripts/remove_codecv_watermark.py "带水印简历.pdf"
```

成功输出示例：

```text
Removed 2 CodeCV watermark pattern fill(s).
Wrote: 带水印简历.clean.pdf
```

## 工作原理

CodeCV 水印在每页内容流中表现为一个可识别的操作序列：

```
/Pattern CS  /Pattern cs  /P1 SCN  /P1 scn      # 将描边/填充色彩空间设为 Pattern
[可选 gs]                                      # 图形状态设置
x y w h re  f                                  # 矩形路径 + 填充，覆盖整页
```

脚本基于序列匹配删除这些指令，并从页面 `/Resources` 的 `/Pattern` 字典中移除已无引用的 Pattern。正文内容（文字、图片、矢量图形）使用普通色彩空间，不受影响。

## 参考项目

- **[py-pdf/pypdf](https://github.com/py-pdf/pypdf)** — 核心依赖，PDF 内容流解析与重写全部基于 pypdf 实现（`PdfReader` / `PdfWriter` / `ContentStream`）
- **[peakxy/remove_codecv_watermark](https://github.com/peakxy/remove_codecv_watermark)** — 本 skill 中 `scripts/remove_codecv_watermark.py` 的水印识别与移除逻辑来源，在此基础上面向 Skill 化调用做了封装（保留原始版权与署名）
- **[acmenlei/codecv](https://github.com/acmenlei/codecv)** — CodeCV 简历生成器本体，本工具处理的 PDF 水印即由该项目免费版导出产生

## 目录结构

```
codecv-watermark-skill/
├── README.md
├── LICENSE
├── package.json                                # npm 包定义（npx 入口）
├── bin/cli.js                                  # npx 安装器（自动检测工具并复制）
├── install.sh                                  # 备选安装（macOS / Linux）
├── install.ps1                                 # 备选安装（Windows）
├── skill/
│   └── remove-codecv-watermark/
│       ├── SKILL.md                           # Skill 定义与触发条件
│       └── scripts/
│           ├── remove_codecv_watermark.py     # 核心去水印脚本
│           └── requirements.txt               # 依赖：pypdf>=6.10.0
└── dist/
    └── remove-codecv-watermark.zip            # 离线分发包（可手动解压安装）
```

## 手动安装（离线）

1. 下载 `dist/remove-codecv-watermark.zip`
2. 解压，将 `remove-codecv-watermark` 目录复制到对应工具的技能目录（见上表）
3. 安装依赖：`pip install -r remove-codecv-watermark/scripts/requirements.txt`

## 注意事项

- 本工具针对 CodeCV 当前导出的 `/Pattern` 平铺水印 PDF。若 CodeCV 后续调整导出实现，脚本可能需要相应适配（脚本在移除 0 处水印时会给出排查指引）。
- 请仅用于处理自己的简历，请尊重 CodeCV 的服务条款。

## License

MIT
