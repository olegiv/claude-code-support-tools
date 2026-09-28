# Triage rules, minimal-fix rules and state schema

## Dispositions

Every unresolved review thread gets exactly one disposition before the round's push. Record it with
`pr-fix.sh triage <thread> KIND --note "<one sentence>" [--file <path>]`.

| Severity of the thread | FIX | REJECT | DEFER | DUP |
|---|---|---|---|---|
| **P0 / P1** | Default. Fix within the defect family (see below). Where the project already has a test harness for the component, add a regression test that fails on the defective code and passes after the repair, plus a valid-input counterexample. | Only when the finding is disproven by reading or reproduction, contradicts the component's documented contract, or is pre-existing and outside the PR diff. Reply must say which. | Real, but its fix is outside the PR's scope. Open an issue, reply with the link, resolve. | Same root cause as another thread already dispositioned. Reply "Duplicate of <url>", resolve. |
| **P2** | **One-line fix only:** a single hunk of about five lines or fewer, no new files, no new structure. If it cannot be done in one hunk it is not a FIX. | Default when the one-line fix does not exist, when the change would be a refactor, or when the point is style, naming or a procedure nit. Reply with one sentence. | Same as above. | Same as above. |
| **P3 / nit** | Never. | Reply and resolve. | — | — |

**The P2 rule is the most important rule in this file.** P2s are the bulk of every findings loop (133 of 146 Go
findings in ocms-go's last 30 PRs; all 14 findings in claude-code-support-tools' last 30 PRs). Rewrites are how a
P2 turns into three new findings. A P2 gets a one-line fix or a reply, never a rewrite, refactor or new abstraction.
Rewrites happen only as an explicit user decision outside this workflow.

"Could not reproduce" is not a disposition. Either establish the reachable failure path and FIX, or show why the
path does not exist and REJECT with that reason.

## Minimal-fix rules

1. Every hunk in the commit maps to exactly one FIX thread id. The commit body lists `thread → file`. Hunks without
   a thread are forbidden; if you notice something else, it becomes a DEFER thread or a separate later change.
2. No new abstractions, no new files unless the finding is literally "this file is missing", no hardening beyond
   the named finding, no "while I'm here".
3. Map the defect family before editing a P0/P1: the violated contract, callers, alternate entry points,
   normalisation, supported input variants and failure paths. Fix the family once. Clarify an ambiguous
   guarantee by writing it down (code comment or doc) before extending a parser or validator.
4. **Denylist / pattern-guard rule.** Never patch the same guard twice in one PR. On the second bypass report,
   choose one: convert the guard to an allowlist or structural check in a single change (unknown input fails
   closed), or document its best-effort coverage next to the code and REJECT further bypass reports against that
   contract. A blocklist over an open-ended input language has no finite finished state; reviewers will always
   find one more spelling.
5. Tests: only where a harness already exists for that component; at most one focused test per fixed thread; never
   new test infrastructure inside a findings fix.
6. Checks: run only the project's declared test and lint commands, scoped to the touched code. Pre-existing failures
   are recorded with `pr-fix.sh check --note "<baseline reason>"`, never silenced and never "cleaned up" in this PR.

## Reply templates

Replies are posted through `pr-fix.sh close`; the text never touches a shell. Keep them to one or two sentences.

- FIX: `Fixed in <sha>: <what changed, one clause>.`
- FIX (already fixed in an earlier round): `Fixed in <sha> (round <k>).`
- REJECT (contract): `Not changing: <component> is documented as best-effort in <doc#section>; this case is outside its documented coverage. Tracking coverage changes separately.`
- REJECT (disproven): `Not changing: <one sentence why the path is unreachable / already guarded at <location>>.`
- REJECT (P2 nit): `Not changing: <one sentence>. Tracking style/procedure polish outside this PR.`
- DEFER: `Deferred to #<issue>: <one sentence>.`
- DUP: `Duplicate of <url>; handled there.`

## Round cap and triage-only mode

`round = max(connector passes with findings, logged pushes + 1)`. Round `k` answers connector pass `k`; pass 1 is
the PR as opened. Rounds 1 and 2 may push. Round 3 and later are triage-only: every unresolved thread is closed by
reply (FIX threads already fixed → "Fixed in …", the rest REJECT/DEFER/DUP), no code changes, and the user is
offered `override` for one more full round. `pr-fix.sh status` reports `escalation-required` once the cap is hit;
the report must name the remaining defect family and propose a smaller patch or a design change. Never certify
unresolved work to meet the target.

## Local review leftovers

After the second local review of a round nothing more is fixed. Remaining P0/P1 from that review are recorded with
`pr-fix.sh triage local REJECT|DEFER --note "<why>"`, which is what lets `status` reach `ready`.

## State schema (`.audit/pr-<N>/state.json`)

```json
{
  "pr": 170, "url": "…", "repo": "owner/name", "head": "sha", "base": "master", "head_ref": "branch",
  "connector_passes": 5, "pending": "false", "latest_connector_commit": "sha",
  "created": "ts", "updated": "ts",
  "threads": {
    "PRRT_…": { "path": "…", "line": 1, "prio": "P1", "title": "…", "body": "…", "author": "…", "url": "…",
                "created": "ts", "outdated": false, "unresolved": true, "first_seen_round": 1,
                "disposition": { "kind": "FIX", "note": "…", "file": "…", "round": 1, "ts": "…" },
                "closed": { "ts": "…", "reply_url": "…", "resolved": true } }
  },
  "pushes":  [ { "sha": "…", "tree": "…", "ts": "…", "round": 1 } ],
  "reviews": [ { "round": 1, "tree": "…", "merge_base": "…", "base": "master", "model": "configured",
                 "effort": "high", "started": "ts", "seconds": 105, "exit": 0,
                 "p0": 0, "p1": 1, "p2": 2, "p3": 0, "format": "text", "file": "…", "tokens": null,
                 "leftovers": { "kind": "REJECT", "note": "…", "ts": "…" } } ],
  "checks":  [ { "round": 1, "cmd": "make test", "exit": 0, "seconds": 42, "note": "", "tree": "…", "ts": "…" },
               { "round": 1, "cmd": null, "waived": "docs-only change", "tree": "…", "ts": "…" } ]
}
```

`round-<k>.md` is the human report rendered by `pr-fix.sh status --report`: the thread table with dispositions,
checks, local reviews (model, effort, seconds, priorities, tokens when available), pushes and the status block.
`last-local-review` holds one line: `tree= merge_base= base= ts= file= p0= p1= effort= exit=`.

## Readiness states

| State | Meaning | Next step |
|---|---|---|
| `incomplete` | a thread lacks a disposition, no check recorded this round, or a check failed without a baseline note | triage, run checks |
| `needs-fix` | no local review this round, or its P0/P1 are neither fixed nor recorded as leftovers | fix, re-run review, or `triage local` |
| `stale` | the working tree (or the merge base) differs from what the last review saw | re-run review |
| `ready` | everything above holds | commit, push once |
| `escalation-required` | pushes reached the cap, or both local reviews are used and P0/P1 remain | stop; report the defect family; ask for `override` |

A successful reviewer exit alone never yields `ready`.
