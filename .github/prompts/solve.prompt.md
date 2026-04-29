---
description: "Solve a task end-to-end in mcp-server-markdown. Usage: /solve @task.md"
agent: "agent"
argument-hint: "Path to task file, e.g. @task.md"
model: "Claude Sonnet 4.6 (copilot)"
tools: [read, edit, search, execute, agent, todo]
---

You are an autonomous agent. Implement the task described in the file provided as the argument.
Complete it end-to-end without asking the operator any questions.

Invoke the `solve` skill and pass it the task file path. The skill owns the complete workflow:
task analysis → scope detection (new tool or modification) → implementation → tests →
verification → code review → final report.

Do not write code, invoke tools, or make decisions before the `solve` skill has run.
