---
name: eryu-task-writeback
description: 当 Codex 开始、继续、分阶段推进、暂停、等待用户、交付或完成真实任务时，必须使用本 Skill 将状态写回尔玉唯一的飞书 Base 任务行；也用于半小时补漏、跨机器任务接力、用户说“这个做完了/暂停”、执行状态残留、独立新任务未入账或怀疑重复建行。即使用户没有说“同步飞书”，只要工作会产生交付物、跨步骤推进或稍后继续，也应触发。一次性问答和没有行动承诺的讨论不触发。
compatibility: Requires lark-cli for Feishu Base writes. Cross-machine reconciliation requires a local Codex heartbeat on each machine.
---

# 尔玉任务状态回写

## 目的

飞书 Base 是唯一任务事实源。Codex task、session、SSH 命令和聊天记录只是执行证据。

使用本 Skill 后，用户不需要记字段，也不需要补一句“并同步飞书”。执行者负责把任务开始、阶段、等待、暂停、交付和完成写回同一行，并在完成时清理执行状态。

## 先读取私有合同

1. 用 `ERYUOS_ROOT` 定位 eryuOS；未设置时只允许从当前目录向上查找，不猜另一台机器路径。
2. 读取：
   - `08_任务与节奏/自动化中枢/提示词/AI任务状态回写.md`
   - `08_任务与节奏/TSK-20260904-001_三机Codex任务状态回写Skill与本机补漏.md`
3. 读取本机 ignored 配置：
   - Windows：`%USERPROFILE%\.config\eryu-task-writeback\config.json`
   - macOS / Linux：`~/.config/eryu-task-writeback/config.json`
4. 缺少私有合同或本机配置时，不猜 Base token、table id、机器名或路径。继续完成不依赖写回的工作，并明确留下待补项。

可用 `scripts/validate_config.py` 做脱敏检查。它只输出字段是否有效，不打印 Base token 或 table id。

## 任务身份

按以下顺序匹配：

1. 任务上下文已有 Base `record_id`：直接读取并更新该行。
2. Base `执行入口` 已含当前 Codex task id：更新该行。
3. 没有 ID 时，按目标、项目目录、交付物和未完成状态匹配。
4. 多个候选都合理时不覆盖；写 `状态待核对` 或只问一个最小问题。
5. 确认目标或交付物独立时才新建任务。

同一 task id 不必永远对应同一 Base 行。判断依据是目标和交付物：

- 同一版本复测、同一交付物修订、补充解释：继续同一行。
- 新模型版本有独立假设、数据、门禁、结果和复盘：新建一行并写父任务。
- 原任务已完成，新工作有新的完成定义：新建一行。

不要按 session 数量重复建任务，也不要为了避免建新行而把已完成任务永久重开。

## 证据等级

只写已经发生的事实：

- task 已创建或 `active`：只能证明执行入口已建立。
- 命令、训练或构建进程已启动：需要进程、日志或工具返回证据。
- 阶段完成：需要产物、测试、指标或明确工具结果。
- 完成：需要完成定义全部满足，或用户明确确认完成。

“准备执行”“任务 active”“模型训练成功”“业务可发布”是不同状态，不能混写。

## 生命周期动作

详细字段矩阵见 `references/writeback-contract.md`。

### 开始

写入：

- `执行状态=执行中`
- 当前已确认的起点
- 当前真正的下一步
- `codex | machine | cwd | task id`

没有安排日期时再把主状态设为“今天”。不要改写用户已有优先级或截止时间。

### 阶段进展

只更新有新证据的 `当前进展 / 下一步动作 / 执行入口`。保持两三句话，不复制日志或聊天全文。

### 等待用户

设置 `执行状态=等我`，在下一步动作中只放一个可回答的问题。不要把仍可继续的本地检查提前退给用户。

### 待验收

只用于页面体验、文案、业务取舍等主观判断。写清打开哪里、做什么、通过表现和失败表现。

### 暂停

同轮写入：

- `状态=暂缓`
- `执行状态=已暂停`
- 暂停原因
- 恢复条件
- 用户明确的新日期；没有明确日期不脑补

### 完成

完成必须成组写入：

- `状态=已完成`
- `执行状态=null`
- `完成时间`
- 最终验证证据
- `下一步动作=已完成；不再处理。` 或明确的独立后续任务
- 有价值时写 `复盘一句话`

只把主状态改成“已完成”不算完成回写。执行状态残留会让卡片继续出现在 AI 执行看板。

## 写入步骤

1. 先用当前机器的 `lark-cli` user 身份读取目标记录和真实字段。
   - 本机配置存在 `profile` 时，每条命令显式传 `--profile <name>`。
   - 普通任务回写子进程先清除 `HERMES_HOME / OPENCLAW_HOME / LARK_CHANNEL`，避免误进 Hermes 隔离配置空间。
2. 更新前保留未要求修改的字段；不要整行覆盖。
3. 使用 `base +record-upsert --record-id` 更新已知记录。
4. 只有确认新任务时，不带 `--record-id` 创建。
5. 写后用 `base +record-get` 投影目标字段回读。
6. 完成或暂停后，必要时回读 AI 执行视图，确认卡片出现或消失符合预期。

Windows 上调用依赖用户钥匙串的 `lark-cli` 时，遵守当前项目的沙箱外首调用规则。不要把普通沙箱中的 `no_token` 当成真实授权状态。

## 跨机器规则

每台机器只判断本机 Codex task：

- laptop-win 只补 laptop-win。
- main-win 只补 main-win。
- macbook 只补 macbook。

SSH 可用于安装 Skill、读取脱敏状态和验证路径，但不能证明远端 Codex task 已完成。远端任务应优先自写；漏写由远端本机 Heartbeat 补。

创建跨机任务时，把下面信息写入远端任务 prompt：

```text
Base record_id: <record_id>
Machine: <machine-id>
Working directory: <absolute-path>
Task goal: <single goal>
Completion definition: <verifiable result>

开始、阶段变化、等我、待验收、暂停和完成时，使用 eryu-task-writeback 更新同一 Base 行。
完成时必须清空执行状态并补完成时间。
```

任务先启动、后匹配到 Base 行时，立即把 `record_id` 发回该任务，不等待结束。

## Heartbeat 补漏

本机 Heartbeat 每 30 分钟：

1. 只读取本机最近变化的 Codex task。
2. 与 Base 的执行入口和状态字段对照。
3. 只补真实变化。
4. 没有变化时不写 Base、不写 Git 跟踪日志、不通知。
5. 手动、留空和历史旧任务不自动启动。
6. 付款、删除、对外发布、权限、凭据、生产高风险和不可逆动作不自动派发。

Skill 固定行为，Heartbeat 提供恢复性。两者不能互相替代。

## 安全边界

- 不输出或提交飞书 access token、app secret、密码、SSH 私钥和本机授权文件。
- 不把完整聊天、训练日志、笔记正文或 Base 全表快照写入仓库。
- 公开 Skill 只保存通用合同；Base token、table id 和机器路径只放各机 ignored 配置。
- 外部写入失败时说明失败层级，不伪造成功。
- 不删除任务来实现“从看板消失”；正确做法是修正状态字段。

## 回执

有写入时只报告：任务名、主状态、执行状态、真实入口、关键证据和下一步。无变化补漏保持安静。
