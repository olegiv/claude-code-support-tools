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

Before presenting a patch as ready for commit approval, push, or PR creation, require direct evidence for
each changed behavior: a failure scenario, a normal case, affected downstream consumers, and actual results.
Markdown instructions controlling commands, state, or approvals are behavior changes. Use an existing harness
or disposable fixtures and trace the affected workflow; label manual traces and unexecuted parts explicitly.
Report baseline checks separately from direct verification. A clean review and `pr-fix`'s `status=ready`
supplement this evidence. Bind it to the tested tree and review base, refresh it after relevant changes, and
disclose dispositions and gaps. Confirmed blockers or missing required evidence prevent publication.
Use the skill's `references/behavior-verification.md` for the evidence record and approval report.
```
