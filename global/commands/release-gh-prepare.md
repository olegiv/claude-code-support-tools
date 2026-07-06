---
allowed-tools: ""
argument-hint: "[version]"
description: "Cut a new version: update CHANGELOG, commit, push, and create a GitHub draft release. Mandatory user approval of the version."
---

# release-gh-prepare

Prepare a new GitHub **draft** release for the current project. Drafts the
release notes from the commits since the last tag, lets the user pick the
version, writes the notes under a new `## [X.Y.Z] - YYYY-MM-DD` heading in
`CHANGELOG.md`, commits, pushes, and creates the draft via `gh`.

**This command does NOT publish the release.** The GitHub UI "Publish
release" button — and therefore the git tag creation — is deliberately
left to the user.

Optional argument: a version override like `0.12.0` or `v0.12.0`, passed
as `$ARGUMENTS`. If provided, the version-selection question in Step 3 is
skipped and the value is used as the release version (still subject to the
content-approval gate in Step 5).

**Validate `$ARGUMENTS` before using it anywhere.** If it is non-empty it
MUST match the regex `^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$` exactly
(optional leading `v`, then `MAJOR.MINOR.PATCH`, optional `-prerelease`).
If it does not match, abort immediately and ask the user for a valid
version — never pass an unvalidated argument to `git` or `gh`. In
particular, reject any value beginning with `-` (e.g. `--generate-notes`):
it must never be forwarded where a CLI could parse it as a flag.

## Hard preconditions — abort if any fails

Before any edit or git action:

1. The current branch is the project's default branch. Resolve it via:
   - `git symbolic-ref --short refs/remotes/origin/HEAD` (returns
     `origin/<branch>`; strip the prefix). Fast path; works on any
     clone where `origin/HEAD` is set.
   - Fallback: `gh repo view --json defaultBranchRef --jq
     .defaultBranchRef.name`.
   - If both fail, abort with a message asking the user to run
     `git remote set-head origin --auto` and retry.

   Call the resolved name `<default-branch>`. If the current branch
   does not match it, or if HEAD is detached — abort with a message
   naming the resolved default and explaining that this command
   releases off the default branch only.
2. `git status --porcelain` is empty (no uncommitted or untracked
   changes).
3. The current branch is in sync with `origin/<default-branch>` (no
   unpushed commits and no unpulled commits from origin).
4. `CHANGELOG.md` exists at the repository root.
5. There is at least one commit on `<default-branch>` since the last
   release tag. If `git log <last-tag>..HEAD` is empty, there is
   nothing to release — abort.
6. `gh auth status` succeeds and the repository has an `origin`
   remote pointing to github.com.

If any precondition fails, report which one and stop — do not prompt
for recovery and do not attempt partial progress.

**Note on `[Unreleased]`:** This command does NOT require the
`[Unreleased]` section in `CHANGELOG.md` to be populated. It drafts
release notes directly from the commit history. An empty `[Unreleased]`
stub is the expected shape between releases and stays empty after this
command runs (no populate/rename dance).

## Step 1 — read state

Capture:

- Latest released version: from the top compare-link row
  (`[X.Y.Z]: …compare/vA...vX.Y.Z`) at the bottom of `CHANGELOG.md`,
  OR from `git describe --tags --abbrev=0` as a fallback.
- Commits since the last tag: `git log <last-tag>..HEAD --oneline`.
  Follow up with `git show --stat <sha>` for any commit whose
  one-liner is ambiguous, and `gh pr view <N>` for any merge commit
  or PR-associated commit so you can synthesize user-facing impact.
- GitHub owner/repo: parse from `gh repo view --json
  nameWithOwner --jq .nameWithOwner`.
- Today's date in `YYYY-MM-DD` (use `date +%Y-%m-%d`, never hardcode).

Explicitly categorize each commit:
- **User-facing** (goes into release notes): new features, changed
  behavior, bugfixes, security fixes, dependency bumps that affect
  the shipped binary, docs changes that operators read.
- **Internal** (omitted): wiki submodule bumps, shared Claude
  submodule bumps, CLAUDE.md docs-index tweaks, slash-command
  symlinks, merge commits with no substantive delta of their own.

## Step 2 — draft release notes

Produce a Keep-a-Changelog-style draft organized into
`### Added / ### Changed / ### Fixed / ### Security / ### Removed /
### ⚠️ Breaking Changes` as warranted. Group with `#### Component`
subheadings (match the style of prior releases in this CHANGELOG.md).

