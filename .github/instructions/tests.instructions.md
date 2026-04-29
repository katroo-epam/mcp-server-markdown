---
applyTo: "tests/**"
---

# Test File Conventions

You are editing the vitest test suite. Follow these rules exactly.

## Framework

- **Vitest** with `describe` / `it` / `expect`. Import from `"vitest"`.
- No mocking of `fs` — use real files in a real temp directory.

## Standard fixture pattern

Every `describe` block that needs files must use this exact pattern:

```typescript
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { yourFunction } from "../src/markdown.js";

let tmpDir: string;

beforeEach(async () => {
  tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "mcp-test-"));
  // create files needed for the test
  await fs.writeFile(path.join(tmpDir, "example.md"), "# Hello\n");
});

afterEach(async () => {
  await fs.rm(tmpDir, { recursive: true, force: true });
});
```

## What to test for every new function

1. **Happy path** — basic valid input returns expected output
2. **Empty directory** — returns empty array, no error
3. **Subdirectory recursion** — files in nested dirs are included
4. **Invalid directory** — non-existent path throws
5. **Non-directory path** — file path where directory expected throws
6. **Edge cases from the task spec** — test every rule and example in the task

## Naming convention

```typescript
describe("functionName", () => {
  it("returns X when Y", async () => { ... });
  it("throws when directory does not exist", async () => {
    await expect(yourFunction("/nonexistent")).rejects.toThrow();
  });
});
```

## Imports

Always use `.js` extension on local imports:
```typescript
import { yourFunction } from "../src/markdown.js";
```

## Never

- Mock `fs` or `path`
- Use `setTimeout` or real network calls
- Hardcode absolute paths — always use `tmpDir` from `beforeEach`
- Leave temp files behind — always clean up in `afterEach`
