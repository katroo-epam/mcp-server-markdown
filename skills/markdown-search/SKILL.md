---
name: markdown-search
description: Search, navigate, and extract content from local markdown files via MCP. Use when working with documentation or knowledge bases.
---

# Markdown Search via MCP

Use this skill when you need to search documentation, extract sections, list headings, or find code blocks across local markdown files.

## Available Tools

| Tool               | What it does                                                               |
| ------------------ | -------------------------------------------------------------------------- |
| `list_files`       | List all .md files in a directory recursively                              |
| `search_docs`      | Full-text search across all .md files (case-insensitive, up to 50 results) |
| `get_section`      | Extract a section by heading until the next heading of same/higher level   |
| `list_headings`    | List all headings as a table of contents                                   |
| `find_code_blocks` | Find fenced code blocks, optionally filter by language                     |
| `get_frontmatter`  | Parse YAML frontmatter metadata from a file                                |

## Workflow

1. `list_files` to discover documentation files in the project
2. `search_docs` for full-text search across all docs
3. `list_headings` to get the table of contents for a specific file
4. `get_section` to extract a specific section by its heading text
5. `find_code_blocks` to find code examples, optionally filtered by language

## Key Patterns

- `get_section` extracts everything under a heading until the next heading of same or higher level
- `find_code_blocks` with `language: "typescript"` filters to only TS examples
- `search_docs` is case-insensitive and returns up to 50 matches with surrounding context
- Unlike the filesystem MCP, this server understands markdown structure (headings, sections, code fences)
