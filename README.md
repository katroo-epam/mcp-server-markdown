# mcp-server-markdown

[![npm version](https://img.shields.io/npm/v/mcp-server-markdown.svg)](https://www.npmjs.com/package/mcp-server-markdown)
[![npm downloads](https://img.shields.io/npm/dm/mcp-server-markdown.svg)](https://www.npmjs.com/package/mcp-server-markdown)
[![CI](https://github.com/ofershap/mcp-server-markdown/actions/workflows/ci.yml/badge.svg)](https://github.com/ofershap/mcp-server-markdown/actions/workflows/ci.yml)
[![TypeScript](https://img.shields.io/badge/TypeScript-strict-blue.svg)](https://www.typescriptlang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Search, navigate, and extract content from local markdown files. Full-text search, section extraction, heading navigation, code block discovery, and frontmatter parsing.

```bash
npx mcp-server-markdown
```

> Works with Claude Desktop, Cursor, VS Code Copilot, and any MCP client. Reads local `.md` files, no auth needed.

![MCP server for searching and navigating markdown documentation](assets/demo.gif)

<sub>Demo built with <a href="https://github.com/ofershap/remotion-readme-kit">remotion-readme-kit</a></sub>

## Why

Tools like Context7 are great for looking up library docs from npm, but they don't help with your own documentation. Project wikis, internal knowledge bases, architecture decision records, onboarding guides: they all live as markdown files in your repo or on disk. The filesystem MCP server can read those files, but it treats them as raw text. It doesn't understand headings, sections, or code blocks. This server does. Point it at a directory and your assistant can search across all your docs, pull out a specific section by heading, list the table of contents, or find every TypeScript code example in your knowledge base.

## Tools

| Tool               | What it does                                                               |
| ------------------ | -------------------------------------------------------------------------- |
| `list_files`       | List all .md files in a directory recursively (sorted alphabetically)      |
| `search_docs`      | Full-text search across all .md files (case-insensitive, up to 50 results) |
| `get_section`      | Extract a section by heading until the next heading of same/higher level   |
| `list_headings`    | List all headings as a table of contents                                   |
| `find_code_blocks` | Find fenced code blocks, optionally filter by language (e.g. typescript)   |
| `get_frontmatter`  | Parse YAML frontmatter metadata at the start of a file                     |

## Quick Start

### Cursor

Add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "markdown": {
      "command": "npx",
      "args": ["-y", "mcp-server-markdown"]
    }
  }
}
```

### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "markdown": {
      "command": "npx",
      "args": ["-y", "mcp-server-markdown"]
    }
  }
}
```

### VS Code

Add to user settings or `.vscode/mcp.json`:

```json
{
  "mcp": {
    "servers": {
      "markdown": {
        "command": "npx",
        "args": ["-y", "mcp-server-markdown"]
      }
    }
  }
}
```

## Examples

- "Search all docs in ./docs for mentions of 'authentication'"
- "Show me the 'API Reference' section from README.md"
- "List all headings in CONTRIBUTING.md"
- "Find all TypeScript code blocks in the docs"
- "What's the frontmatter metadata in this file?"
- "Give me the table of contents for our architecture docs"

## Agentic Workflow

This repository includes a GitHub Copilot CLI multi-agent workflow for implementing new MCP tools autonomously — from spec to verified, reviewed code — with zero operator input after the start command.

### Architecture

```
Operator
   │
   └─ /solve @task.md
         │
         ▼
   ┌─────────────────────────────────────────────────────┐
   │  Orchestrator  (.github/prompts/solve.prompt.md)    │
   │  Entry point — delegates everything to solve skill  │
   └──────────────────────┬──────────────────────────────┘
                          │ invokes
                          ▼
   ┌─────────────────────────────────────────────────────┐
   │  solve skill  (.github/skills/solve/SKILL.md)       │
   │                                                     │
   │  Step 1 — Parse task spec (tool name, I/O, rules)   │
   │  Step 2 — Read codebase, detect new vs. modify      │
   │  Step 3 — Implement in src/markdown.ts + index.ts   │
   │  Step 4 — Write tests in tests/markdown.test.ts     │
   │  Step 5 — Run bash scripts/verify.sh (exit 0)       │
   │  Step 6 — Invoke Code Reviewer ──────────────────┐  │
   │  Step 7 — Report results                         │  │
   └──────────────────────────────────────────────────┼──┘
                                                      │ spawns
                                                      ▼
                          ┌───────────────────────────────────┐
                          │  Code Reviewer agent              │
                          │  (.github/agents/review.agent.md) │
                          │                                   │
                          │  Independent — reads, never edits │
                          │  Checks: correctness, security,   │
                          │  edge cases, style, test coverage │
                          │                                   │
                          │  Returns: PASS | ISSUES FOUND     │
                          └───────────────────────────────────┘
```

If the Code Reviewer returns **ISSUES FOUND**, the `solve` skill fixes each issue and re-runs `verify.sh` before completing.

### Instruction files

| File                                         | Purpose                                                          |
| -------------------------------------------- | ---------------------------------------------------------------- |
| `.github/copilot-instructions.md`            | Global rules: commands, architecture, key conventions            |
| `.github/instructions/src.instructions.md`   | Source file rules (applied to `src/**`)                          |
| `.github/instructions/tests.instructions.md` | Test conventions and edge-case checklist (applied to `tests/**`) |
| `AGENTS.md`                                  | Full project conventions reference for all agents                |

### One-time setup (per machine)

Open GitHub Copilot CLI **in the repo directory** and run:

```
/allow-all
```

The CLI tracks approvals per command type (e.g. `bash`, `pnpm install`, `pnpm build`, `pnpm test` are all separate entries). `/allow-all` adds a wildcard that pre-approves **all** tool permissions for this repo — file writes, bash scripts, and every pnpm command — so the agent never stops to ask during the solve run.

> **Note:** This must be run from the repo directory so the approval is scoped to this repo's path. It persists across sessions, so you only need to do it once per machine.

### Running the workflow

```
/solve @task.md
```

The agent will implement the task end-to-end: reading the spec, writing code, writing tests, verifying the build, and running an independent code review — all without operator input.

> **Note:** Without the `/allow-all` pre-setup, the CLI will prompt for bash command approval mid-run, which interrupts the autonomous workflow.

### What the workflow produces

After a successful run, the agent will have:

1. Added a new exported function to `src/markdown.ts` with all logic
2. Registered the tool in `src/index.ts` via `server.tool()`
3. Added a `describe` block to `tests/markdown.test.ts` covering happy path, edge cases, and error handling
4. Passed `pnpm typecheck`, `pnpm build`, `pnpm test`, and `pnpm lint`
5. Received a **PASS** from the independent Code Reviewer agent

### Interpreting results

| Signal                               | Meaning                                                               |
| ------------------------------------ | --------------------------------------------------------------------- |
| `verify.sh` exits 0                  | Build, types, and all tests pass                                      |
| Code Reviewer returns `PASS`         | Implementation is correct, secure, and well-tested                    |
| Code Reviewer returns `ISSUES FOUND` | Agent will self-correct and re-verify before finishing                |
| Agent asks a question                | Should not happen — if it does, it incurs a penalty per contest rules |

## Development

```bash
git clone https://github.com/ofershap/mcp-server-markdown.git
cd mcp-server-markdown
pnpm install
pnpm test
pnpm build
```

## See also

More MCP servers and developer tools on my [portfolio](https://gitshow.dev/ofershap).

## Author

[![Made by ofershap](https://gitshow.dev/api/card/ofershap)](https://gitshow.dev/ofershap)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://linkedin.com/in/ofershap)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=flat&logo=github&logoColor=white)](https://github.com/ofershap)

---

<sub>README built with [README Builder](https://ofershap.github.io/readme-builder/)</sub>

## License

MIT © 2026 Ofer Shapira
