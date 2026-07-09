# AGENTS.md

Project-specific guidelines for coding agents working on FoliBusAPI.

---

## Skills

Always load relevant skills before starting work. Use the skill name to load via `/skill:<name>` or read the SKILL.md directly.

- **swift-api-design-guidelines-skill** — Use when designing, reviewing, or renaming APIs. Read the `references/` subdirectory for detailed guidance on naming, argument labels, documentation, and conventions.
- **documentation** — Use when writing or improving documentation, DocC articles, README files, or code comments.
- **swift-concurrency-pro** — Use when reviewing or writing Swift concurrency code (async/await, actors, Sendable).
- **swiftui-pro** — Use when working on the FoliBusUI SwiftUI layer.
- **xcodebuildmcp-cli** — Use when doing iOS/macOS build, test, run, debug, or UI automation work.

Read the skill file at the start of the task, not partway through. Skills contain decision trees and checklists that shape the approach.

---

## Multi-model exploration

When auditing, reviewing, or investigating code, **use multiple models in parallel** to get diverse perspectives. Different models catch different issues.

Pattern:
1. Divide the work into logical segments (e.g., by module, by concern)
2. Launch parallel subagents, each with a different model
3. Collect results and deduplicate
4. Pass single-agent findings to a different model for cross-verification

This catches false positives and surfaces issues that any single model would miss.

**Available models** (check current availability — these may change):
- `opencode-go/deepseek-v4-flash` — fast, cheap, good for execution and verification
- `opencode-go/deepseek-v4-pro` — stronger reasoning
- `opencode-go/kimi-k2.7-code` — code-focused
- `opencode-go/qwen3.7-max` — expensive, strong for analysis/writing, **avoid for pure execution**

---

## Planning and review

**Always prompt for review before executing plans.** Present the plan, explain trade-offs, ask questions about preferences and constraints. Don't assume — ask.

For breaking changes specifically:
- Explain what changes and why
- Ask whether the rename/behavior change is worth the consumer migration cost
- Confirm naming preferences (don't pick names unilaterally)
- Ask about downstream usage and blast radius

---

## Execution strategy

Use **cheap models for execution** of pre-planned work. If the plan is already approved and the task is mechanical (renames, adding doc comments, applying patterns), use `deepseek-v4-flash`.

| Task type | Model | Rationale |
|-----------|-------|-----------|
| Exploration / audit | Multiple models (parallel) | Diverse perspectives catch more issues |
| Analysis / writing | `qwen3.7-max` or `kimi-k2.7-code` | Strong reasoning for reports and articles |
| Execution of approved plans | `deepseek-v4-flash` | Fast, cheap, sufficient for mechanical work |
| Complex implementation | `deepseek-v4-pro` or `kimi-k2.7-code` | When execution requires judgment |

**Do not use `qwen3.7-max` for pure execution tasks** — it's expensive and overkill for mechanical work. Reserve it for analysis, writing, and tasks that benefit from stronger reasoning.

---

## XcodeBuildMCP

If using XcodeBuildMCP, load the installed XcodeBuildMCP skill before calling XcodeBuildMCP tools.
