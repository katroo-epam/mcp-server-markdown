---
name: solve
description: Solve a task end-to-end for the mcp-server-markdown server. Handles adding new tools, modifying existing ones, or any other change described in task.md format. Completes autonomously without asking the operator any questions.
---

You are an autonomous agent. Implement the task described in the file passed as the argument (e.g. `@task.md`). Complete it end-to-end without asking the operator any questions.

**Critical rules — never break these:**

- Do NOT ask the operator any questions at any point
- Do NOT store or update memories
- Do NOT prompt for confirmations
- Always use `pnpm` — never `npm` or `npx`

## Step 1 — Read and understand the task

Read the task file. Extract and record:

- **Tool name** — the exact name referenced in the Goal
- **Input schema** — all fields with their types; which are required vs optional
- **Output shape** — exact field names, types, and nesting (flat object? array? nested?)
- **Transport format** — how `src/index.ts` should render the result as MCP response text
  (e.g. `JSON.stringify(result)`, newline-joined list, custom text, sentinel like `"(no matches)"`)
- **Rules** — every constraint from the task
- **Examples** — treat each as a required test case

## Step 2 — Understand the codebase and detect scope

Read these files before writing any code:

- `src/markdown.ts` — existing function patterns and signatures
- `src/index.ts` — how tools are registered and how output is rendered
- `tests/markdown.test.ts` — test fixture pattern
- `AGENTS.md` — project conventions and error handling rules

Then **detect the task scope** by searching the codebase:

- Search `src/index.ts` for any `server.tool(` call whose first argument matches the tool name
- Search `src/markdown.ts` for any exported function matching the tool name

**If the tool already exists** → this is a **modification task** (Path B in Step 3).
**If the tool does not exist** → this is a **new tool task** (Path A in Step 3).

## Step 3 — Implement

### Path A — Adding a new tool

**`src/markdown.ts`** — add the logic function. Match the task input exactly — input may be a directory, a file path, a string, or multiple params:

```typescript
export interface YourResult {
  // fields matching the task output spec exactly
}

export async function yourFunction(): Promise<YourResult[] | YourResult> {
  // params matching the task input schema exactly — directory, filePath, query, flags, etc.
  // validate input:
  //   directory → path.resolve + stat → isDirectory check
  //   file      → path.resolve + stat → isFile check
  //   other     → validate as appropriate

  // for per-file iteration: wrap each file in try/catch and continue on error
  return results;
}
```

**`src/index.ts`** — register the tool. Render the output exactly as the task spec implies (JSON, text lines, etc.):

```typescript
import { yourFunction } from "./markdown.js";

server.tool(
  "tool_name", // must match task spec exactly
  "Clear description.",
  {
    // required params: z.type().describe(...)
    // optional params: z.type().optional().describe(...)
  },
  async ({ /* all params */ }) => {
    const result = await yourFunction(/* params */);
    // render output to match transport format from Step 1
    return {
      content: [{ type: "text" as const, text: /* rendered text */ }],
    };
  },
);
```

### Path B — Modifying an existing tool

1. Read the existing function in `src/markdown.ts` and its registration in `src/index.ts` in full.
2. Understand exactly what the current behavior is before touching anything.
3. Apply the minimal diff to satisfy the task spec:
   - New parameters: add to function signature and Zod schema
   - Changed logic: update only the parts the spec changes
   - Changed output: update rendering in `src/index.ts`
4. **Preserve all existing behavior** unless the spec explicitly changes it.
5. New optional parameters must default to preserving the old behavior.

## Step 4 — Write tests

Add a `describe` block to `tests/markdown.test.ts` (or extend the existing block if modifying):

- Happy path with valid input matching spec examples
- Empty/minimal input returns cleanly (empty array, `(no matches)`, etc.)
- Invalid input throws (bad path, wrong type, missing required param)
- Per-item errors are skipped, not propagated
- One `it()` per rule and per example from the task spec
- **For Path B (modification)**: add regression tests for the existing behavior that must be preserved

Use real tmp files. Pattern:

```typescript
beforeEach(async () => {
  tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "mcp-test-"));
});
afterEach(async () => {
  await fs.rm(tmpDir, { recursive: true, force: true });
});
```

Never mock `fs`.

## Step 5 — Verify

```bash
bash scripts/verify.sh
```

Fix any errors and re-run. Retry up to 3 times. Do not proceed until exit code is 0.

## Step 6 — Code review

Invoke the `Code Reviewer` agent, passing:

- The task file path
- The list of files changed

If **ISSUES FOUND**: fix each issue, re-run `bash scripts/verify.sh`, and only continue when **PASS**.

## Step 7 — Done

Report:

- Tool name added or modified
- Files changed
- Tests added (count)
- Final build and test status
