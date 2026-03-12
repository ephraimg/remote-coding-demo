# Claude Code Project Instructions

This file contains project-specific instructions for Claude Code when working in this repository.

## Commit and Push Policy

⚠️ **CRITICAL: Never commit or push without explicit user permission.**

- ❌ Do NOT run `git commit` unless explicitly asked
- ❌ Do NOT run `git push` unless explicitly asked
- ✅ DO make file changes as requested
- ✅ DO run `git status` and `git diff` to show changes
- ✅ WAIT for user to review changes before committing

**Always ask first:** "Ready to commit and push these changes?"

## Security - Secrets Management

⚠️ **CRITICAL: This project contains security documentation. Be extremely careful with secrets.**

### Never Expose:
- API keys (ANTHROPIC_API_KEY, GitHub tokens, AWS credentials)
- SSH private keys
- Passwords or tokens
- IP addresses of EC2 instances
- Any content from `.secrets` files

### Before ANY commit:
1. Scan all staged changes for secrets
2. Check for patterns: `sk-ant-`, `ghp_`, `AKIA`, `ssh-rsa`, IP addresses
3. Verify `.gitignore` is protecting sensitive files
4. Run: `git diff --cached` and review carefully

### Safe to include:
- Documentation with placeholder examples (e.g., "sk-ant-YOUR-KEY")
- Generic instructions and setup guides
- Public information (AWS region names, service names)

## Pre-commit Hook

This project has a pre-commit hook that scans for secrets. If it blocks a commit:
- ✅ Review the flagged content carefully
- ✅ Remove any actual secrets
- ❌ Do NOT bypass with `--no-verify` without user approval

## Documentation Changes

This project has extensive documentation in `docs/`:
- Keep all docs consistent when making changes
- Update cross-references if file names change
- Maintain security best practices in all examples

## Working with Multiple Files

When asked to make changes:
1. Read the relevant files first
2. Make the requested changes
3. Show a summary of what was changed
4. WAIT for user approval before committing

## Testing Changes

Before committing:
- Verify syntax in shell scripts
- Check markdown formatting
- Test example commands are correct
- Ensure no real secrets in examples

---

**Remember: This is a security-focused educational project. Extra caution required!**
