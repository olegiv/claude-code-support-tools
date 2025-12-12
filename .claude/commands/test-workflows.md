Validate GitHub Actions workflow files for syntax errors and best practices.

## Process

1. Locate workflow files:
   - `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.github/workflows/claude.yml`
   - `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.github/workflows/claude-code-review.yml`

2. Check for YAML syntax errors:
   - Use a YAML validator or parser
   - Report any syntax issues

3. Validate workflow structure:
   - Verify required fields (name, on, jobs)
   - Check job definitions
   - Validate step syntax
   - Verify action versions are current

4. Check Claude Code Action usage:
   - Verify anthropics/claude-code-action@v1 is used correctly
   - Check required parameters (claude_code_oauth_token)
   - Validate claude_args syntax if present
   - Verify permissions are appropriate

5. Review best practices:
   - Proper event triggers
   - Correct permissions scope
   - Secure secrets handling
   - Appropriate checkout depth

6. Provide validation report:
   - Syntax status (pass/fail)
   - Structure validation results
   - Best practice recommendations
   - Security considerations

7. If issues found, provide specific fixes with line numbers and corrections
