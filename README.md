# eryu-skills

Public-safe skills mirror for bootstrapping a new machine.

This repository currently syncs the first safe batch: PPT/deck skills and their minimal Lark dependency.

## Mac install

```bash
git clone https://github.com/sealofyou/eryu-skills.git ~/workspace/github/eryu-skills
cd ~/workspace/github/eryu-skills
bash install-mac.sh
```

Restart Codex / agent sessions after installing.

## Included now

- `gpt-image2-ppt-skills`: image-based 16:9 PPTX generation.
- `guizang-ppt-skill`: single-file horizontal web deck generation.
- `lark-shared`: Lark auth and shared CLI rules needed by Lark skills.
- `lark-slides`: Feishu/Lark online slides creation and editing.

## Not included yet

Personal integration and automation skills are intentionally excluded until separately sanitized, including Get笔记, daily task hub, broad Feishu/Lark suites, Dida sync, server/credential workflows, logs, generated outputs, cookies, browser state, `.env`, and private keys.

## Secret policy

Do not commit real API keys, tokens, passwords, OAuth files, cookies, private keys, local account configs, databases, logs, or generated runtime state. Use local environment variables, password managers, untracked local files, or platform settings.