# Repository instructions

This repository ships scripts and Markdown instructions for developer workflows.
Read `CLAUDE.md` for its structure and documented checks. A Markdown change that
controls commands, state, approvals, or execution is a behavior change.

## Behavior verification before publication

Before presenting a patch as ready for commit approval, push, or PR creation:

1. Map each changed behavior or FIX finding to its failure scenario, correction,
   and direct evidence. Include a normal case that must still work.
2. Trace the changed step through its callers and subsequent consumers, within
   the affected workflow. Check ordering, state changes, and failure paths.
3. Exercise relevant scenarios with the existing harness or disposable fixtures.
   For instruction changes, trace the complete command sequence and its decisions;
   check command semantics in a disposable repository where needed. Record any
   unexecuted part and do not claim it was tested.
4. Report baseline regression checks separately from checks of the changed
   behavior. A clean independent review supplements direct evidence.
5. Bind evidence to the candidate tree, review base, and relevant environment.
   Refresh affected evidence after changes. Report each finding's disposition;
   unresolved blockers or missing required evidence prevent publication.

Use `global/skills/pr-fix/references/behavior-verification.md` for the evidence
record and readiness report. Pure wording/formatting edits need only an
appropriate structural check. Do not add test infrastructure or broaden a review
to unrelated code merely to satisfy this gate.

For PR findings, use `$pr-fix` and preserve its scope, P2 rule, approval requirements,
and review/push limits. Its runner's `status=ready` verifies recorded bookkeeping;
the author must also satisfy the behavior-verification gate before publishing.
