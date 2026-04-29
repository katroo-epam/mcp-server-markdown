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

Read the task file passed as the argument. Extract and record:

- The exact tool name to add
- Input schema: required and optional fields with types
- Output shape: exact field names, types, and values
- All rules and edge cases listed in the task
- Any examples provided

## Step 2 — Implement using the add-tool skill

Invoke the `add-tool` skill. Pass it the full task context you extracted in Step 1:
the tool name, input schema, output shape, all rules, edge cases, and examples.

The `add-tool` skill owns the complete implementation workflow:
reading the codebase → implementing the function in `src/markdown.ts` → registering
the tool in `src/index.ts` → writing tests in `tests/markdown.test.ts` →
running `bash scripts/verify.sh` → checking the spec checklist.

Do not start writing code yourself before invoking the skill.

## Step 3 — Independent code review

Invoke the `Code Reviewer` agent, passing:

- The task file path
- The list of files changed: `src/markdown.ts`, `src/index.ts`, `tests/markdown.test.ts`

If the reviewer reports **ISSUES FOUND**:

- Fix each reported issue
- Re-run `pnpm build && pnpm test`
- Only proceed when the reviewer reports **PASS**

## Step 4 — Done

Confirm completion with a summary:

- Tool name added
- Files changed
- Tests added (count)
- Review result
