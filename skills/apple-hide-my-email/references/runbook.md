# Apple Hide My Email Runbook

## Purpose

Create batches of Apple Hide My Email aliases on macOS and append the addresses to Feishu Base.

## Preconditions

- macOS is signed in to the correct Apple ID.
- System Settings can open Apple ID -> iCloud -> 隐藏邮件地址.
- Codex has permission to control System Settings through Computer Use.
- `lark-cli auth status` shows user identity available when Feishu writeback is required.

## Recommended Creation Script

Run this in `node_repl` after opening System Settings -> Apple ID -> iCloud -> 隐藏邮件地址:

```js
if (!globalThis.sky) {
  const { setupComputerUseRuntime } = await import("/Users/eryu/.codex/plugins/cache/openai-bundled/computer-use/1.0.1000387/scripts/computer-use-client.mjs");
  await setupComputerUseRuntime({ globals: globalThis });
}
const { createHideMyEmailAliases } = await import("/Users/eryu/.codex/skills/apple-hide-my-email/scripts/create_hide_my_email_aliases.mjs");
const aliases = await createHideMyEmailAliases({ count: 10, prefix: "GPT", startIndex: 0, delayMs: 3000 });
nodeRepl.write(JSON.stringify(aliases));
```

The script reads each address again from the `设置完成` page. Use its returned list as the source of truth. It creates labels with ASCII letters, so choose an unused prefix or `startIndex` before a new batch. `delayMs` pauses between aliases and is recommended after a limit alert.

## Feishu Writeback

Write only the email field:

```bash
lark-cli base +record-batch-create \
  --as user \
  --base-token "$GPT_ACCOUNT_BASE_TOKEN" \
  --table-id "$GPT_ACCOUNT_TABLE_ID" \
  --json '{"fields":["邮箱号"],"rows":[["one@icloud.com"],["two@icloud.com"]]}' \
  --format json
```

Verify only the email field:

```bash
lark-cli base +record-list \
  --as user \
  --base-token "$GPT_ACCOUNT_BASE_TOKEN" \
  --table-id "$GPT_ACCOUNT_TABLE_ID" \
  --field-id 邮箱号 \
  --limit 200 \
  --format json
```

## Recovery

- If the script stops after creating some aliases, use `error.created` and the visible Apple labels to determine progress; only the current pending label was not created.
- If System Settings says `电子邮件已达上限`, cancel the uncompleted form and stop the batch. No alias was created. Verify manually before retrying with `delayMs`; if the list itself shows `100 items`, the Apple account is at its total capacity.
- Do not guess missing addresses. Reopen Hide My Email and inspect labels if needed.
- If Feishu writeback fails after Apple aliases are created, rerun only the Feishu writeback with the returned email list.
- If Computer Use cannot read System Settings, verify the Codex desktop accessibility authorization before retrying.

## Safety

- Never write access tokens, passwords, OTPs, 2FA secrets, or ChatGPT session data.
- Never read Feishu fields other than the email field unless the user explicitly requests a safe field.
