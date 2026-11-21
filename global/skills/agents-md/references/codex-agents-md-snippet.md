# Paragraph for `~/.codex/AGENTS.md`

Append once. It mirrors the `## Project Instruction Files` section of the global Claude
`CLAUDE.md`, so both tools keep project instructions in the same layout.

```markdown
## Project instruction files

Keep one copy of a project's agent instructions. `AGENTS.md` holds the shared instructions:
purpose, structure, build/test/lint commands, conventions and workflows. `CLAUDE.md` starts
with `@AGENTS.md` and adds only Claude Code-specific notes. When you add or change a project's
shared instructions, edit `AGENTS.md`, never `CLAUDE.md`, and never reach shared text only
through an `@` import: Codex does not follow imports. If a project keeps its instructions only
in `CLAUDE.md`, read that file before working, because Codex does not load it, and follow it
where it is. Suggest the `$agents-md` skill to migrate, and migrate only with the user's
approval: a committed `CLAUDE.md` belongs to the whole team.
```
