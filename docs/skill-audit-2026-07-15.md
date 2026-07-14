# Skill 审计记录（2026-07-15）

## 结论

本机 Skill 的主要问题不是缺少能力，而是来源混合：系统、OMX、飞书插件、第三方仓库和个人 Skill 同时复制到多个目录，导致重复触发、版本漂移和跨机器安装困难。

新的边界：

- 个人编排 Skill 直接维护在 `eryu-skills/skills/`。
- 第三方 Skill 只在 `skills.sources.csv` 记录来源、分支和子目录。
- 系统、OMX、飞书插件和连接器由各自安装器管理。
- 本机运行目录是安装结果，不再作为唯一源码。

## 本机重复项

`~/.codex/skills` 与 `~/.agents/skills` 同时存在 16 个同名 Skill，其中 8 个内容完全相同，8 个存在版本差异。保留较新的 `.agents` 版本，并把 `.codex` 重复副本移到可恢复归档，可以直接减少 Skill 元数据重复。

重复名单：

- brainstorming
- daily-task-hub
- dispatching-parallel-agents
- executing-plans
- feishu-workspace
- finishing-a-development-branch
- receiving-code-review
- requesting-code-review
- subagent-driven-development
- systematic-debugging
- test-driven-development
- using-git-worktrees
- using-superpowers
- verification-before-completion
- writing-plans
- writing-skills

## 需要修复

- `dida-feishu-light-sync` 缺少 YAML frontmatter，名称被解析成 `{}`，无法稳定触发。已重写为跨机器版本。
- `github-kb` 固定依赖 `E:\workspace\github`，Mac 和笔记本不可直接使用。已改为环境变量、`eryuOS` 映射和机器默认路径的渐进解析。
- `eryu-dynamic-web-publisher` 把 Guizang 设为普通 deck 默认路线，与 2026-07-15 视觉选择不一致。已改为路由到 `eryu-share-studio`。

## 从仓库移除的镜像

以下内容仍可使用，但不再复制进 `eryu-skills`：

- `gpt-image2-ppt-skills`：使用独立上游仓库。
- `guizang-ppt-skill`：使用上游仓库。
- `lark-shared`、`lark-slides`：由飞书插件或 CLI 安装链管理。
- `ui-ux-pro-max`：使用上游仓库子目录。
- `modelscope-deploy`、`project-harness-bootstrap`、批量生图 Skill：使用各自独立仓库。
- `skill-creator`：使用 Codex 系统版本。

## 删除候选

- `cleanup-ws`：硬编码 Claude 目录和 Windows 路径，描述中的“cleanup/清理”触发过宽，且本机未安装。移除。
- `uv-project-env`：对所有 Python 项目自动触发，容易覆盖项目已有环境约定，本机未安装。移除。

## 保留但不进入本仓库

- OMX 工作流：由 oh-my-codex 更新。
- Codex `.system` Skill：由 Codex 更新。
- 飞书/Lark 全套 Skill：由插件更新。
- Get笔记、浏览器、OpenCLI 等连接器：每台机器单独授权。
- `jianying-editor` 等大型专项 Skill：通过 profile 按需安装，不默认加载。

## 预期收益

- 默认跨机器安装只加载核心分享、网页路由、任务巡检和 GitHub 管理能力。
- 删除重复根目录后，Skill 列表减少 16 个重复入口。
- `eryu-skills` 工作树从多个大型上游镜像收敛为轻量个人规则和安装清单。
- 第三方更新不再依赖手工复制，重新运行安装脚本即可拉取对应分支最新版本。
