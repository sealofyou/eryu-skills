function letterSuffix(index) {
  var value = index;
  var suffix = "";
  do {
    suffix = String.fromCharCode(65 + (value % 26)) + suffix;
    value = Math.floor(value / 26) - 1;
  } while (value >= 0);
  return suffix;
}

function buttonIndex(tree, label) {
  for (const line of tree.split("\n")) {
    const match = line.match(/^\s*(\d+) 按钮(?: \(disabled\))? (.+)$/);
    if (match && match[2].trim() === label) return Number(match[1]);
  }
  throw new Error(`Button not found: ${label}`);
}

function labelFieldIndex(tree) {
  const match = tree.match(/^\s*(\d+) 文本栏 .*标记你的电子邮件$/m);
  if (!match) throw new Error("Hide My Email label field not found.");
  return Number(match[1]);
}

function emailFromTree(tree) {
  const match = tree.match(/[A-Za-z0-9._%+-]+@icloud\.com/i);
  if (!match) throw new Error("Generated Hide My Email address not found.");
  return match[0].toLowerCase();
}

async function getTree(app) {
  return (await globalThis.sky.get_app_state({ app, disableDiff: true })).text;
}

async function closeCompletionPage(app) {
  const tree = await getTree(app);
  if (tree.includes("设置完成") || tree.includes("Setup Complete")) {
    await globalThis.sky.click({ app, element_index: buttonIndex(tree, "完成") });
  }
}

export async function createHideMyEmailAliases({
  count = 20,
  prefix = "GPT",
  startIndex = 0,
  delayMs = 0,
  app = "System Settings",
} = {}) {
  if (!globalThis.sky) {
    throw new Error("Computer Use runtime is not initialized. Run this module from node_repl after setupComputerUseRuntime.");
  }
  if (!Number.isInteger(count) || count < 1) {
    throw new Error("count must be a positive integer.");
  }
  if (!Number.isInteger(delayMs) || delayMs < 0) {
    throw new Error("delayMs must be a non-negative integer.");
  }

  await closeCompletionPage(app);
  const created = [];
  for (let index = 0; index < count; index += 1) {
    const label = `${prefix}${letterSuffix(startIndex + index)}`;
    const listTree = await getTree(app);
    await globalThis.sky.click({ app, element_index: buttonIndex(listTree, "创建新地址") });

    const addTree = await getTree(app);
    const generated = emailFromTree(addTree);
    await globalThis.sky.set_value({ app, element_index: labelFieldIndex(addTree), value: label });

    const readyTree = await getTree(app);
    await globalThis.sky.click({ app, element_index: buttonIndex(readyTree, "继续") });

    const completeTree = await getTree(app);
    if (completeTree.includes("电子邮件已达上限") || completeTree.includes("Email limit reached")) {
      const limitError = new Error("Apple reported an address limit. The current alias was not created; pause and verify before retrying.");
      limitError.created = [...created];
      limitError.pendingLabel = label;
      throw limitError;
    }
    if (!completeTree.includes("设置完成") && !completeTree.includes("Setup Complete")) {
      throw new Error(`Alias creation did not complete for ${label}.`);
    }
    const confirmed = emailFromTree(completeTree);
    if (confirmed !== generated) {
      throw new Error(`Generated address changed for ${label}: ${generated} / ${confirmed}`);
    }
    created.push(confirmed);
    await globalThis.sky.click({ app, element_index: buttonIndex(completeTree, "完成") });
    if (delayMs > 0 && index < count - 1) {
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
  return created;
}
