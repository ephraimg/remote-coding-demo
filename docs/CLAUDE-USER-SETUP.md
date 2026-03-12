# EC2 Claude User Setup Guide

Complete guide to setting up a secure, restricted user for Claude Code development.

## Environment Setup (Recommended)

Before starting, set up environment variables and aliases for easier management.

**See: [Environment Setup Guide](ENVIRONMENT-SETUP.md)**

**Quick setup:**
```bash
# Add to ~/.exports.local
export EC2_IP="your-elastic-ip"
export GITHUB_USERNAME="yourusername"
alias ssh-ec2="ssh -i ~/.ssh/ec2-remote-coding ec2-user@\$EC2_IP"
alias ssh-claude="ssh -i ~/.ssh/ec2-claude-key ec2-claude-user@\$EC2_IP"
alias scp-to-ec2="scp -i ~/.ssh/ec2-remote-coding"

# Source it
echo '[ -f ~/.exports.local ] && source ~/.exports.local' >> ~/.bashrc
source ~/.bashrc
```

**Note:** All commands below use these variables/aliases for convenience, but you can replace them with actual values if you prefer.

---

## Overview

This setup creates `ec2-claude-user` - a restricted Linux user that:
- ✅ Can access multiple project directories via symlinks
- ✅ Cannot read ec2-user's secrets (SSH keys, AWS credentials)
- ✅ Has its own GitHub token (revocable separately)
- ✅ Has secret scanning via pre-commit hooks
- ✅ Uses isolated Claude Code installation

## Directory Structure

```
/home/ec2-user/projects/           ← Real project files
    ├── remote-coding-demo/
    ├── project-2/
    └── project-3/

/home/ec2-claude-user/projects/    ← Symlinks to real files
    ├── remote-coding-demo → /home/ec2-user/projects/remote-coding-demo/
    ├── project-2 → /home/ec2-user/projects/project-2/
    └── project-3 → /home/ec2-user/projects/project-3/
```

**Benefits:**
- No file duplication - one source of truth
- Both users can work on same projects
- Easy to add new projects
- Claude can work across multiple codebases

## Prerequisites

- EC2 instance running (t2.medium or larger)
- SSH access as ec2-user
- GitHub account
- Anthropic API key

## Setup Process

### Part 1: Automated Setup (5 minutes)

**1. Upload the setup script to EC2:**

```bash
# On your local machine (from repo root)
scp-to-ec2 docs/setup-claude-user.sh ec2-user@$EC2_IP:~

# Or without environment setup:
# scp -i ~/.ssh/ec2-remote-coding docs/setup-claude-user.sh ec2-user@YOUR-ELASTIC-IP:~
```

**2. SSH into EC2 and run the script:**

```bash
ssh-ec2

# Or without environment setup:
# ssh -i ~/.ssh/ec2-remote-coding ec2-user@YOUR-ELASTIC-IP

# Make executable
chmod +x setup-claude-user.sh

# Run as root
sudo ./setup-claude-user.sh
```

The script will:
- Create ec2-claude-user
- Set up `/home/ec2-user/projects/` as shared projects directory
- Create 'developers' group for shared access
- Create symlinks in `/home/ec2-claude-user/projects/`
- Install Claude Code
- Configure git
- Set up pre-commit hooks for all projects
- Update .gitignore for all projects
- Create SSH directory

### Part 2: SSH Key Setup (2 minutes)

**1. Generate SSH key on your LOCAL machine:**

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ec2-claude-key

# No passphrase (press Enter) or set one if you prefer
```

**2. Copy public key:**

```bash
cat ~/.ssh/ec2-claude-key.pub
# Copy the entire output
```

**3. Add to EC2 authorized_keys:**

```bash
# On EC2 as ec2-user
sudo nano /home/ec2-claude-user/.ssh/authorized_keys
# Paste the public key
# Save: Ctrl+X, Y, Enter
```

**4. Test SSH access:**

```bash
# From your local machine (using alias)
ssh-claude

# Or without environment setup:
# ssh -i ~/.ssh/ec2-claude-key ec2-claude-user@$EC2_IP

# Should connect! Type 'exit' to log out
```

### Part 3: GitHub Token Setup (3 minutes)

**1. Create new Personal Access Token:**

- Go to: https://github.com/settings/tokens
- Click "Generate new token (classic)"
- **Note:** `EC2 Claude Bot Token`
- **Expiration:** 90 days (or your preference)
- **Scopes:** Check ✅ **repo** ONLY
- Click "Generate token"
- **Copy the token** (starts with `ghp_...`)

**2. Test git access:**

```bash
# SSH as ec2-claude-user
ssh -i ~/.ssh/ec2-claude-key ec2-claude-user@YOUR-ELASTIC-IP

# Navigate to project
cd ~/projects/remote-coding-demo

