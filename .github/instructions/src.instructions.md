---
applyTo: "src/**"
---

# Source File Conventions

You are editing the MCP server source. Follow these rules exactly.

## Two-file architecture

- `src/markdown.ts` — all logic, file I/O, and parsing. Export every new function and interface.
- `src/index.ts` — only MCP wiring. Import from `"./markdown.js"` (`.js` extension, not `.ts`).

## TypeScript rules

- `strict: true` and `noUncheckedIndexedAccess: true` are enabled.
- Array access `arr[i]` returns `T | undefined`. Always guard: `if (line !== undefined)`.
- Never use `any`. Use `unknown` and narrow it.
- All new interfaces and types go in `src/markdown.ts`, not in `src/index.ts`.

## Adding a new function to src/markdown.ts

```typescript
import fs from "node:fs/promises";
import path from "node:path";

export interface YourResult {
  file: string;
  // ... fields matching the task output spec exactly
}

export async function yourFunction(directory: string): Promise<YourResult[]> {
  const absDir = path.resolve(directory);
  const stat = await fs.stat(absDir);
  if (!stat.isDirectory()) {
    throw new Error(`Not a directory: ${directory}`);
  }
  // ... implementation
  return results;
}
```

## Adding a tool registration to src/index.ts

```typescript
// 1. Add to the import block at the top
import { yourFunction } from "./markdown.js";

// 2. Add a server.tool() call — keep it in the same order as the function in markdown.ts
server.tool(
  "your_tool_name", // must match task spec exactly
  "Clear description.",
  {
    directory: z.string().describe("Path to the directory"),
    optionalParam: z.boolean().optional().describe("Optional flag"),
  },
  async ({ directory, optionalParam }) => {
    const absDir = path.resolve(directory);
    const result = await yourFunction(absDir, optionalParam);
    return {
      content: [{ type: "text" as const, text: JSON.stringify(result) }],
    };
  },
);
```

## Error handling

- **Invalid input** (bad path, not a directory): throw `new Error(...)` — MCP SDK converts it automatically.
- **Per-file errors**: wrap in `try/catch` and `continue` — never let one bad file fail the whole call.

## Security

- Always call `path.resolve()` on user-supplied paths before passing to `fs`.
- Never concatenate user input directly into shell commands.
- Validate that the resolved path is a directory before iterating it.
