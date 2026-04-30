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

## Mandatory edge-case checklist

For every new function, cover as many of these as are relevant. Each item should be its own `it()`:

### Input validation
- Path traversal attempt: `directory = tmpDir + "/../../etc"` — must throw or resolve safely
- Empty string path — must throw
- Path to a file instead of a directory (for directory-accepting tools) — must throw

### File content edge cases
- **Empty file** — a `.md` file with zero bytes; must not throw, return empty/no result for that file
- **Frontmatter-only file** — only YAML frontmatter, no body content
- **No headings** — file with only paragraph text, no `#` headings
- **Duplicate headings** — two or more headings with the same text in one file
- **Unicode content** — headings or body with emoji, CJK characters, accented letters
- **CRLF line endings** — file written with `\r\n`; line numbers and content must still be correct
- **Very long line** — a single line exceeding 10 000 characters; must not hang or crash

### Directory/filesystem edge cases
- **Deeply nested subdirectory** — at least 3 levels deep (`a/b/c/file.md`); file must be included
- **Non-markdown files** — `.txt`, `.json`, `.png` files in the directory; must be ignored
- **Per-item error resilience** — one unreadable or corrupted file must not fail the whole call; remaining files are still returned

### Result correctness
- **Sorting / ordering** — if the spec implies sorted output, verify with multiple files
- **Relative paths** — returned `file` fields must be relative to the input directory, not absolute
- **1-based positions** — if the output includes `line` or `column`, verify they start at 1, not 0

### Optional flags / parameters (when a tool has them)
- Default value of every optional parameter preserves the previous behavior
- Setting a flag to `false` excludes the expected item type
- Setting a flag to `true` includes items that would otherwise be omitted

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
