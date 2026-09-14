## Codex 同软件 CLI 路径

需要 Node.js 22+ 和支持 `exec --ignore-user-config --ephemeral --json` 的本机 Codex CLI。先检查 `codex exec --help`；不支持时不能直接套命令。

辅助脚本先在父进程读取当前 `CODEX_HOME/config.toml` 的 Responses provider，复用其 `experimental_bearer_token` 或 `env_key`；只有 provider 明确声明 `requires_openai_auth=true` 时才回退到该 Codex 认证文件的 API key。也可从既有本机配置注入成对的 `CPA_BASE_URL / CPA_API_KEY`。不修改全局配置、不复制认证文件。

子 Codex 使用本次输出目录下独立的 `runtime-profile`（仅修改子进程 HOME / APPDATA / CODEX_HOME），分开默认配置发现和运行状态；必要的用户与项目规则由主 Agent 写进任务包。**这不保证减少系统 Skill 注入或输入 token**：当前版本仍会同步并注入可见的 Skill 描述，简单文件探针累计约 5–6 万输入 token（含缓存），独立目录探针也未下降。使用者需要知道这个实际开销；不得声称已经实现上下文减负。用户仍要求同软件优先时保留该顺序，明确点名配套 CLI 时直接照做。项目 cwd 自身规则仍可能加载，任务包只放必要材料也不能消除运行时附加描述。

```text
node <skill-dir>/scripts/codex-cpa.mjs models
node <skill-dir>/scripts/codex-cpa.mjs run --model <真实ID> --cwd <绝对目录> --prompt-file <UTF-8任务包> --out-dir <本次独立输出目录> --timeout 180
```

- 默认 `--access read-only`；已授权实现任务可传 `--access workspace-write`，只在任务范围内使用，不能超出父任务权限。
- 只有用户或当前任务明确给了思考强度才传 `--effort`；不偷偷降低强度，不把某个模型的后缀当成另一个模型。
- 默认使用短暂、不持久化的 CLI 会话。每次调用给新的输出目录，防止覆盖旧证据。
- `read-only` 主要限制写入，`--cwd` 不限制全部可读范围。只需少量材料时用只含必要材料的临时工作目录；需要强读取隔离时使用已有受控沙箱，不能把工作目录当成隔离保证。
- 包装器过滤无关环境变量，命令工具不继承 API 认证环境；独立 runtime-profile 只控制默认配置与上下文发现。**它没有实现 OS 级凭据读取隔离**，同一用户权限下的进程仍可能访问已知绝对路径。只用于父任务已经授权的宿主执行场景；需要强读取隔离时使用已有 OS 级受控环境，不把换 HOME 当成安全隔离。
- 超时会终止子进程树；若终止仍失败，`terminationFailed=true` 并给出 PID。此时报告残留进程，不把它当成结束，不启动重复任务。
- Windows 上宿主配置/钥匙串在普通沙箱内不可读时，按当前平台审批机制申请这个具体调用；子 Codex 仍保留只读或工作区沙箱。审批拒绝时不能改用配套 CLI 绕过同一个限制。
- `result.json` 中的 `model` 是实际发出的请求 ID，不是已核实的上游厂商身份。CPA 可能有服务端映射，不能根据模型自述确认真实身份。
- `processCompleted=true` 仅表示 CLI 正常结束；主 Agent 还必须检查 `finalText`、`toolCalls` 和实际验收证据。`acceptanceVerified` 默认始终为 false，由主 Agent 独立判断任务是否完成。

