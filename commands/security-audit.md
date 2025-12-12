# security-audit

Perform a comprehensive security audit of the current project.

Before starting a new audit:
1. If previous audit files exist in `.audit/`, create a directory with the current timestamp (e.g., `.audit/2025-01-15_14-30-00/`)
2. Move all existing audit files into that timestamped directory to preserve audit history
3. Use all previously done audits for evolution analysis if needed (compare findings, track remediation progress, identify recurring issues)

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