Rules:
- Focus on WHAT and WHY from the user/operator perspective, not how.
- Reference security audit finding IDs (FIND-xxx, SEC-xxx) when a
  commit closes one — the user tracks these.
- Mention new config/env vars by name (e.g. `OCMS_HSTS_PRELOAD`).
- Omit internal churn per Step 1.
- Each code-level security fix should note if it ships with a drift
  test (when the commit body or audit report says so).

## Step 3 — propose version via AskUserQuestion

Offer 2–3 version options based on the drafted notes:

- **Major bump** if the draft has `### ⚠️ Breaking Changes` or a
  removed public surface that is not scoped to internal API only.
- **Minor bump** if `### Added` has any user-facing bullets (new
  public API, new feature, new scope).
- **Patch bump** if the draft is only `### Fixed` / `### Security` /
  `### Changed` bullets with no new surface.

Present options via AskUserQuestion with concise reasoning attached
to each option. Recommended choice first with "(Recommended)" suffix
if one is clearly right. Let the user pick, override with a version
string, or cancel.

**Never** skip this step. Even if the bump is obvious, the user's
version-choice authority is not delegated. If the user passed a
version argument to the command, use the validated `$ARGUMENTS` (it
must already have passed the format check above) and skip the
question.

## Step 4 — infer release title

From the drafted notes, take the first bullet of the top `#### …`
subgroup under `### Added` (or the first bullet overall if there is
no Added section). Strip bold markers and trailing punctuation, trim
to ~50 characters at a clause boundary so the full `vX.Y.Z — …`
string stays under ~70 chars.

Fallback order: first Added bullet → first bullet of any section →
`vX.Y.Z` alone with no subtitle.

**Sanitize the subtitle.** It is synthesized from commit messages and
`gh pr view` output — attacker-influenceable in a repo that accepts
outside contributions — and lands inside a shell-quoted `--title` value
in Step 9 (`gh release create` has no `--title-file` option). Strip any
`"`, `` ` ``, `$`, and `\` from the subtitle before composing the title.
The `vX.Y.Z` prefix is already format-validated; only the free-text
subtitle needs stripping.

Always let the user override the title in Step 5's content-approval
gate.

## Step 5 — MANDATORY content-approval gate

Present a single compact message with:

- **Proposed version:** `vX.Y.Z` (previous: `vA.B.C`).
- **Proposed title:** `vX.Y.Z — <subtitle>`.
- **Release notes draft:** the full `### Added / ### Changed / …`
  block as it will land in `CHANGELOG.md` and the release body.
- **Ask:** "Accept, adjust the title, request edits to the notes, or
  cancel?"

Wait for the user. Accept any of:
- "yes" / "accept" / "proceed" → continue with the proposal.
- A title override → use it instead.
- Edit instructions → revise notes and re-present.
- "cancel" / "no" / anything negative → stop without side effects.

Never assume approval from silence. Never interpret ambiguity as
"proceed" — if the response is unclear, ask again rather than acting.

## Step 6 — update CHANGELOG.md

Two edits to one file. No other files touched.

1. **Insert a new section directly below the existing `[Unreleased]`
   stub.** Leave the `## [Unreleased]` header and its empty body
   alone — it is Keep-a-Changelog convention and stays as a stub
   between releases. Insert between the blank line after
   `## [Unreleased]` and the previous release's heading:

   ```markdown
   ## [X.Y.Z] - YYYY-MM-DD

   <the approved release notes from Step 5>

   ```

2. **Update the compare-link block at the bottom:**
   - Rewrite the existing `[Unreleased]: …compare/vA.B.C...HEAD`
     line to `[Unreleased]: …compare/vX.Y.Z...HEAD`.
   - Insert a new line directly under it:
     `[X.Y.Z]: …compare/vA.B.C...vX.Y.Z`.

Do NOT rename `[Unreleased]`. Do NOT delete anything. The resulting
diff should be `N insertions, 1 deletion` where N is the size of the
inserted section plus the one new compare-link row.

## Step 7 — commit gate

Show `git diff --stat CHANGELOG.md` and the first 30 + last 10 lines
of `git diff CHANGELOG.md` so the user can sanity-check the edit
landed as planned.

Draft commit message:

```
Cut vX.Y.Z

Add [X.Y.Z] section to CHANGELOG with release notes and update the
compare-link block. No code changes; the version string is derived
from the git tag at build time.
```

Adjust the second paragraph if the project's version string comes
from somewhere other than the git tag (check `Makefile`, `setup.py`,
`Cargo.toml`, `package.json`, etc. — mention the adjustment, but do
NOT auto-edit those files).

