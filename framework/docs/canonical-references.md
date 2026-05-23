# Canonical external references

Main agent reviews these docs **before any planning** on a non-trivial change, per master CLAUDE.md §2. Don't assume — read.

These are stable upstream references for Claude Code, the Claude Agent SDK, and common integrations. Bookmark by topic, not URL — URLs change; topics don't.

---

## Claude Code (the CLI tool)

- [CLI Reference](https://code.claude.com/docs/en/cli-reference.md) — all command-line flags, subcommands, slash commands
- [Tool Reference](https://code.claude.com/docs/en/tools-reference.md) — every built-in tool (Read, Write, Edit, Bash, Glob, Grep, etc.)
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide.md) — workflow automation via hooks
- [Hooks Reference](https://code.claude.com/docs/en/hooks.md) — full hook specification
- [Slash Commands](https://code.claude.com/docs/en/commands.md) — defining custom slash commands

## Claude Agent SDK (Python)

- [Agent SDK — Python](https://code.claude.com/docs/en/agent-sdk/python.md) — top-level SDK overview
- [Cost and Usage Tracking](https://code.claude.com/docs/en/agent-sdk/cost-tracking.md)
- [Permissions for Agent SDK](https://code.claude.com/docs/en/agent-sdk/permissions.md)
- [Handle Approvals (User Input)](https://code.claude.com/docs/en/agent-sdk/user-input.md)
- [MCP integration](https://code.claude.com/docs/en/agent-sdk/mcp.md)
- [Run claude CLI programmatically via -p](https://code.claude.com/docs/en/agent-sdk/mcp.md)
- [Session Storage (External Stores)](https://code.claude.com/docs/en/agent-sdk/session-storage.md)
- [Custom Tools](https://code.claude.com/docs/en/agent-sdk/custom-tools.md)
- [Sub-agents](https://code.claude.com/docs/en/agent-sdk/subagents.md)
- [Structured Outputs](https://code.claude.com/docs/en/agent-sdk/structured-outputs.md)

## Common integrations

- [Discord Application Commands](https://docs.discord.com/developers/interactions/application-commands.md)
- [Discord Modals](https://docs.discord.com/developers/components/using-modal-components.md)
- [Discord Component Reference](https://docs.discord.com/developers/components/reference.md)

## Alternative tools (for reference)

- [Gemini CLI Docs](https://geminicli.com/docs/cli/cli-reference/)
- [Gemini 3 on CLI](https://geminicli.com/docs/get-started/gemini-3/)

---

## How to use this list

1. **Before planning a feature**: skim the relevant Claude Code / Agent SDK sections. The SDK has multiple ways to accomplish the same task (Task tool vs subagent vs custom tool); pick by reading.
2. **Before writing a brief**: confirm your assumptions about a tool's behaviour by reading the reference. Briefs that misstate tool behaviour produce coder confusion.
3. **Before claiming "the SDK doesn't support X"**: check. The SDK gains capabilities; an outdated assumption blocks valid implementations.

The pattern this list exists to prevent: **fabricating tool behaviour from memory**. If you don't know, read. Reading is cheaper than coder reverting wasted work.

## Adding to this list

Project-specific references (e.g. Stripe API for a payments project, Twilio for messaging) belong in the **project's** `docs/DESIGN.md` §References section, not here. This list is for tools the framework itself uses.
