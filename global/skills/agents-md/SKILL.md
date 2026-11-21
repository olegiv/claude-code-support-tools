---
name: agents-md
description: Organize a project's agent instruction files so Claude Code and Codex follow one copy - shared instructions in AGENTS.md, and a CLAUDE.md that imports it with `@AGENTS.md` and adds only Claude Code-specific notes. Use when asked to set up, migrate, merge, deduplicate or check a project's CLAUDE.md and AGENTS.md, to make a project's instructions work for both Claude Code and Codex, or when a project keeps its shared instructions only in CLAUDE.md. Project files only, not ~/.claude or ~/.codex.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# agents-md: one set of project instructions for Claude Code and Codex

## Target layout

```text
AGENTS.md   shared instructions: purpose, structure, build/test/lint commands,
            conventions, review rules, workflows
CLAUDE.md   "@AGENTS.md" on its own line, then only Claude Code-specific notes
```

Claude Code reads `CLAUDE.md` and loads each `@path` import in full. Codex reads
`AGENTS.md` and does not follow `@` imports. So the shared copy has to be
`AGENTS.md`, and `CLAUDE.md` imports it.

## Rules

- Change nothing until the user approves the plan in step 3. A committed
  `CLAUDE.md` belongs to everyone who works on the repository.
- Move text, don't rewrite it. Moved content stays word for word, apart from the
  title and references to the file it moved out of.
- Never commit or push. The global commit and test-gate rules apply afterwards.
- Do not edit CI files (`.github/workflows/`, `.gitlab-ci.yml` and similar)
  unless the user approves that file by name. List them in the report instead.
- Leave `CLAUDE.local.md`, `.claude/settings*.json` and user-level files
  (`~/.claude/`, `~/.codex/`) alone.

## 1. Inspect

From the repository root:

```bash
git ls-files -co --exclude-standard | grep -E '(^|/)(AGENTS|CLAUDE)\.md$'
ls -la CLAUDE.md AGENTS.md .claude/CLAUDE.md 2>/dev/null
```

Classify the root, then each subdirectory that has either file:

| State | Signs | Action |
|---|---|---|
| A. Done | `CLAUDE.md` has the import line and no shared content | Only run steps 5 and 6 |
| B. Symlink | `CLAUDE.md -> AGENTS.md` | Already one copy. Replace the link with an importing file only if the user wants Claude Code-only notes or has Windows contributors |
| C. `CLAUDE.md` only | No `AGENTS.md` | Move the shared content into a new `AGENTS.md` |
| D. `AGENTS.md` only | No `CLAUDE.md` | Create `CLAUDE.md` with the import |
| E. Both have content | Shared text in both | Merge into `AGENTS.md` |
| F. Neither | | Offer to create both |

- `.claude/CLAUDE.md` is another place Claude Code reads project instructions
  from. Imports resolve relative to the importing file, so there the line is
  `@../AGENTS.md`. Keep shared content in one of the two Claude files, not both.
- Nested directories: Claude Code loads a subdirectory's `CLAUDE.md` when it
  works on files there, and Codex reads `AGENTS.md` files from the repository
  root down to its working directory. Use the same layout in each directory.

## 2. Sort the content

Read every instruction file in full and sort each section:

- **Shared, goes to `AGENTS.md`:** anything any agent working on the repository
  needs. That includes descriptions of the repository's own `.claude/` agents,
  commands and skills, because they are part of its structure.
- **Claude Code only, stays in `CLAUDE.md`:** instructions only Claude Code can
  act on, such as "run `/foo` before committing", "use the X subagent for Y",
  or notes about its hooks, plan mode or `/memory`.
