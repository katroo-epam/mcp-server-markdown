# AGENTS.md

## Project Overview

`mcp-server-markdown` is a TypeScript MCP (Model Context Protocol) server that exposes
markdown-parsing tools over stdio to MCP clients (Claude, VS Code Copilot, Cursor, etc.).

## File Map

| File | Role |
|---|---|
| `src/index.ts` | MCP server: tool registrations only, no logic |
| `src/markdown.ts` | All file I/O and markdown parsing logic |
| `tests/markdown.test.ts` | Vitest tests — uses real tmp-dir fixtures, no mocks |

## How to Add a New Tool

Every new tool follows this two-step split:

**Step 1 — `src/markdown.ts`**: Add the pure async function with all logic.

```typescript
// src/markdown.ts
export interface MyResult { file: string; count: number; }

export async function myTool(directory: string): Promise<MyResult[]> {
  const absDir = path.resolve(directory);
  const stat = await fs.stat(absDir);
  if (!stat.isDirectory()) throw new Error(`Not a directory: ${directory}`);
  // ... logic
  return results;
}
```

**Step 2 — `src/index.ts`**: Import and register the tool.

```typescript
// src/index.ts — add to imports
import { myTool } from "./markdown.js";

// add a new server.tool() call
server.tool(
  "my_tool",
  "Description of what this tool does.",
  {
    directory: z.string().describe("Path to the directory to scan"),
  },
  async ({ directory }) => {
    const absDir = path.resolve(directory);
    const results = await myTool(absDir);
    return { content: [{ type: "text" as const, text: JSON.stringify(results) }] };
  },
);
```

## Error Handling Conventions

Two levels of error handling apply to every tool:

**Fatal (fail the whole call):** Invalid input like a missing or non-directory path.
Throw an `Error` — the MCP SDK converts it to a proper MCP error response automatically.

**Per-item (skip and continue):** A single bad file must not stop processing.
Wrap per-file logic in `try/catch` and skip the bad record — return the rest.

```typescript
for (const file of files) {
  try {
    // process file
  } catch {
    continue; // skip bad file, don't fail the whole call
  }
}
```

## Verification (run after every change)

```bash
pnpm install   # first run only
pnpm build     # must succeed with no errors
pnpm test      # all tests must pass
```

If build or tests fail — fix before considering the task done.

## Constraints

- Never pre-implement task solutions in this file or any prompt/instruction file.
- Do not mock `fs` in tests — use real files in a temp directory (`os.tmpdir()`).
- Do not ask the operator questions — proceed autonomously.
- Match existing code style: ESM `.js` imports, `strict` TS, `as const` on type literals.
