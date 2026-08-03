# eryu-skills

尔玉跨机器 Skill 入口。仓库只直接维护个人编排 Skill；第三方 Skill 通过来源清单安装，不再复制完整上游仓库。

## 安装

### Windows

```powershell
git clone https://github.com/sealofyou/eryu-skills.git "$HOME\workspace\github\eryu-skills"
cd "$HOME\workspace\github\eryu-skills"
.\install.ps1 -Profile core
```

### macOS / Linux

```bash
git clone https://github.com/sealofyou/eryu-skills.git ~/workspace/github/eryu-skills
cd ~/workspace/github/eryu-skills
bash install.sh core
```

重启 Codex 或 Agent session 后加载新 Skill。

## Profile

| Profile | 内容 |
| --- | --- |
| `core` | 尔玉分享工坊、尔玉短视频工坊、动态网页路由、滴答飞书轻量巡检、GitHub 知识库、Frontend Slides |
| `content` | 写作、思维挖掘、配图、课程、视频笔记和批量生图 |
| `slides` | gpt-image2-ppt 与 Guizang 专项路线 |
| `design` | UI/UX Pro Max |
| `tools` | Harness、ModelScope 等工程工具 |
| `media` | 剪映自动化 Skill |
| `all` | 安装以上全部 profile |

选择非 `core` profile 时会自动同时安装 core。

## 源码边界

- `skills/`：由尔玉维护、可以直接跨机器同步的轻量 Skill。
- `skills.sources.csv`：第三方或独立仓库的来源、分支和子目录。
- `install.ps1` / `install.sh`：把选定 profile 安装到 `~/.codex/skills`。
- `~/.cache/eryu-skills/repos`：外部仓库缓存，不进入 Git。

OMX、Codex 系统 Skill、飞书/Lark 插件、浏览器插件和带本机授权的连接器由各自安装器管理，不复制进本仓库。

## 更新

```bash
git pull --ff-only
```

然后重新运行对应安装命令。安装器只替换清单中由本仓库管理的目标目录，不删除其他 Skill。

## 安全

不要提交 API key、token、密码、OAuth 文件、cookie、私钥、`.env`、数据库、日志、浏览器状态和生成产物。个人 Skill 只保存读取私有上下文的规则，不保存私有正文和凭据。

审计记录见 `docs/skill-audit-2026-07-15.md`。