# Test git (will prompt for credentials)
git pull

# Enter:
# Username: YOUR-GITHUB-USERNAME
# Password: [paste the Claude bot token]

# Should work! Credentials are now saved
```

### Part 4: Anthropic API Key (1 minute)

**SSH as ec2-claude-user:**

```bash
# Create secure secrets file
touch ~/.secrets
chmod 600 ~/.secrets

# Add API key to secure file
echo 'export ANTHROPIC_API_KEY="sk-ant-YOUR-ACTUAL-KEY"' >> ~/.secrets

# Source it from .bashrc
echo '[ -f ~/.secrets ] && source ~/.secrets' >> ~/.bashrc
source ~/.bashrc

# Verify
echo $ANTHROPIC_API_KEY
```

**Note:** Using `.secrets` (600 permissions) instead of `.bashrc` (644) is a security best practice, even though ec2-claude-user is the only user accessing their own files.

### Part 5: Test Claude Code (2 minutes)

```bash
# Navigate to project
cd ~/projects/remote-coding-demo

# Start Claude
claude

# Select "Anthropic Console account - API usage billing"
# Should authenticate and start!

# Try a simple command:
"Add a comment to index.html"

# Review changes
exit
git diff

# Commit and push
git add .
git commit -m "Test: Claude bot first commit"
git push
```

## Local Machine Configuration

### SSH Config

Add to `~/.ssh/config`:

```
# Main admin user
Host ec2-admin
    HostName YOUR-ELASTIC-IP
    User ec2-user
    IdentityFile ~/.ssh/ec2-remote-coding

# Claude coding user
Host ec2-claude
    HostName YOUR-ELASTIC-IP
    User ec2-claude-user
    IdentityFile ~/.ssh/ec2-claude-key
```

**Usage:**

```bash
# Admin tasks
ssh ec2-admin

# Coding with Claude
ssh ec2-claude
```

### Termius (iOS/Android)

**Create new host:**
- **Alias:** `EC2 Claude`
- **Hostname:** `YOUR-ELASTIC-IP`
- **Port:** `22`
- **Username:** `ec2-claude-user`
- **Key:** Import `~/.ssh/ec2-claude-key`

## Adding New Projects

### Automatic (Recommended)

**Upload the helper script:**
```bash
# From repo root (using alias)
scp-to-ec2 docs/add-project-to-claude.sh ec2-user@$EC2_IP:~

# Or without environment setup:
# scp docs/add-project-to-claude.sh ec2-user@YOUR-ELASTIC-IP:~
```

**Add a new project:**
```bash
# SSH as ec2-user (using alias)
ssh-ec2

# Or: ssh ec2-admin (if using SSH config)

# Create/clone your new project
cd ~/projects
git clone https://github.com/YOUR-USERNAME/new-project.git

# Run the helper script
chmod +x add-project-to-claude.sh
sudo ./add-project-to-claude.sh new-project
```

**Done!** Claude user can now access it.

### Manual

If you prefer manual setup:

```bash
# As ec2-user
cd ~/projects
git clone https://github.com/YOUR-USERNAME/new-project.git

# Set permissions
sudo chown -R ec2-user:developers ~/projects/new-project
sudo chmod -R g+rwX ~/projects/new-project
sudo find ~/projects/new-project -type d -exec chmod g+s {} \;

# Create symlink
sudo ln -s ~/projects/new-project /home/ec2-claude-user/projects/
```

## Daily Workflow

### Coding with Claude

```bash
# SSH as Claude user (using alias)
ssh-claude

# Or: ssh ec2-claude (if using SSH config)

# List available projects
ls -la ~/projects/

# Navigate to any project
cd ~/projects/remote-coding-demo
# or
cd ~/projects/other-project

# Start Claude
claude

# Make changes, then exit Claude

# Review changes (ALWAYS!)
git diff

# Commit and push
git add .
git commit -m "Description of changes"
git push

# Watch Amplify deploy (if configured)
```

**Claude can work across multiple projects:**
```bash
cd ~/projects/project-1
claude
# Make changes to project-1

cd ~/projects/project-2
claude
# Make changes to project-2
```

### Admin Tasks

```bash
# SSH as admin user (using alias)
ssh-ec2

# Or: ssh ec2-admin (if using SSH config)

