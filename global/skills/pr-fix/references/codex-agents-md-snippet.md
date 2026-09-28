# Paragraph for `~/.codex/AGENTS.md`

Append once (outside any managed block). It mirrors the `## PR Review Findings` section of the global Claude
`CLAUDE.md`, so both tools follow the same rules.

```markdown
## Pull-request review findings

When asked to fix, address, check, or re-check pull-request review findings (Codex connector or other review
bots), invoke `$pr-fix`. It fixes only what a thread names, runs `codex exec review --base` locally once before
pushing, and allows at most two fix pushes per pull request; after that it triages (reply, resolve, defer) and
stops unless the user says `override`. A P2 finding gets a one-line fix or a reply, never a rewrite. Do not
invoke `$full-branch-audit` or any whole-repository audit as part of a findings fix; it is for explicit
whole-checkout audits only.
```
