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

Input may be a directory, a file path, a string, or multiple parameters — match the task spec.
Do not assume directory input or array output unless the spec says so.

```typescript
import fs from "node:fs/promises";
import path from "node:path";

export interface YourResult {
  file: string;
  // ... fields matching the task output spec exactly
}

export async function yourFunction(): Promise<YourResult[] | YourResult> {
  // params matching the task input spec
  // For directory input:
  const absDir = path.resolve(directory);
  const stat = await fs.stat(absDir);
  if (!stat.isDirectory()) {
    throw new Error(`Not a directory: ${directory}`);
  }
  // For file input:
  // const absFile = path.resolve(filePath);
  // const stat = await fs.stat(absFile);
  // if (!stat.isFile()) throw new Error(`Not a file: ${filePath}`);
  return results;
}
```

## Modifying an existing function in src/markdown.ts

1. Read the full existing function before making any changes.
2. Apply the minimal diff required by the task spec.
3. Preserve all existing behavior unless the spec explicitly changes it.
4. New optional parameters must default to the old behavior.

## Adding a tool registration to src/index.ts

Output rendering must match what the task spec implies. Check existing tools:
some use `JSON.stringify`, some join lines with `"\n"`, some use sentinel text like `"(no matches)"`.

```typescript
// 1. Add to the import block at the top
import { yourFunction } from "./markdown.js";

// 2. Add a server.tool() call — keep it in the same order as the function in markdown.ts
server.tool(
  "your_tool_name", // must match task spec exactly
  "Clear description.",
  {
    // required params: z.type().describe(...)
    // optional params: z.type().optional().describe(...)
  },
  async ({ /* all params */ }) => {
    const result = await yourFunction(/* params */);
    return {
      content: [{ type: "text" as const, text: /* rendered output */ }],
    };
  },
);
```

## Error handling

- **Invalid input** (bad path, not a directory, not a file): throw `new Error(...)` — MCP SDK converts it automatically.
- **Per-file errors**: wrap in `try/catch` and `continue` — never let one bad file fail the whole call.

## Security

- Always call `path.resolve()` on user-supplied paths before passing to `fs`.
- Never concatenate user input directly into shell commands.
- Validate that the resolved path is the expected type (directory, file) before using it.