# System updates, user management, etc.
sudo yum update
```

## Security Features

### What's Protected

✅ **ec2-user's secrets are isolated:**
- SSH keys in `/home/ec2-user/.ssh/`
- AWS credentials in `/home/ec2-user/.aws/`
- Environment variables

✅ **Pre-commit hook scans for:**
- API keys (sk-ant-, ghp-, AKIA)
- Passwords and secrets
- SSH private keys (-----BEGIN)
- Common credential patterns

✅ **Separate GitHub token:**
- Revoke Claude's token without affecting your main access
- Audit trail shows "Claude Bot" commits

### What Claude Can Access

✅ **Project files only:**
- `/home/ec2-claude-user/projects/remote-coding-demo/`

✅ **Its own credentials:**
- ANTHROPIC_API_KEY (in its own environment)
- GitHub token (for git push)

❌ **Cannot access:**
- Other users' files
- System configuration
- SSH keys of other users
- AWS credentials

### Important: Protecting Secrets in .bashrc

⚠️ **`.bashrc` files are world-readable (644 permissions)** - any user can read them!

**Problem:** If ec2-user puts secrets in `~/.bashrc`, ec2-claude-user (and Claude) can read them.

**Solution:** Use a separate `.secrets` file with restricted permissions:

```bash
# As ec2-user - create secure secrets file
touch ~/.secrets
chmod 600 ~/.secrets

# Add your secrets to .secrets (not .bashrc!)
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.secrets

# In .bashrc, add ONLY this line to source the secure file:
# Open .bashrc with nano and add this line manually:
[ -f ~/.secrets ] && source ~/.secrets

# Verify permissions
ls -la ~/.secrets  # Should show: -rw------- (600)

# Test
source ~/.bashrc
echo $ANTHROPIC_API_KEY
```

**Verify Claude can't read it:**
```bash
# As ec2-claude-user
cat /home/ec2-user/.secrets
# Should say: Permission denied ✅
```

**Never do this:**
- ❌ Don't put API keys directly in `.bashrc`
- ❌ Don't accidentally add the `echo` command to `.bashrc` itself

## Troubleshooting

### Pre-commit Hook Blocks Commit

```bash
# If it's a false positive, bypass with:
git commit --no-verify -m "Message"

# But review carefully first!
```

### GitHub Authentication Fails

```bash
# Re-enter credentials
rm ~/.git-credentials
git pull  # Will prompt again
```

### Claude Won't Start

```bash
# Check API key is set
echo $ANTHROPIC_API_KEY

# If not set:
source ~/.bashrc

# Or re-add to secure file:
echo 'export ANTHROPIC_API_KEY="sk-ant-YOUR-KEY"' >> ~/.secrets
source ~/.bashrc
```

### "Permission Denied" on SSH

```bash
# Check key permissions on local machine
chmod 600 ~/.ssh/ec2-claude-key

# Check authorized_keys on EC2
sudo ls -la /home/ec2-claude-user/.ssh/
# Should be: drwx------ (700) for .ssh
#            -rw------- (600) for authorized_keys
```

### "Permission Denied" Accessing Projects

```bash
# If you get permission denied when trying to cd ~/projects/remote-coding-demo
# The issue is ec2-user's home directory doesn't allow traversal

# Fix as ec2-user:
ssh-ec2
chmod o+x /home/ec2-user

# Verify:
ls -ld /home/ec2-user
# Should show: drwx-----x (execute bit for others)

# Now try again as claude user
```

**Note:** The setup script now handles this automatically, but manual setups may need this fix.

### Git "Dubious Ownership" Error

```bash
# If you see: "fatal: detected dubious ownership in repository"
# This happens because the repo is owned by ec2-user but accessed by ec2-claude-user

# Fix as ec2-claude-user:
git config --global --add safe.directory /home/ec2-user/projects/remote-coding-demo

# For multiple projects, repeat for each:
git config --global --add safe.directory /home/ec2-user/projects/PROJECT-NAME
```

**Note:** The setup script now handles this automatically for all existing projects.

## Maintenance

### Rotating GitHub Token

**When token expires:**

1. Create new token on GitHub (same process)
2. SSH as ec2-claude-user
3. Remove old credentials:
   ```bash
   rm ~/.git-credentials
   ```
4. Git pull (will prompt for new token)

### Syncing Project Changes

**With symlinks, syncing is automatic!**

Both users work on the **same files**:

```bash
# As ec2-user - make changes
cd ~/projects/remote-coding-demo
vim index.html
git commit -am "Update"
git push

# As ec2-claude-user - sees changes immediately
cd ~/projects/remote-coding-demo
git status  # Shows ec2-user's changes!
```

**No syncing needed** - symlinks point to the same files.

## Cost Impact

**No additional cost** - same EC2 instance, just better security!

## Rollback

**To remove ec2-claude-user:**

```bash
# As ec2-user
sudo userdel -r ec2-claude-user

# Remove from GitHub settings:
# https://github.com/settings/tokens
# https://github.com/settings/keys
```

---

## Summary

**Time to set up:** ~15 minutes
**Security benefit:** High
**Complexity:** Low (mostly automated)
**Cost:** $0 (same instance)

**Result:** Secure, isolated Claude Code environment that protects your secrets! 🔒
