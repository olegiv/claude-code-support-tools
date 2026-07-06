---
description: "Lookup user details and roles"
argument-hint: "<uid|email|username>"
allowed-tools: Bash
---

# User Information

Look up detailed information about a Drupal user.

## Arguments

- `$ARGUMENTS` - User ID (numeric), email address, or username

## Instructions

### 1. Validate Input
```bash
if [ ${#ARGUMENTS} -gt 254 ]; then
  echo "ERROR: Input too long (max 254 characters)"
  exit 1
fi

# Validate input format: uid (numeric), email (with @), or username (safe chars)
INPUT="$ARGUMENTS"
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  : # numeric uid - safe
elif [[ "$INPUT" =~ @ ]]; then
  # email - allow standard email characters
  if ! printf '%s' "$INPUT" | grep -qE '^[a-zA-Z0-9._+@-]+$'; then
    echo "ERROR: Invalid email format"
    exit 1
  fi
else
  # username - alphanumeric, underscores, hyphens, dots
  if ! printf '%s' "$INPUT" | grep -qE '^[a-zA-Z0-9._-]+$'; then
    echo "ERROR: Invalid username format. Only alphanumeric, dots, hyphens, underscores allowed."
    exit 1
  fi
fi
```

### 2. Identify User
```bash
INPUT="$ARGUMENTS"

# Check if numeric (uid)
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  ./vendor/bin/drush user:information --uid="$INPUT" --format=yaml 2>&1
# Check if email
elif [[ "$INPUT" =~ @ ]]; then
  ./vendor/bin/drush user:information --mail="$INPUT" --format=yaml 2>&1
# Assume username
else
  ./vendor/bin/drush user:information "$INPUT" --format=yaml 2>&1
fi
```

### 3. Get User Roles
```bash
# Escape for PHP single-quoted string context: \ -> \\, ' -> \'
PHP_SAFE_INPUT=$(printf '%s' "$ARGUMENTS" | sed "s/\\\\/\\\\\\\\/g; s/'/\\\\'/g")
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
# Escape for SQL string context: \ -> \\, ' -> ''
SQL_SAFE_INPUT=$(printf '%s' "$ARGUMENTS" | sed "s/\\\\/\\\\\\\\/g; s/'/''/g")
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
# Escape for SQL string context: \ -> \\, ' -> ''
SQL_SAFE_INPUT=$(printf '%s' "$ARGUMENTS" | sed "s/\\\\/\\\\\\\\/g; s/'/''/g")
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
