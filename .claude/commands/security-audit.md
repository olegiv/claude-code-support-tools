# security-audit

Perform a comprehensive security audit of the current project.

Use the Task tool to launch the security-auditor agent with the following prompt:

"Perform a comprehensive security audit of this codebase. Analyze application code, dependencies, configurations, authentication systems, APIs, and secrets management. Generate detailed security reports in the .audit directory with findings, risk assessments, and remediation recommendations."

The agent will:
1. Analyze application code for OWASP Top 10 vulnerabilities
2. Audit dependencies for known CVEs
3. Review configuration files for security issues
4. Examine authentication and authorization implementations
5. Check API security and input validation
6. Scan for exposed secrets and credentials
7. Generate comprehensive markdown reports in .audit/ directory
8. Provide risk assessments and remediation guidance

**Note:** Results are stored in `.audit/` which should never be committed to git.