Ask: "Should I proceed with this commit?" Wait for explicit "yes".

When committing, use `git commit --no-verify` per the user-explicit-
commit convention (projects with a pre-commit hook that blocks
automated commits allow them when the user explicitly requests it).

## Step 8 — push gate

After the commit succeeds, ask: "Should I push to
`origin/<default-branch>`?" Wait for explicit "yes". Shared-state
change; silent execution is forbidden.

## Step 9 — create GitHub draft release

Once pushed, get the full SHA and write the release body to a temp
file so `gh` does not shell-interpolate:

```bash
FULL_SHA=$(git rev-parse HEAD)
NOTES_FILE=$(mktemp "${TMPDIR:-/tmp}/<repo>-<version>-notes.XXXXXX")
```

Use the positional `mktemp` template form (portable across macOS BSD and
GNU); it creates the file atomically with restrictive permissions, so it
cannot be pre-planted via a predictable path or hijacked by a symlink.

Write the release body to `$NOTES_FILE`:
- A one- to two-sentence opening blurb synthesized from the top
  bullet (mirroring what the release title communicates, expanded).
- The full `[X.Y.Z]` content (the release-notes block from Step 2,
  WITHOUT the `## [X.Y.Z] - YYYY-MM-DD` heading itself).
- A trailing `**Full changelog:**
  https://…/compare/vA.B.C...vX.Y.Z` line.

Then:

```bash
gh release create \
  --draft \
  --target "$FULL_SHA" \
  --title "vX.Y.Z — <subtitle>" \
  --notes-file "$NOTES_FILE" \
  -- vX.Y.Z
```

Notes:
- The `--` before `vX.Y.Z` ends option parsing so the tag can never
  be misread as a flag (defense in depth on top of the version-format
  check). `gh release create` takes positional args
  (`[<tag>] [<files>...]`), so `--` must come **after** all flags,
  with the tag as the final positional.
- Pass the **full 40-char SHA** to `--target`. Short SHAs are
  rejected by the GitHub API with `target_commitish is invalid`.
- Prefer `--notes-file` over `--notes "<body>"` — keeps shell
  quoting out of the release body and avoids `$`/backtick
  interpolation in inline code samples.
- Do NOT pass `--generate-notes`. The curated CHANGELOG is the
  source of truth.
- The git tag `vX.Y.Z` will NOT exist yet. Draft releases can
  reference a commit SHA directly; the tag is created only when the
  user publishes from the GitHub UI.

Clean up with `rm -f "$NOTES_FILE"` after `gh release create` — and also
on failure, so the temp file never leaks.

## Step 10 — verify and report

Run:

```bash
gh release view vX.Y.Z --json name,tagName,isDraft,targetCommitish,url
git tag -l vX.Y.Z   # expect empty output
```

Confirm `isDraft: true`, `targetCommitish` matches the full SHA from
step 8, and no local `vX.Y.Z` tag exists. Report:

- Commit SHA on `<default-branch>`.
- Draft release URL (from `.url` in the JSON). Note the URL contains
  `untagged-<hash>` until published.
- Reminder: "Review in the GitHub UI and click **Publish release**
  when ready. Publishing creates the `vX.Y.Z` tag."

## Error recovery

If Step 9 fails after Step 8 has pushed the CHANGELOG commit:

- Do NOT force-push, do NOT reset. The commit is already on
  `origin/<default-branch>` and other users may have pulled it.
- Report the exact error and the commit SHA.
- Suggest a manual retry: `gh release create --draft --target <sha>
  --notes-file <path> -- vX.Y.Z`.

If the user cancels at the content-approval gate in Step 5, exit
cleanly with no file changes and no git operations performed.

## What this command does NOT do

- Publish the release. That button stays in the user's hands.
- Create the git tag. Publishing the draft release creates the tag.
- Rename or delete the `[Unreleased]` stub. It stays empty.
- Populate `[Unreleased]` as an intermediate step. The command writes
  a new `[X.Y.Z]` section directly; no populate-then-rename churn.
- Update other files (Makefile version strings, Cargo.toml version,
  package.json version, etc.). If the project pins its version
  outside of the git tag, warn the user during the Step 7 commit
  gate but do not auto-edit.
- Write a `.github/release.yml` auto-notes config. The curated
  CHANGELOG body is the deliberate choice; do not introduce
  generate-notes as a fallback.
- Run tests, linters, or vulnerability scans. Those belong in CI
  and in the user's separate `/test`, `/lint`, `/security-audit`
  workflows. This command assumes `<default-branch>` HEAD is already
  clean.
