# GitHub 根目录解析

## 推荐环境变量

```text
ERYU_GITHUB_ROOT
```

示例：

- Windows 主台式：`E:\workspace\github`
- Mac：`/Users/eryu/workspace/github`
- Windows 笔记本：由本机路径映射确认，不预设盘符

## 判定

一个有效根目录通常满足至少一项：

- 存在 `CLAUDE.md` 或其他仓库总索引。
- 包含多个带 `.git` 的子目录。
- 是用户当轮明确提供的路径。

如果候选路径不存在，先创建父级工作区前确认机器角色和目标位置。不要因为主台式使用 E 盘就在其他机器创建同名盘符结构。
