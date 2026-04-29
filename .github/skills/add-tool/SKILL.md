---
name: add-tool
description: Add a new tool to the mcp-server-markdown MCP server. Use when a task requires implementing a new MCP tool — reading a task spec, writing the logic function, registering it, writing tests, and verifying the build passes. Always use this skill when adding any new capability to the server.
---

# Add a New MCP Tool

Use this skill when you need to implement a new tool in `mcp-server-markdown`.
It covers the full workflow: spec → implement → test → verify → review.

## Workflow

### 1. Parse the task spec

Read the task file and extract:
- **Tool name** — the exact string to use in `server.tool()`
- **Input schema** — required fields and optional fields (with types)
- **Output shape** — exact field names, types, and values
- **Rules** — every constraint listed; check each one during implementation
- **Examples** — use them as test cases

### 2. Read the codebase before writing any code

```
src/markdown.ts      ← understand existing function patterns
src/index.ts         ← understand tool registration pattern
tests/markdown.test.ts ← understand test fixture pattern
```

### 3. Implement — two-file split (always)

**`src/markdown.ts`** — add the logic function:
```typescript
export interface YourResult {
  // fields matching the task output spec exactly
}

export async function yourFunction(
  directory: string,
  // optional params last
): Promise<YourResult[]> {
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

**`src/index.ts`** — register the tool:
```typescript
// Add to imports at the top
import { yourFunction } from "./markdown.js";

// Add server.tool() call
server.tool(
  "tool_name",           // must match task spec exactly
  "Clear description.",
  {
    directory: z.string().describe("Path to directory"),
    optionalFlag: z.boolean().optional().describe("Optional flag"),
  },
  async ({ directory, optionalFlag }) => {
    const absDir = path.resolve(directory);
    const result = await yourFunction(absDir, optionalFlag);
    return { content: [{ type: "text" as const, text: JSON.stringify(result) }] };
  },
);
```

### 4. Write tests

Add a `describe` block to `tests/markdown.test.ts`:

```typescript
describe("yourFunction", () => {
  it("returns expected results for valid input", async () => { ... });
  it("returns empty array for empty directory", async () => { ... });
  it("throws when directory does not exist", async () => {
    await expect(yourFunction("/nonexistent")).rejects.toThrow();
  });
  it("skips bad files without failing", async () => { ... });
  // one test per rule/example from the task spec
});
```

Always use real tmp files — never mock `fs`. Pattern:
```typescript
beforeEach(async () => {
  tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "mcp-test-"));
});
afterEach(async () => {
  await fs.rm(tmpDir, { recursive: true, force: true });
});
```

### 5. Verify

```bash
bash scripts/verify.sh
```

Fix any errors and re-run until it exits 0.

### 6. Spec checklist — before finishing

- [ ] Tool name matches task spec exactly
- [ ] All required inputs present in Zod schema
- [ ] All optional inputs marked `.optional()`
- [ ] Output JSON shape matches spec exactly (field names, types)
- [ ] Every rule from the task is implemented
- [ ] All task examples produce correct output
- [ ] No existing tests broken

## Key Rules

| Rule | Detail |
|---|---|
| `.js` imports | Always `"./markdown.js"`, never `.ts` |
| `as const` | Required on `type: "text"` in tool response |
| Array guards | `arr[i]` is `T \| undefined` — always check before use |
| Path safety | Always `path.resolve()` before any `fs` call |
| Error levels | Fatal = bad input (throw); Per-item = bad file (catch + continue) |

## Spec Template

Use this to capture the task before implementing:

```
Tool name: 
Input (required): 
Input (optional): 
Output shape: 
Rules:
  1.
  2.
Edge cases:
  -
Examples from spec:
  Input:
  Expected output:
```
