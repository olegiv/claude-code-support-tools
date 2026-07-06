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

Validate and use the project's deploy script with any flags from `$ARGUMENTS`:
```bash
# Validate arguments contain only safe characters
if printf '%s' "$ARGUMENTS" | grep -qE '[][;|&`$(){}!<>\\#*?~]'; then
  echo "ERROR: Arguments contain forbidden shell characters"
  exit 1
fi
# Block quote characters (prevent string escaping attacks)
if printf '%s' "$ARGUMENTS" | grep -qF '"' || printf '%s' "$ARGUMENTS" | grep -qF "'"; then
  echo "ERROR: Arguments contain forbidden quote characters"
  exit 1
fi
# Block newlines
if [ "$(printf '%s' "$ARGUMENTS" | wc -l)" -gt 0 ]; then
  echo "ERROR: Arguments must be single-line"
  exit 1
fi
./.fly/scripts/deploy.sh "$ARGUMENTS"
```

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

3. Extract the app URL and verify it responds:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" "https://$(grep '^app ' fly.toml | awk -F\"' '{print $2}').fly.dev/health"
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