- **`@` imports already in `CLAUDE.md`:** Codex cannot follow them. Inline a
  short imported file into `AGENTS.md`. For a long one, keep the `@path` line in
  `CLAUDE.md` and add a plain-text pointer to `AGENTS.md` ("Read
  `docs/testing.md` before changing tests"). Never make an `@` import inside
  `AGENTS.md` the only route to shared text: Claude Code expands it, Codex sees
  only the literal line.
- **Duplicates (state E):** keep one copy in `AGENTS.md`. When the files
  disagree, for example on the test command, stop and ask which one is right.

## 3. Plan and approval

Show the user, then wait for approval:

- the layout per directory, which sections move to `AGENTS.md` and which stay
  in `CLAUDE.md`, and why
- each conflict that needs their decision
- the step 5 files you will change, and those you will only report
- the expected size of `AGENTS.md` against the Codex limit (step 6)

## 4. Write the files

`AGENTS.md` starts with this note, followed by the moved content in its original
order:

```markdown
# AGENTS.md

Shared instructions for coding agents working in this repository. Codex and other
agents read this file directly; Claude Code loads it through the `@AGENTS.md`
import in `CLAUDE.md`. Keep shared instructions here, and put only Claude
Code-specific notes in `CLAUDE.md`.
```

`CLAUDE.md` becomes:

```markdown
# CLAUDE.md

@AGENTS.md

## Claude Code notes

- Shared instructions are in `AGENTS.md`, imported above. Document structure,
  tools, tests and workflows there, not here.
```

followed by any Claude Code-only sections from step 2. Drop the old file's
generic intro line, such as "This file provides guidance to Claude Code...":
the new header replaces it. The import has to be on its own line, outside code
spans and fenced blocks, where Claude Code ignores it. Create new files with
mode 644.

## 5. Update the tools that write `CLAUDE.md`

```bash
git grep -nE 'CLAUDE\.md' -- ':!CLAUDE.md' ':!AGENTS.md' ':!CHANGELOG*'
```

Decide for each hit:

- **Writes or updates the project's docs** (doc-sync agents, scaffolding
  commands that say "update README.md and CLAUDE.md", release checklists,
  CONTRIBUTING): point it at `AGENTS.md`.
- **Reads the project's rules or commands from the file** ("use the test command
  `CLAUDE.md` names"): point it at `AGENTS.md`, falling back to `CLAUDE.md`.
- **CI prompts** such as "use the repository's CLAUDE.md": these keep working,
  because Claude Code loads the import. Leave them unless the user approves.
- **User-level files, other projects or Claude Code in general:** leave them.

## 6. Verify

Run each check and report its command and result. Label any check you could not
run; never report it as passed.

1. **Nothing lost.** Diff the old files (`git show HEAD:CLAUDE.md`,
   `git show HEAD:AGENTS.md`) against the new ones. Every hunk must be the
   header, a reference change you listed, or a section kept in `CLAUDE.md`.
2. **Import line.** `grep -nxE '@(\.\./)?AGENTS\.md' CLAUDE.md .claude/CLAUDE.md`
   prints it, and it is not inside a fenced block.
3. **Claude Code loads `AGENTS.md`** (if `claude` is on PATH). Run this from the
   directory holding `CLAUDE.md`, not from a temporary directory, where Claude
   Code may not load project instructions. Pick a heading near the end of
   `AGENTS.md`:

   ```bash
   claude -p 'Answer only from the project instructions already in your context. Do not use any tools. Quote verbatim the first line under the heading "HEADING". If it is not in your context, reply exactly NOT LOADED.' \
     --disallowedTools "Bash Read Grep Glob Edit Write NotebookEdit WebFetch WebSearch Agent Skill" \
     --output-format json | jq -r '.result'
   ```

   The quoted line must match the file. `NOT LOADED` means the import failed.
4. **Codex reads all of `AGENTS.md`** (if `codex` is on PATH). Ask the same
   question about the last heading in the file:

   ```bash
   codex exec --sandbox read-only --json 'Answer only from the AGENTS.md instructions already in your context. Do not run any commands or read any files. Quote verbatim the first line under the heading "HEADING". If it is not in your context, reply exactly NOT LOADED.' \
     | jq -r 'select(.item.type? == "agent_message") | .item.text'
   ```

   A wrong answer or `NOT LOADED` for the last heading means the file was cut
   short.
5. **Size.** `wc -c AGENTS.md`. Codex reads at most `project_doc_max_bytes` of
   project instructions, 32 KiB by default; check `~/.codex/config.toml` for an
   override. Above about 28 KiB, warn the user. Above the limit, propose moving
   component rules into `AGENTS.md` files in those directories.

## 7. Report

- each directory's state before and after, and the files changed
- the step 6 results, with commands, and any check not run
- the consumers changed, and those left alone with the reason
- the size of `AGENTS.md` and the headroom left
- that nothing was committed
