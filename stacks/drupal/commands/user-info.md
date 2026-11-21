---
description: "Lookup user details and roles"
argument-hint: "<uid|email|username>"
allowed-tools: Bash
---

# User Information

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be one value of at most 254 characters: a numeric user ID (`^[0-9]+$`), an email address matching `^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+$`, or a username matching `^[a-zA-Z0-9_.][a-zA-Z0-9._-]*$` (no leading `-`). The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

Look up detailed information about a Drupal user.

## Arguments

- `$ARGUMENTS` - User ID (numeric), email address, or username

## Instructions

### 1. Validate Input
```bash
ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
if [ ${#ARGS} -gt 254 ]; then
  echo "ERROR: Input too long (max 254 characters)"
  exit 1
fi

# Validate input format: uid (numeric), email (with @), or username (safe chars)
INPUT="$ARGS"
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  : # numeric uid - safe
elif [[ "$INPUT" =~ @ ]]; then
  # email - allow standard email characters
  if ! printf '%s' "$INPUT" | grep -qE '^[a-zA-Z0-9._+@-]+$'; then
    echo "ERROR: Invalid email format"
    exit 1
  fi
else
  # username - alphanumeric, underscores, hyphens, dots; no leading hyphen
  # (a leading - would reach drush as an option)
  if ! printf '%s' "$INPUT" | grep -qE '^[a-zA-Z0-9_.][a-zA-Z0-9._-]*$'; then
    echo "ERROR: Invalid username format. Only alphanumeric, dots, hyphens, underscores; no leading hyphen."
    exit 1
  fi
fi
```

### 2. Identify User
```bash
ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
INPUT="$ARGS"

# Check if numeric (uid)
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  ./vendor/bin/drush user:information --uid="$INPUT" --format=yaml 2>&1
# Check if email
elif [[ "$INPUT" =~ @ ]]; then
  ./vendor/bin/drush user:information --mail="$INPUT" --format=yaml 2>&1
# Assume username
else
  ./vendor/bin/drush user:information --format=yaml -- "$INPUT" 2>&1
fi
```

### 3. Get User Roles
```bash
ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
# Escape for PHP single-quoted string context: \ -> \\, ' -> \'
PHP_SAFE_INPUT=$(printf '%s' "$ARGS" | sed "s/\\\\/\\\\\\\\/g; s/'/\\\\'/g")
./vendor/bin/drush php:eval "
  \$input = '$PHP_SAFE_INPUT';
  \$user = NULL;

  if (is_numeric(\$input)) {
    \$user = \Drupal\user\Entity\User::load(\$input);
  } elseif (strpos(\$input, '@') !== FALSE) {
    \$users = \Drupal::entityTypeManager()->getStorage('user')
      ->loadByProperties(['mail' => \$input]);
    \$user = reset(\$users);
  } else {
    \$user = user_load_by_name(\$input);
  }

  if (\$user) {
    echo 'UID: ' . \$user->id() . PHP_EOL;
    echo 'Username: ' . \$user->getAccountName() . PHP_EOL;
    echo 'Email: ' . \$user->getEmail() . PHP_EOL;
    echo 'Status: ' . (\$user->isActive() ? 'Active' : 'Blocked') . PHP_EOL;
    echo 'Created: ' . date('Y-m-d H:i:s', \$user->getCreatedTime()) . PHP_EOL;
    echo 'Last Login: ' . (\$user->getLastLoginTime() ? date('Y-m-d H:i:s', \$user->getLastLoginTime()) : 'Never') . PHP_EOL;
    echo 'Roles: ' . implode(', ', \$user->getRoles()) . PHP_EOL;
  } else {
    echo 'User not found' . PHP_EOL;
  }
"
```

### 4. Recent Activity
```bash
ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
# Escape for SQL string context: \ -> \\, ' -> ''
SQL_SAFE_INPUT=$(printf '%s' "$ARGS" | sed "s/\\\\/\\\\\\\\/g; s/'/''/g")
./vendor/bin/drush sql:query "
SELECT type, message, timestamp
FROM watchdog
WHERE uid = (
  SELECT uid FROM users_field_data
  WHERE CAST(uid AS CHAR) = '$SQL_SAFE_INPUT'
     OR mail = '$SQL_SAFE_INPUT'
     OR name = '$SQL_SAFE_INPUT'
  LIMIT 1
)
ORDER BY timestamp DESC
LIMIT 10;
" 2>&1
```

### 5. Content Authored
```bash
ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
# Escape for SQL string context: \ -> \\, ' -> ''
SQL_SAFE_INPUT=$(printf '%s' "$ARGS" | sed "s/\\\\/\\\\\\\\/g; s/'/''/g")
./vendor/bin/drush sql:query "
SELECT type, COUNT(*) as count
FROM node_field_data
WHERE uid = (
  SELECT uid FROM users_field_data
  WHERE CAST(uid AS CHAR) = '$SQL_SAFE_INPUT'
     OR mail = '$SQL_SAFE_INPUT'
     OR name = '$SQL_SAFE_INPUT'
  LIMIT 1
)
GROUP BY type;
" 2>&1
```

## Output Format

### User Profile

| Field | Value |
|-------|-------|
| UID | numeric |
| Username | string |
| Email | email |
| Status | Active/Blocked |
| Created | date |
| Last Login | date |
| Roles | list |

### Content Summary

| Content Type | Count |
|--------------|-------|
| article | N |
| page | N |

### Recent Activity

Last 10 logged actions.

### Quick Actions

```bash
# Generate login link
./vendor/bin/drush user:login --uid=<uid>

# Block user
./vendor/bin/drush user:block <username>

# Unblock user
./vendor/bin/drush user:unblock <username>

# Add role
./vendor/bin/drush user:role:add <role> <username>

# Remove role
./vendor/bin/drush user:role:remove <role> <username>
```
