# 任务回写字段合同

## 本机配置

```json
{
  "machine_id": "laptop-win",
  "eryuos_root": "本机 eryuOS 绝对路径",
  "base_token": "本机受控资源 ID",
  "table_id": "本机受控资源 ID",
  "identity": "user"
}
```

配置只保存资源定位，不保存飞书 access token、app secret 或密码。

## 字段矩阵

| 事件 | 状态 | 执行状态 | 当前进展 | 下一步动作 | 完成时间 |
| --- | --- | --- | --- | --- | --- |
| 记录 | 收集箱 / 今天 / 本周 | 空 | 可空 | 可执行动作 | 空 |
| 开始 | 保留 | 执行中 | 起点证据 | 当前动作 | 空 |
| 阶段 | 保留 | 执行中 | 新阶段证据 | 后续动作 | 空 |
| 等待 | 保留 | 等我 | 已完成部分 | 一个问题 | 空 |
| 交付 | 保留 | 待验收 | 交付物与验证 | 验收方法 | 空 |
| 暂停 | 暂缓 | 已暂停 | 暂停原因 | 恢复条件 | 空 |
| 完成 | 已完成 | 空 | 最终证据 | 已完成或独立后续 | 必填 |
| 不确定 | 保留 | 状态待核对 | 已知事实 | 缺失证据 | 空 |

## 最小命令顺序

命令参数来自本机 ignored 配置。示例不包含真实资源 ID。

```text
lark-cli base +record-get --base-token <base> --table-id <table> --record-id <record> --as user --format json
lark-cli base +record-upsert --base-token <base> --table-id <table> --record-id <record> --as user --json <field-map>
lark-cli base +record-get --base-token <base> --table-id <table> --record-id <record> --as user --format json
```

`+record-upsert` 不会按任务名自动去重。不带 `--record-id` 一定创建新行，因此创建前必须先查重。

## 完成字段示例

```json
{
  "状态": ["已完成"],
  "执行状态": null,
  "当前进展": "最终结果与验证证据",
  "下一步动作": "已完成；不再处理。",
  "完成时间": "YYYY-MM-DD HH:mm",
  "复盘一句话": "可复用经验"
}
```

## 独立新任务判断

满足任一条件时倾向新建：

- 新的完成定义。
- 新模型版本和新假设。
- 独立数据、门禁、结果与复盘。
- 用户明确要求单独跟踪。

只是换 session、换机器、补解释或修同一交付物时继续原行。

## 跨机完成

不能读取远端 task 时：

1. 保留最后有证据状态。
2. 不把 SSH 通、进程存在或用户说“应该还在做”扩大为完成证据。
3. 让远端执行者自写，或等待远端 Heartbeat 补漏。
4. 远端完成回写必须清空执行状态。
