---
name: github-kb
description: 当用户提到 GitHub、仓库、repo、克隆项目、查找本地代码库、查看 issue 或 PR，或需要维护跨机器 GitHub 仓库索引时使用。
---

# GitHub 知识库

## 定位仓库根目录

按顺序使用：

1. 环境变量 `ERYU_GITHUB_ROOT`。
2. `eryuOS` 本机路径映射中记录的 GitHub 根目录。
3. `$HOME/workspace/github`。
4. Windows 主台式兼容路径 `E:\workspace\github`。

找到后读取根目录的 `CLAUDE.md` 或仓库索引。不要把某台机器的绝对路径写成跨机器固定事实。

详细规则见 `references/path-resolution.md`。

## 工作流

1. 先查本地索引和目录，避免重复 clone。
2. 本地已有仓库时，读取其 README、AGENTS 和 Git 状态后再操作。
3. 本地没有时，使用 `gh repo view` 或 `gh search repos` 确认真实仓库。
4. 用户明确要求下载时，clone 到当前机器的 GitHub 根目录。
5. clone 成功后更新根目录索引，写一行用途摘要和相对链接。
6. issue、PR、release 和仓库元数据优先使用 `gh` CLI 查询。

## 安全边界

- 不把 GitHub token、SSH 私钥、cookie 和私有仓库内容复制进公开 Skill 仓库。
- 不在未确认目标目录时 clone 到 `eryuOS` 内。
- 不假设 Mac、笔记本和主台式使用同一个盘符。
- 不自动删除或移动仓库；清理候选先列清单和依据。
