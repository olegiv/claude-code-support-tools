---
description: "Deploy a Go application to Fly.io (--reset, --logs, or status)"
argument-hint: "[--reset | --logs | status]"
allowed-tools: Bash(fly *), Bash(docker info*), Bash(git status*), Bash(grep *), Bash(./.fly/scripts/deploy.sh*), Bash(curl -s -o /dev/null -w *), Bash(tail *)
---

Deploy a Go application to Fly.io.

**Parameter:** `$ARGUMENTS` - Options: `--reset` (reset database before deploy), `--logs` (show logs after deploy), `status` (check deployment status only)

## Prerequisites Check

1. Verify `fly` CLI is installed:
   ```bash
   fly version
   ```
   If not installed, tell the user to install it: `curl -L https://fly.io/install.sh | sh`

2. Verify `fly.toml` exists in the project root
   - If not found, stop and inform the user they need a `fly.toml` configuration

3. Verify user is authenticated:
   ```bash
   fly auth whoami
   ```
   If not authenticated, tell the user to run `fly auth login`

4. If a deploy script exists (`.fly/scripts/deploy.sh`) that uses local Docker, verify Docker is running:
   ```bash
   docker info > /dev/null 2>&1
   ```
   If Docker is not running, **stop immediately** and tell the user: "Docker is not running. Please start Docker Desktop and run `/fly-deploy` again."

## If `$ARGUMENTS` is "status"

Run status checks only (no deployment):
```bash
fly status
fly checks list
```
Report app status, machine state, and health check results.

## Step 1: Pre-Deploy Checks

1. Check for uncommitted changes:
   ```bash
   git status --porcelain
   ```
   If there are uncommitted changes, warn the user but don't block.

2. Extract app name from `fly.toml`:
   ```bash
   grep "^app " fly.toml
   ```

3. Verify the app exists on Fly.io:
   ```bash
   fly status
   ```
   If the app doesn't exist, inform the user to run `fly launch --no-deploy --copy-config` first.

## Step 2: Build and Deploy

**If a deploy script exists** (`.fly/scripts/deploy.sh`):

Run the project's deploy script with only the flags recognised from
`$ARGUMENTS`. `$ARGUMENTS` is substituted into this prompt before any shell
runs, so a shell-side check cannot protect the command that contains it.
Instead, decide the flags here, in prose, and type a fixed command:

1. Split `$ARGUMENTS` on whitespace. The only accepted tokens are `--reset`,
   `--logs` and `status`.
2. If any other token is present, stop and report
   `Unrecognised argument: <token>`; do not run the deploy script.
3. Compose the command from the recognised tokens only. The possible forms
   are:
   ```bash
   ./.fly/scripts/deploy.sh
   ./.fly/scripts/deploy.sh --reset
   ./.fly/scripts/deploy.sh --logs
   ./.fly/scripts/deploy.sh --reset --logs
   ```
   Never paste the raw `$ARGUMENTS` text into a command.

**If no deploy script exists**, deploy directly:

1. Build and deploy via Fly.io remote builder:
   ```bash
   fly deploy
   ```

2. If remote builder fails, try local Docker build:
   ```bash
   fly deploy --local-only
   ```

3. If `--reset` flag is present and a reset script exists:
   ```bash
   fly ssh console -C "/app/scripts/reset-demo.sh"
   fly machines restart
   ```

## Step 3: Post-Deploy Verification

1. Wait for deployment to complete (up to 60 seconds):
   ```bash
   fly status
   ```

2. Check health endpoint:
   ```bash
   fly checks list
   ```

3. Verify the app responds. Take the app name from the `app` line read in
   Step 1 (`fly.toml` may quote it with `'` or `"`) and type it into the URL:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" "https://<app-name>.fly.dev/health"
   ```

## Step 4: Report Results

Report:
- Deployment status (success/failure)
- App URL: `https://<app-name>.fly.dev`
- Health check status
- Machine info (region, memory, CPU)

If `--logs` flag is present or deployment had issues:
```bash
fly logs --no-tail | tail -30
```

## Troubleshooting

If deployment fails, check common issues:

1. **Volume not created:**
   ```bash
   fly volumes list
   ```
   If empty, suggest: `fly volumes create <name> --size 1 --region <region>`

2. **Secrets not set:**
   ```bash
   fly secrets list
   ```
   Check for required secrets (e.g., `OCMS_SESSION_SECRET`, session keys, API keys).

3. **Machine not starting:**
   ```bash
   fly logs --no-tail | tail -50
   ```
   Look for startup errors.

4. **Health check failures:**
   ```bash
   fly checks list
   ```
   Check if the health endpoint path in `fly.toml` matches the application's health route.
