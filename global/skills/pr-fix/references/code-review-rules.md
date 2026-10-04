# `## Code Review Rules` block for a target repository's AGENTS.md

The Codex GitHub reviewer (`chatgpt-codex-connector`) reads `AGENTS.md` from the **pull request head**, so a
rules section added in the PR itself applies to that PR's next review. Put repository-wide rules in the root
`AGENTS.md`; put component rules in the `AGENTS.md` closest to the component. Rules guide the reviewer's judgment.
The `pr-fix` runner checks recorded state. The author must also establish direct behavior evidence before
publication; neither reviewer rules nor a `ready` status establish that the checks exercise the change.

Paste and adapt:

```markdown
## Code Review Rules

### Scope
- Review only lines changed in this pull request. Report pre-existing problems in unchanged code as a
  single note at the end, not as inline findings.
- Treat changed workflow instructions as behavior. Trace affected callers and downstream consumers for
  context, including command ordering and state changes; keep findings tied to defects introduced by the diff.
- Report P0 and P1 only when you can name the concrete input, environment or call path that triggers the
  failure. Do not report style, naming, formatting, speculative hardening or alternative designs.
- One finding per root cause. If a guard or validator has a class of bypasses, report the class once with
  two examples. Do not report a root cause that already has a reply on this pull request.

### Best-effort guards
- Components documented as best-effort tripwires (not security boundaries) are reviewed against their
  documented coverage list, not against every possible spelling of an input. Safe path: add the missing
  case to the coverage list and to its test table.
- Current best-effort components: <path/to/guard> (contract: <path/to/doc#section>).
```

Worked example from ocms-go PR 170: `dsh-git-guard/` is documented in `docs/dsh-onboarding.md` as *"a tripwire,
not a security boundary. A deliberately adversarial model could evade shell-string matching."* Under the rule
above, shell-string evasions (repository wrappers, here-strings, command substitutions, dashed `git-*`
executables) are known limitations to be replied to and resolved, while ordinary Git spellings (`--delete`,
option order, `remote rm`, global options such as `-C` and `--no-pager`) are defects to fix.

OpenAI's own measurement of custom review rules reported that rule-guided reviews recovered 98% of the findings
the rules asked for, against 58% without rules, so the reviewer does follow this section. Suppressing classes
of findings is plausible under the same mechanism but is not documented as guaranteed.
