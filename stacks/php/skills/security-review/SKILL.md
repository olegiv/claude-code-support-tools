---
name: security-review
description: PHP security review and vulnerability scanning guide. Use for code review, security audits, and fixing vulnerabilities in PHP applications.
allowed-tools: Read, Grep, Glob, Bash
---

# PHP Security Review Skill

This skill guides security review and vulnerability scanning for PHP applications.

## Quick Scanning

### Composer Audit
```bash
composer audit                           # Check known vulnerabilities
composer audit --format=json             # JSON output
```

### Static Analysis
```bash
./vendor/bin/phpstan analyse             # PHPStan (if configured)
```

## Security Checklist

### 1. Input Validation
- [ ] All user input sanitized before use
- [ ] Database queries use prepared statements / parameterized queries
- [ ] No raw SQL string concatenation with user input
- [ ] File uploads validated (type, size, extension)

### 2. Output Encoding
- [ ] HTML escaped: `htmlspecialchars($data, ENT_QUOTES, 'UTF-8')`
- [ ] URL encoded when building URLs with user data
- [ ] JSON encoded with `json_encode()` for API responses
- [ ] No direct echo/print of user-controlled data

### 3. Access Control
- [ ] Authentication checks on protected endpoints
- [ ] Authorization verified for resource access
- [ ] Admin functions properly protected
- [ ] Role/permission checks where needed

### 4. Authentication & Sessions
- [ ] `password_hash()` / `password_verify()` for passwords
- [ ] Session management via framework (not custom)
- [ ] CSRF token protection on state-changing requests
- [ ] Login attempt rate limiting

### 5. Secrets Management
- [ ] No hardcoded credentials in source code
- [ ] API keys in environment variables or config files outside repo
- [ ] `.env` files not committed to version control
- [ ] Secrets directories in `.gitignore`

### 6. Dependencies
- [ ] `composer audit` clean
- [ ] No deprecated packages with known vulnerabilities
- [ ] Latest security patches applied

## Dangerous Patterns

### SQL Injection
```php
// BAD - Direct concatenation
$query = "SELECT * FROM users WHERE name = '" . $name . "'";

// GOOD - PDO Prepared statements
$stmt = $pdo->prepare("SELECT * FROM users WHERE name = :name");
$stmt->execute(['name' => $name]);
```

### XSS (Cross-Site Scripting)
```php
// BAD - Unescaped output
echo $user_input;

// GOOD - Escaped
echo htmlspecialchars($user_input, ENT_QUOTES, 'UTF-8');
```

### Command Injection
```php
// BAD - Direct shell execution
exec("ls " . $user_input);

// GOOD - Escaped argument
exec("ls " . escapeshellarg($user_input));
// Better: Use PHP functions instead of shell commands
```

### Path Traversal
```php
// BAD - Direct path from user input
file_get_contents($user_path);

// GOOD - Validate path is within allowed directory
$real_path = realpath($user_path);
// PHP 8.0+: str_starts_with($real_path, $allowed_directory)
// PHP 7.x:  strpos($real_path, $allowed_directory) === 0
if ($real_path && str_starts_with($real_path, $allowed_directory)) {
    file_get_contents($real_path);
}
```

### Insecure Deserialization
```php
// BAD - Unserialize user data
$data = unserialize($user_input);

// GOOD - Use JSON instead
$data = json_decode($user_input, true);
// Or restrict allowed classes
$data = unserialize($input, ['allowed_classes' => [SafeClass::class]]);
```

## Code Review Process

1. **Identify entry points**: Forms, APIs, URL parameters, file uploads
2. **Trace data flow**: Input -> Processing -> Output
3. **Check sanitization**: At both input and output points
4. **Verify access control**: Authentication and authorization
5. **Review dependencies**: Third-party code vulnerabilities
6. **Test edge cases**: Empty, null, special characters, boundary values

## Reporting

When reporting issues, include:
- **Severity**: Critical/High/Medium/Low
- **Location**: File path and line number
- **Description**: What the vulnerability is
- **Impact**: What could happen if exploited
- **Remediation**: How to fix it

## Resources

- OWASP Top 10: https://owasp.org/Top10/
- PHP Security: https://www.php.net/manual/en/security.php
- CWE/SANS Top 25: https://cwe.mitre.org/top25/
