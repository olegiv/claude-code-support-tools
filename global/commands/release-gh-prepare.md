---
allowed-tools: ""
description: "Cut a new version: update CHANGELOG, commit, push, and create a GitHub draft release. Mandatory user approval of the version."
---

# release-gh-prepare

Prepare a new GitHub **draft** release for the current project. Updates
`CHANGELOG.md`, commits, pushes, and creates the draft via `gh`.

**This command does NOT publish the release.** The GitHub UI "Publish
release" button — and therefore the git tag creation — is deliberately
left to the user.

Optional argument: a version override like `0.12.0` or `v0.12.0`. If
provided, the auto-inference step is skipped and the argument is used
as the proposed version (still subject to the mandatory approval gate).

## Hard preconditions — abort if any fails

Before any edit or git action:

1. The current branch is `master`. If it is `main`, `dev`, a feature
   branch, or a detached HEAD — abort with a message explaining that
   this command releases off `master` only.
2. `git status --porcelain` is empty (no uncommitted or untracked
   changes).
3. The current branch is in sync with `origin/master` (no unpushed
   commits and no unpulled commits from origin).
4. `CHANGELOG.md` exists at the repository root, contains a
   `## [Unreleased]` heading, and the section under it is non-empty
   (has at least one `### ...` subsection with bullet content).
5. `gh auth status` succeeds and the repository has an `origin`
   remote pointing to github.com.

If any precondition fails, report which one and stop — do not prompt
for recovery and do not attempt partial progress.

## Step 1 — read state

Capture:

- Latest released version: from the top compare-link row
  (`[X.Y.Z]: …compare/vA...vX.Y.Z`) at the bottom of `CHANGELOG.md`,
  OR from `git describe --tags --abbrev=0` as a fallback.
- Unreleased section content: everything between `## [Unreleased]`
  and the next `## [` heading.
- GitHub owner/repo: parse from `gh repo view --json
  nameWithOwner --jq .nameWithOwner`.
- Today's date in `YYYY-MM-DD` (use `date +%Y-%m-%d`, never hardcode).

## Step 2 — infer proposed version

If the user supplied a version argument, use it verbatim (strip a
leading `v` and re-add it consistently). Otherwise apply semver to the
Unreleased content:

- **Major bump** if `BREAKING` appears anywhere in the Unreleased
  section AND the project's `go.mod` / `package.json` / equivalent
  does not scope the break as "internal API only". When in doubt,
  propose minor and surface the BREAKING tag in the rationale so the
  user can override to major.
- **Minor bump** if `### Added` has any bullets (new public API, new
  feature, new scope).
- **Patch bump** otherwise (only `### Fixed` / `### Security` /
  `### Dependencies` / `### Changed` with no new surface).

Compute the next version from the latest tag using the chosen bump.
Never propose a decrease or a skipped minor/patch unless the user's
override dictates it.

## Step 3 — infer release title

From the Unreleased section, take the first non-heading bullet line
that starts with bold text (`- **...**`). Strip the bold markers and
any trailing punctuation. That becomes the release subtitle.

- Example: `- **Finding exclusions now operate at prompt level, not
  as a post-filter.**` → title becomes `vX.Y.Z — Finding exclusions
  now operate at prompt level`.
- Trim the subtitle to ~50 characters at a clause boundary so the
  full `vX.Y.Z — ...` string stays under ~70 chars.
- If there is no bold bullet, fall back to the first plain bullet
  line. If that is also missing, use `vX.Y.Z` alone with no subtitle.

## Step 4 — MANDATORY approval gate

This step is NOT optional. Do not edit any file, do not run any
git-state-changing command until the user approves.

Present a single compact message with:

- **Proposed version:** `vX.Y.Z` (previous: `vA.B.C`).
- **Bump reason:** one sentence explaining which signal drove the
  bump (BREAKING, Added, only Fixed, etc.).
- **Proposed title:** `vX.Y.Z — <subtitle>`.
- **Release body source:** the `[Unreleased]` section content,
  verbatim, as it will appear in the draft.
- **Ask:** "Accept, override with a specific version like `0.12.0`,
  adjust the title, or cancel?"

Wait for the user. Accept any of these:

- "yes" / "accept" / "proceed" → continue with the proposal.
- A version string (`0.12.0`) → use it instead, recompute title.
- A title override → use it instead.
- "cancel" / "no" / anything negative → stop without side effects.

