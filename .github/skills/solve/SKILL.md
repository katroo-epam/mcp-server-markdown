---
name: solve
description: Solve a task by implementing a new MCP tool end-to-end. Use when given a task file describing what to add to the mcp-server-markdown server. Reads the task, implements the feature, writes tests, verifies the build, runs code review, and completes autonomously without asking the operator any questions.
---

You are an autonomous agent. Implement the task described in the file passed as the argument (e.g. `@task.md`). Complete it end-to-end without asking the operator any questions.

## Step 1 — Read and understand the task

Read the task file. Extract:

- The exact tool name to add
- Input schema: required and optional fields with types
- Output shape: exact field names, types, and values
- All rules and edge cases listed in the task
- Any examples provided

## Step 2 — Understand the codebase

Read these files before writing any code:

- `src/markdown.ts` — existing function patterns
- `src/index.ts` — how tools are registered
- `tests/markdown.test.ts` — test fixture pattern
- `AGENTS.md` — project conventions and error handling rules

## Step 3 — Implement

**`src/markdown.ts`** — add the logic function:

```typescript
export interface YourResult {
  // fields matching the task output spec exactly
}

export async function yourFunction(directory: string): Promise<YourResult[]> {
  const absDir = path.resolve(directory);
  const stat = await fs.stat(absDir);
  if (!stat.isDirectory()) throw new Error(`Not a directory: ${directory}`);
  const files = await listMarkdownFiles(absDir);
  const results: YourResult[] = [];
  for (const file of files) {
    try {
      // per-file logic
    } catch {
      continue; // skip bad files, never fail the whole call
    }
  }
  return results;
}
```

**`src/index.ts`** — add to imports and register the tool:

```typescript
import { yourFunction } from "./markdown.js";

server.tool(
  "tool_name",
  "Description.",
  { directory: z.string().describe("Path to directory") },
  async ({ directory }) => {
    const absDir = path.resolve(directory);
    const result = await yourFunction(absDir);
    return {
      content: [{ type: "text" as const, text: JSON.stringify(result) }],
    };
  },
);
```

## Step 4 — Write tests

Add a `describe` block to `tests/markdown.test.ts`:

- Happy path with valid input
- Empty directory returns empty results, not an error
- Invalid directory throws
- Per-file error skipped without failing the whole call
- One test per rule/example from the task spec

Use the existing pattern: `fs.mkdtemp` in `beforeEach`, `fs.rm` in `afterEach`, real files only — never mock `fs`.

## Step 5 — Verify

```bash
bash scripts/verify.sh
```

If it fails: fix the error and re-run. Retry up to 3 times. Do not proceed until exit code is 0.

## Step 6 — Code review

Review the implementation against the task spec:

- Tool name matches exactly
- All required inputs in Zod schema; optional inputs marked `.optional()`
- Output JSON shape matches spec exactly
- Every rule from the task is implemented
- No existing tests broken
- Path traversal protected: `path.resolve()` before every `fs` call
- Per-file errors caught and skipped, not propagated

If issues found: fix them, re-run `bash scripts/verify.sh`.

## Step 7 — Done

Report:

- Tool name added
- Files changed
- Number of tests added
- Final build and test status
