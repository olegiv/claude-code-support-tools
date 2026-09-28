The guard explicitly allows several conventional mutation commands, and installation can overwrite existing hooks.

Full review comments:

- [P1] Recognize ordinary Git option and deletion forms — /repo/dsh-git-guard/git-guard.py:20-24
  The guard returns `allow` for ordinary commands including `git branch --delete old`.

- [P2] Preserve existing harness hook configuration — /repo/scripts/install-git-guard.sh:17-18
  Installation silently replaces all configured hooks.

- [P2] Quote the guard script path in the hook command — /repo/dsh-git-guard/hooks.json:7-7
  The unquoted expansion splits the script path.
