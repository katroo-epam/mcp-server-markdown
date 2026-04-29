# Copilot Instructions

## Commands

```bash
pnpm install         # install dependencies
pnpm build           # compile with tsup → dist/
pnpm typecheck       # tsc --noEmit (no emit, just type-check)
pnpm lint            # eslint + prettier --check
pnpm format          # prettier --write
pnpm test            # vitest run (single pass)
pnpm test:watch      # vitest watch mode
pnpm test:coverage   # vitest run --coverage
```

Run a single test file:

```bash
pnpm exec vitest run tests/markdown.test.ts
```

Run a single `describe` block or `it` by name pattern:

```bash
pnpm exec vitest run -t "listMarkdownFiles"
```

## Architecture

This is a **Model Context Protocol (MCP) server** that exposes markdown-parsing capabilities over stdio to MCP clients (Claude Desktop, Cursor, VS Code Copilot, etc.).

```
src/index.ts     — MCP server wiring: registers tools, starts StdioServerTransport
src/markdown.ts  — Pure async functions: all markdown parsing logic lives here
tests/
  markdown.test.ts — Tests only src/markdown.ts; uses real tmp-dir fixtures
```

**Data flow:** MCP client → stdio → `McpServer` (index.ts) → calls functions from `markdown.ts` → returns `{ content: [{ type: "text", text }] }`.

All tool handlers in `index.ts` resolve paths with `path.resolve()` before passing to `markdown.ts`. The markdown functions themselves also call `path.resolve()` internally, so paths are always absolute before any `fs` call.

## Key Conventions

**Two-layer separation:** `index.ts` owns MCP wiring and response formatting; `markdown.ts` owns all file I/O and parsing logic. New tools follow this same split — add the pure function to `markdown.ts` and the `server.tool(...)` registration to `index.ts`.

**TypeScript strictness:** `strict: true` + `noUncheckedIndexedAccess: true` are enabled. Array element access like `lines[i]` returns `string | undefined`; always guard with `if (line !== undefined)` before use (see existing patterns in `markdown.ts`).

**ESM module imports:** The project uses `"type": "module"` and `"moduleResolution": "NodeNext"`. Imports within the project must use `.js` extensions (e.g., `"./markdown.js"`), even though the source files are `.ts`.

**Test fixtures with real fs:** Tests create a real temp directory in `beforeEach` via `fs.mkdtemp` and clean up in `afterEach`. Do not mock `fs` — use real files in `os.tmpdir()`.

**Tool response shape:** Every MCP tool handler must return `{ content: [{ type: "text" as const, text: string }] }`. The `as const` assertion on `type` is required for TypeScript to satisfy the SDK's type.

**Build output:** `tsup` produces a single ESM file at `dist/index.js` with a `#!/usr/bin/env node` shebang injected. The `dist/` directory is the published artifact (see `"files"` in `package.json`).

**Lint-staged hooks:** Husky runs `eslint --fix` + `prettier --write` on staged `.ts`/`.js` files and `prettier --write` on `.json`/`.md`/`.yml` files on commit.
