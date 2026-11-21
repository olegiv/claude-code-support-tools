# Paragraph for `~/.codex/AGENTS.md`

Append once. It mirrors the `## Project Instruction Files: AGENTS.md and CLAUDE.md` section of
the global Claude `CLAUDE.md`, so both tools keep project instructions in the same layout.

```markdown
## Project instruction files

Keep one copy of a project's agent instructions. `AGENTS.md` holds the shared instructions:
purpose, structure, build/test/lint commands, conventions and workflows. `CLAUDE.md` starts
with `@AGENTS.md` and adds only Claude Code-specific notes.

- Edit the file that holds the shared instructions. In a project that uses this layout, that is
  `AGENTS.md`: never copy shared instructions into `CLAUDE.md`, and never make an `@` import
  inside `AGENTS.md` the only route to shared text, because Codex does not follow imports. In a
  project not yet migrated, edit the file that holds the instructions until it is migrated.
- When asked to write project instructions for a project that has neither file, create both in
  this layout.
- Codex does not load `CLAUDE.md` by default. If a project's `CLAUDE.md` holds anything besides
  the `@AGENTS.md` import and Claude Code-only notes, read it before working: its rules apply
  too. If the two files name different commands for the same task, ask which one is right.
- Don't restructure a project unasked: suggest the `$agents-md` skill, and migrate only with the
  user's approval, because a `CLAUDE.md` in a repository belongs to the whole team.
```
