# Skill 运行时审计与裁剪记录（2026-07-27）

## 结论

本次审计把 `eryu-skills` 继续收敛为“个人领域 Skill + 工具/接口 Skill”的跨机器来源。强模型可以减少通用流程提示词的必要性，但不能替代第三方 API 的调用边界、平台限制、私有工作流约束和可复用的领域模板。

线上仓库与本机 clone 的源码差异已通过 `git pull --ff-only` 收敛。线上新增的 `apple-hide-my-email` 已登记到 `tools` profile，并标记为 `macos` 平台；Windows/Linux 安装器会自动跳过它。

## 来源边界

| 来源 | 处理方式 |
| --- | --- |
| `eryu-skills/skills/` | 个人维护、跨机器同步的权威源码 |
| `skills.sources.csv` | 第三方仓库的来源、分支、子目录和平台元数据 |
| `~/.codex/skills` | 本机安装结果，不作为源码来源 |
| `~/.agents/skills` | 插件/Agent 运行时管理的 Skill，不复制进本仓库 |
| Codex `.system`、OMX、Lark、浏览器连接器 | 由各自安装器管理，不在此仓库镜像 |

## 当前本机差异

- 线上仓库直接维护的 Skill 已包含 `eryu-share-studio`、`eryu-dynamic-web-publisher`、`dida-feishu-light-sync`、`github-kb` 和新增的 `apple-hide-my-email`。
- 本机 `~/.codex/skills` 还包含 Codex/OMX 系统 Skill 及第三方 profile 安装结果；这些额外目录不是线上仓库缺失，而是不同来源的运行时层。
- 本机 `~/.agents/skills` 还包含飞书、OpenCLI 和通用流程 Skill；它们不应被误判为 `eryu-skills` 的源码差异。
- `humanizer-zh` 目前由 `.agents` 层提供；来源清单仍保留它，以便在需要时通过 `content` profile 安装。

## 对强模型的兼容性判断

### 已移入本机可恢复归档

下列 Skill 的问题是平台/流程不匹配，不是模型能力不足：

| Skill | 判断 | 原因 |
| --- | --- | --- |
| `using-superpowers` | 移除 | 要求调用当前环境不存在的 `Skill` 工具，并声称可以覆盖系统行为；会制造递归触发和优先级冲突。 |
| `writing-plans` | 移除 | 强制专用 worktree、极细的计划模板和额外执行选择，不适合当前仓库的自主维护协议。 |
| `test-driven-development` | 移除 | 对文档、清单和配置维护也强制“先写失败测试”，会把不适用的代码流程套到非代码变更上。 |
| `using-git-worktrees` | 移除 | 将 worktree 设为默认前置步骤，与本机围绕 `master` 的轻量维护方式冲突。 |
| `writing-skills` | 移除 | 依赖上述 superpowers/TDD 体系，内容过长且要求不存在的平台工具与人工确认。 |

这些 Skill 只从本机活动目录移出并保留到可恢复归档；不删除 Codex `.system`、OMX、Lark 或浏览器插件管理的目录。

### 保留但按需触发

- `systematic-debugging`、`verification-before-completion`：它们提供故障定位和证据校验，不是模型可以安全默认省略的领域约束。
- `brainstorming`、`requesting-code-review`、`receiving-code-review`、`subagent-driven-development`、`dispatching-parallel-agents`：只在任务形状确实匹配时使用，不作为每轮对话的前置门槛。
- `eryu-share-studio`、`eryu-dynamic-web-publisher`、`dida-feishu-light-sync`、`github-kb`、`frontend-slides` 及各 profile 的工具/内容 Skill：保留，因为它们承载尔玉的品牌规则、外部接口知识或稳定产出流程。

## 安装约定

1. 新机器默认安装 `core`。
2. 写作、幻灯片、设计、工具和媒体能力按需追加 profile，不默认安装 `all`。
3. 安装器只替换 `skills.sources.csv` 管理的目标目录，不删除其他来源的 Skill。
4. 修改个人 Skill 只改 `skills/<name>/`，完成结构校验和安装冒烟后再提交并推送。

## 后续复核触发条件

- 上游仓库更换工具接口、认证方式或运行平台时。
- Codex/Agent 的 Skill 加载协议发生变化时。
- 同名 Skill 在 `.codex`、`.agents`、插件缓存或项目级目录再次出现时。

