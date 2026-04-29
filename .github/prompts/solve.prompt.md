---
description: "Solve a task: implement a new MCP tool end-to-end. Usage: /solve @task.md"
agent: "agent"
argument-hint: "Path to task file, e.g. @task.md"
model: "Claude Sonnet 4.6 (copilot)"
tools: [read, edit, search, execute, agent, todo]
---

You are an autonomous agent. Your goal is to implement the task described in the file
provided as the argument. Complete it end-to-end without asking the operator any questions.

## Step 1 — Read and understand the task

Read the task file passed as the argument. Extract:

- What new function/tool needs to be added
- The exact input schema (required and optional fields)
- The exact output shape (field names, types, values)
- All rules and edge cases listed in the task

## Step 2 — Understand the codebase

Read these files before writing any code:

- `src/markdown.ts` — understand existing function patterns
- `src/index.ts` — understand how tools are registered
- `tests/markdown.test.ts` — understand the test fixture pattern

Follow the patterns in `AGENTS.md` exactly.

## Step 3 — Implement

1. Add the new logic function to `src/markdown.ts`
2. Add the `server.tool()` registration to `src/index.ts`
3. Export the new function from `src/markdown.ts` (required for testing)

Apply error handling conventions from `AGENTS.md`:

- Fatal errors for invalid input (missing/non-directory path)
- Per-item try/catch for individual file failures

## Step 4 — Write tests

Add tests to `tests/markdown.test.ts`:

- Happy path: basic working input
- Edge cases from the task spec
- Error cases: invalid directory, missing files, empty directory
- Boundary cases: empty results, large inputs

Use the existing pattern: `fs.mkdtemp` in `beforeEach`, `fs.rm` in `afterEach`, real files only.

## Step 5 — Verify

Run the verification script:

```bash
bash scripts/verify.sh
```

This runs `pnpm install` → `pnpm typecheck` → `pnpm build` → `pnpm test` in sequence.
If any step fails: fix the error, then re-run the script.
Retry up to 3 times. Do not proceed until the script exits with code 0.

## Step 6 — Independent code review

Invoke the `Code Reviewer` agent, passing:

- The task file path
- The list of files changed: `src/markdown.ts`, `src/index.ts`, `tests/markdown.test.ts`

If the reviewer reports **ISSUES FOUND**:

- Fix each reported issue
- Re-run `pnpm build && pnpm test`
- Only proceed when the reviewer reports **PASS**

## Step 7 — Done

Confirm completion with a summary:

- Tool name added
- Files changed
- Tests added (count)
- Review result
