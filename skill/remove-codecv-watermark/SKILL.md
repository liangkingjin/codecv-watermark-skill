---
name: remove-codecv-watermark
description: 去除 CodeCV（codecv.top）导出简历 PDF 中的平铺图案水印。当用户提到"去除/删除 CodeCV 水印"、"简历去水印"、"CodeCV 导出的 PDF 有水印"、"清理 codecv.top 水印"等场景时使用本 skill。适用于免费版 CodeCV 导出的、带平铺图案水印的 PDF 简历。
agent_created: true
---

# Remove CodeCV Watermark

## Overview

CodeCV（codecv.top）免费版导出的简历 PDF 会附带全页平铺图案水印。本 skill 通过解析 PDF 内容流（Content Stream），识别水印特有的 Pattern 色彩空间填充指令序列并将其移除，同时清理对应的 Pattern 资源，从而在不重排版面的前提下输出无水印的干净 PDF。

## How It Works

CodeCV 水印在每页内容流中表现为一个可识别的操作序列：

```
/Pattern CS  /Pattern cs  /P1 SCN  /P1 scn      # 将描边/填充色彩空间设为 Pattern
[可选 gs]                                      # 图形状态设置
x y w h re  f                                  # 矩形路径 + 填充，覆盖整页
```

脚本 `scripts/remove_codecv_watermark.py` 基于序列匹配删除这些指令，并从页面 `/Resources` 的 `/Pattern` 字典中移除已无引用的 Pattern。正文内容（文字、图片、矢量图形）使用普通色彩空间，不受影响。

## Usage

### 1. Environment Setup

脚本依赖 `pypdf >= 6.10.0`。优先使用隔离的 Python 环境安装依赖，不要污染全局环境：

```bash
python -m pip install -r scripts/requirements.txt
```

### 2. Run the Script

```bash
# 基本用法：输出为 <input>.clean.pdf
python scripts/remove_codecv_watermark.py <input.pdf>

# 指定输出路径
python scripts/remove_codecv_watermark.py <input.pdf> <output.pdf>
```

### 3. Verify the Result

- 脚本输出 `Removed N CodeCV watermark pattern fill(s).`，N 为移除的水印填充数量（通常等于 PDF 页数）。N 为 0 表示未检测到该类型水印。
- 用 `PdfReader` 或直接打开输出文件确认页数与内容完整。
- 始终基于原始 PDF 处理，不要对已清理的文件二次运行（避免叠加修改）。

## Troubleshooting

若脚本报告 `Removed 0 ...`（未匹配到水印），说明该 PDF 的水印不是本脚本针对的 Pattern 平铺类型，可能情形：

1. **文字型水印**：水印以普通文本对象绘制。用 pypdf 提取每页文本，找到重复出现的固定水印文字（如 "CodeCV"），在内容流中定位并删除对应的 `BT ... ET` 文本块。
2. **图片型水印**：水印是 `/XObject` 中的图片。检查页面 `/Resources` 的 `/XObject`，找出被以透明度（`/ExtGState` 含 `/ca < 1`）大面积绘制者，删除对应 `Do` 指令并清理资源。
3. **加密 PDF**：先尝试 `PdfReader(...).decrypt("")`，失败则需用户提供密码。

处理前先 dump 内容流分析结构（`ContentStream(page.get_contents(), pdf).operations`），确认水印的绘制方式后再动手。

## Resources

### scripts/
- `remove_codecv_watermark.py` — 核心去水印脚本（Python 3.9+，命令行接口）
- `requirements.txt` — 依赖清单（`pypdf>=6.10.0`）
