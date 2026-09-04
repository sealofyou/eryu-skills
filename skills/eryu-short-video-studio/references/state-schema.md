# 项目状态结构

`project-state.yaml` 是 Agent、用户和未来前端的共同事实源。不保存凭据、验证码、手机号或未脱敏原文。

## 必填字段

```yaml
schema_version: 1
project:
  id: "YYYYMMDD-slug"
  title: ""
  slug: ""
  platform: "douyin"
  mode: "produce"
  review_mode: "standard"
  status: "active"
  current_stage: "route"
content:
  type: ""
  audience: ""
  core_judgment: ""
  hook: ""
  duration_target_seconds: 60
  aspect_ratio: "9:16"
  version: "draft-v1"
locks:
  route: "pending"
  facts: "pending"
  script: "pending"
  visual: "pending"
  voice: "pending"
  render: "pending"
  publish: "pending"
review:
  waiting_for_user: false
  checkpoint: ""
  questions: []
cost:
  paid_action_authorized: false
  estimate: ""
  actual: ""
artifacts:
  fact_card: "fact-card.md"
  content_plan: "content-plan.md"
  speaker_notes: "speaker-notes.md"
  review_board: "review-board.md"
  verification: "verification.md"
  html: ""
  audio: ""
  subtitle: ""
  video: ""
  cover: ""
  publish_copy: "publish-copy.md"
publish:
  authorized: false
  account: ""
  status: "assets_ready"
  public_url: ""
next_action:
  owner: "agent"
  description: ""
updated_at: ""
```

## 枚举

- `project.status`: `active` / `waiting_user` / `blocked` / `complete`
- `project.current_stage`: `route` / `facts` / `script` / `visual` / `voice` / `render` / `package` / `publish` / `archive`
- `locks.*`: `pending` / `review` / `approved` / `failed` / `not_required`
- `next_action.owner`: `agent` / `user` / `external`

## 更新规则

- 每个阶段只有一个真实 `current_stage`。
- 当需要用户决定时，设置 `waiting_for_user: true`、填写 `checkpoint` 和 `questions`。
- 用户回复后立即更新对应 lock，不只在聊天中记住。
- 付费、上传和发布只能依据真实授权修改布尔字段。
- `updated_at` 使用 ISO 8601 时间。
