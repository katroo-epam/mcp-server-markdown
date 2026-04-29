# AGENTS.md

## Project Overview

`mcp-server-markdown` is a TypeScript MCP (Model Context Protocol) server that exposes
markdown-parsing tools over stdio to MCP clients (Claude, VS Code Copilot, Cursor, etc.).

## File Map

| File                     | Role                                                |
| ------------------------ | --------------------------------------------------- |
| `src/index.ts`           | MCP server: tool registrations only, no logic       |
| `src/markdown.ts`        | All file I/O and markdown parsing logic             |
| `tests/markdown.test.ts` | Vitest tests — uses real tmp-dir fixtures, no mocks |

## Repo Invariants (apply to every task)

These constraints apply regardless of whether you are adding a new tool or modifying an existing one:

- **Logic in `src/markdown.ts`** — all file I/O and parsing stays here; `src/index.ts` never calls `fs` directly.
- **Registration in `src/index.ts`** — every tool is registered with `server.tool()`; no logic lives in handlers.
- **Tests in `tests/markdown.test.ts`** — add a `describe` block or extend the existing one; never mock `fs`.
- **Verify with `bash scripts/verify.sh`** — runs typecheck + build + tests; must exit 0 before finishing.
- **Path safety** — always call `path.resolve()` on user-supplied paths before any `fs` call.
- **TypeScript strict** — `strict: true` and `noUncheckedIndexedAccess: true`; guard `arr[i]` before use.
- **ESM imports** — local imports use `.js` extension (`"./markdown.js"`, not `"./markdown.ts"`).

## How to Add a New Tool

Every new tool follows this two-step split:

**Step 1 — `src/markdown.ts`**: Add the pure async function with all logic.
Input may be a directory, a file path, a string, or multiple parameters — match the task spec.

```typescript
// src/markdown.ts
export interface MyResult {
  file: string;
  count: number;
}

export async function myTool(directory: string): Promise<MyResult[]> {
  const absDir = path.resolve(directory);
  const stat = await fs.stat(absDir);
  if (!stat.isDirectory()) throw new Error(`Not a directory: ${directory}`);
  // ... logic
  return results;
}
```

**Step 2 — `src/index.ts`**: Import and register the tool. Output rendering (JSON, text, etc.)
must match what the task spec implies — look at existing tools for reference patterns.

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
    return {
      content: [{ type: "text" as const, text: JSON.stringify(results) }],
    };
  },
);
```

## How to Modify an Existing Tool

When modifying an existing tool:

1. **Read the current implementation first** — understand exactly what exists before touching anything.
2. **Make the minimal diff** — change only what the task spec requires.
3. **Preserve existing behavior** unless the spec explicitly changes it.
   New optional parameters must default to the old behavior.
4. **Add regression tests** — at least one test per existing behavior path that must be preserved.
5. **Run `bash scripts/verify.sh`** — all previously passing tests must still pass.

## Error Handling Conventions

Two levels of error handling apply to every tool:

**Fatal (fail the whole call):** Invalid input like a missing or wrong-type path.
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
bash scripts/verify.sh   # typecheck + build + all tests — must exit 0
```

## Constraints

- Never pre-implement task solutions in this file or any prompt/instruction file.
- Do not mock `fs` in tests — use real files in a temp directory (`os.tmpdir()`).
- Do not ask the operator questions — proceed autonomously.
- Match existing code style: ESM `.js` imports, `strict` TS, `as const` on type literals.
