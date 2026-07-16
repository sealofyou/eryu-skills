---
name: apple-hide-my-email
description: Batch-create Apple Hide My Email aliases on macOS and optionally append the resulting @icloud.com addresses to a Feishu/Lark Base email field. Use when the user asks to create Apple privacy emails, hidden email addresses, 隐藏邮件地址, 隐私邮箱, iCloud relay aliases, GPT账号邮箱整理, or to write newly created Apple aliases into Feishu Base.
---

# Apple Hide My Email

Use this skill to create Apple "Hide My Email" aliases from macOS System Settings and write only the alias email addresses into Feishu Base.

## Boundaries

- Create Apple Hide My Email aliases only.
- Write only the Feishu Base field that stores email addresses, usually `邮箱号`.
- Do not automate ChatGPT account registration, OTP retrieval, login sessions, access tokens, passwords, or 2FA.
- Do not store Feishu tokens, Base tokens, table ids, Apple account credentials, or session tokens in the skill or repository.

## Workflow

1. Read `references/runbook.md` before running the workflow.
2. Confirm System Settings can access Apple ID -> iCloud -> Hide My Email.
3. Use Computer Use to run `scripts/create_hide_my_email_aliases.mjs`; it drives the current macOS System Settings web-style panel and returns the confirmed addresses.
4. If the user wants Feishu writeback, append the returned addresses with `lark-cli base +record-batch-create`, writing only the email field.
5. Verify the Feishu write with `lark-cli base +record-list --field-id 邮箱号`; do not read other fields.

## Script

Primary creation script (run in `node_repl` after initializing the Computer Use runtime):

```js
if (!globalThis.sky) {
  const { setupComputerUseRuntime } = await import("/Users/eryu/.codex/plugins/cache/openai-bundled/computer-use/1.0.1000387/scripts/computer-use-client.mjs");
  await setupComputerUseRuntime({ globals: globalThis });
}
const { createHideMyEmailAliases } = await import("/Users/eryu/.codex/skills/apple-hide-my-email/scripts/create_hide_my_email_aliases.mjs");
const aliases = await createHideMyEmailAliases({ count: 10, prefix: "GPT", startIndex: 0, delayMs: 3000 });
nodeRepl.write(JSON.stringify(aliases));
```

`startIndex` is zero-based and controls the letter suffix: `0` produces `GPTA`; `16` produces `GPTQ`. Choose an unused prefix or starting point before creating a new batch. Use `delayMs` after a limit alert to avoid retrying a transient service throttle.

The returned list is the source of truth for Feishu writeback. Each address is read again from the `设置完成` page before it is returned.

## Notes

- The old Swift AX script remains only as a legacy diagnostic tool. Recent macOS System Settings panels accept the label value but can ignore its subsequent `继续` action when driven directly by AX; use the `.mjs` Computer Use path as the primary workflow.
- If System Settings reports `电子邮件已达上限`, stop the batch after cancelling the uncompleted form and inspect the list total. The alert can be transient; a list showing `100 items` indicates the current Apple account has reached its total capacity.
- Numeric labels can be unreliable under some Chinese input methods in Apple web-style settings panels. Prefer ASCII letter labels such as `GPTA` to `GPTT` when the user does not require exact Apple-side labels.
- The Feishu Base may still display separate user-facing labels; the important persisted field is the email address itself.