Never assume approval from silence. Never interpret ambiguity as
"proceed". If unsure, ask again.

## Step 5 — update CHANGELOG.md

1. Rename the existing `## [Unreleased]` heading to
   `## [X.Y.Z] - YYYY-MM-DD`.
2. Insert a fresh empty `## [Unreleased]` section above it. One
   blank line of separation.
3. At the bottom compare-link list:
   - Replace `[Unreleased]: …compare/vA.B.C...HEAD` with
     `[Unreleased]: …compare/vX.Y.Z...HEAD`.
   - Add a new line
     `[X.Y.Z]: …compare/vA.B.C...vX.Y.Z` directly under the
     `[Unreleased]` row.

No other edits. The existing Unreleased body is the release notes.

## Step 6 — commit gate

Show `git diff CHANGELOG.md` (expect ~5-line diff: heading rename,
new empty `[Unreleased]` block, two link-list rows).

Draft commit message:

```
Cut vX.Y.Z

Move [Unreleased] entries to [X.Y.Z] - YYYY-MM-DD and add the
compare link. No code changes; the version string is derived from
the git tag at build time.
```

Adjust the second line if the project's version string comes from
somewhere other than the git tag (check `Makefile`, `setup.py`,
`Cargo.toml`, `package.json`, etc. — mention the adjustment).

Ask: "Should I proceed with this commit?" Wait for explicit "yes".

## Step 7 — push gate

After the commit succeeds, ask: "Should I push to origin/master?"
Wait for explicit "yes". This is a shared-state change; silent
execution is forbidden.

## Step 8 — create GitHub draft release

Once pushed, get the full SHA:

```bash
FULL_SHA=$(git rev-parse HEAD)
```

Then:

```bash
gh release create vX.Y.Z \
  --draft \
  --target "$FULL_SHA" \
  --title "vX.Y.Z — <subtitle>" \
  --notes "<release body>"
```

Notes:

- Pass the **full 40-char SHA** to `--target`. Short SHAs are
  rejected by the GitHub API with `target_commitish is invalid`.
- The release body is the `[Unreleased]` content from before the
  CHANGELOG rename, with a one- or two-sentence opening blurb
  synthesized from the top bullet (mirroring what the release title
  communicates, expanded to 2 sentences). End the body with a
  `**Full changelog:** https://…/compare/vA.B.C...vX.Y.Z` line.
- Do NOT pass `--generate-notes`. The curated CHANGELOG is the
  source of truth.
- The git tag `vX.Y.Z` will NOT exist yet. Draft releases can
  reference a commit SHA directly; the tag is created only when the
  user publishes from the GitHub UI.

## Step 9 — verify and report

Run:

```bash
gh release view vX.Y.Z --json name,tagName,isDraft,targetCommitish,url
```

Confirm `isDraft: true` and `targetCommitish` matches the full SHA
from step 8. Report:

- Commit SHA on master.
- Draft release URL (from `.url` in the JSON). Note that the URL
  will contain `untagged-<hash>` until published.
- Reminder: "Review in the GitHub UI and click **Publish release**
  when ready. Publishing creates the `vX.Y.Z` tag."

## Error recovery

If step 8 fails after step 7 has pushed the CHANGELOG commit:

- Do NOT force-push, do NOT reset. The commit is already on
  origin/master and other users may have pulled it.
- Report the exact error and the commit SHA.
- Suggest a manual retry: `gh release create vX.Y.Z --draft
  --target <sha> …`.

If the user cancels at the approval gate in step 4, exit cleanly
with no file changes and no git operations performed.

## What this command does NOT do

- Publish the release. That button stays in the user's hands.
- Create the git tag. Publishing the draft release creates the tag.
- Update other files (Makefile version strings, Cargo.toml version,
  package.json version, etc.). If the project pins its version
  outside of the git tag, warn the user during step 6's commit-gate
  but do not auto-edit.
- Write a `.github/release.yml` auto-notes config. The curated
  CHANGELOG body is the deliberate choice; do not introduce
  generate-notes as a fallback.
- Run tests, linters, or vulnerability scans. Those belong in CI
  and in the user's separate `/test`, `/lint`, `/security-audit`
  workflows. This command assumes master HEAD is already clean.
