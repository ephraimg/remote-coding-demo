# Environment Setup (Optional but Recommended)

This guide helps you set up environment variables and aliases to make working with your EC2 instance easier. **This is completely optional** - you can manually type or copy-paste values instead.

## Why Use Environment Variables?

**Without environment variables:**
```bash
ssh -i ~/.ssh/ec2-remote-coding ec2-user@54.193.42.100
scp -i ~/.ssh/ec2-remote-coding docs/setup.sh ec2-user@54.193.42.100:~
```

**With environment variables:**
```bash
ssh-ec2
scp-to-ec2 docs/setup.sh ec2-user@$EC2_IP:~
```

**Benefits:**
- ✅ Less typing
- ✅ No copy-paste errors
- ✅ Easy to update if IP changes
- ✅ Reusable across terminal sessions

---

## Setup Instructions

### 1. Create `~/.exports.local`

```bash
# Create the file
touch ~/.exports.local
chmod 600 ~/.exports.local  # Keep it private
```

### 2. Add Your Configuration

Open `~/.exports.local` in your editor and add:

```bash
# ==================================================
# Remote Coding Demo - Environment Configuration
# ==================================================

# AWS EC2
export EC2_IP="YOUR-ELASTIC-IP-HERE"           # e.g., "54.193.42.100"
export AWS_REGION="us-west-1"                  # Your AWS region

# GitHub
export GITHUB_USERNAME="YOUR-GITHUB-USERNAME"  # e.g., "ephraimg"

# SSH Keys
export EC2_KEY="$HOME/.ssh/ec2-remote-coding"
export EC2_CLAUDE_KEY="$HOME/.ssh/ec2-claude-key"

# Anthropic (optional - only if using Claude Code)
export ANTHROPIC_API_KEY="sk-ant-..."  # Your Anthropic API key

# ==================================================
# Convenient Aliases
# ==================================================

# SSH shortcuts
alias ssh-ec2="ssh -i $EC2_KEY ec2-user@$EC2_IP"
alias ssh-claude="ssh -i $EC2_CLAUDE_KEY ec2-claude-user@$EC2_IP"

# SCP shortcuts (upload to EC2)
alias scp-to-ec2="scp -i $EC2_KEY"
alias scp-to-claude="scp -i $EC2_CLAUDE_KEY"

# Quick IP check
alias ec2-ip="echo $EC2_IP"

# SSH config regeneration (useful when IP changes)
alias update-ssh-config='cat > ~/.ssh/config << EOF
Host ec2-admin
    HostName $EC2_IP
    User ec2-user
    IdentityFile $EC2_KEY

Host ec2-claude
    HostName $EC2_IP
    User ec2-claude-user
    IdentityFile $EC2_CLAUDE_KEY
EOF
echo "SSH config updated with IP: $EC2_IP"'
```

### 3. Source the File from Your Shell

**If using Bash (`~/.bashrc`):**
```bash
echo '[ -f ~/.exports.local ] && source ~/.exports.local' >> ~/.bashrc
source ~/.bashrc
```

**If using Zsh (`~/.zshrc`):**
```bash
echo '[ -f ~/.exports.local ] && source ~/.exports.local' >> ~/.zshrc
source ~/.zshrc
```

### 4. Verify Setup

```bash
# Check variables are set
echo $EC2_IP
echo $GITHUB_USERNAME

# Test aliases
ssh-ec2  # Should connect to your EC2 instance
```

---

## Usage Examples

### SSH Connections

```bash
# Using alias (easiest)
ssh-ec2
ssh-claude

# Using variable
ssh -i $EC2_KEY ec2-user@$EC2_IP

# Or still use SSH config hosts
ssh ec2-admin
ssh ec2-claude
```

### File Transfers

```bash
# Upload to ec2-user home
scp-to-ec2 localfile.txt ec2-user@$EC2_IP:~/

# Upload to claude user
scp-to-claude setup.sh ec2-claude-user@$EC2_IP:~/

# Download from EC2
scp -i $EC2_KEY ec2-user@$EC2_IP:~/remotefile.txt .
```

### Documentation Commands

Throughout our docs, you'll see commands like:
```bash
ssh-ec2
scp-to-ec2 docs/setup-claude-user.sh ec2-user@$EC2_IP:~
```

**If you haven't set up the environment:**
- Replace `$EC2_IP` with your actual IP
- Replace `ssh-ec2` with `ssh -i ~/.ssh/ec2-remote-coding ec2-user@YOUR-IP`
- Replace `scp-to-ec2` with `scp -i ~/.ssh/ec2-remote-coding`

---

## Updating Configuration

### When Your IP Changes

If you get a new Elastic IP or restart your instance:

```bash
# Edit ~/.exports.local
nano ~/.exports.local
# Update EC2_IP value

# Reload
source ~/.exports.local

# Update SSH config (if using the alias)
update-ssh-config
```

### Adding New Variables

Just add them to `~/.exports.local` and reload:
```bash
echo 'export NEW_VAR="value"' >> ~/.exports.local
source ~/.exports.local
```

---

## Security Notes

**What to store in `~/.exports.local`:**
- ✅ EC2 IP addresses (public information)
- ✅ GitHub usernames (public)
- ✅ Paths to SSH keys (local filesystem)
- ⚠️ API keys (if you trust your local machine security)

**File permissions:**
```bash
chmod 600 ~/.exports.local  # Only you can read/write
```

**Never commit `~/.exports.local` to git!**

Add to your global `.gitignore`:
```bash
echo ".exports.local" >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

---

## Alternative: Manual Configuration

**Don't want environment variables?** No problem!

Just replace variables in commands:
- `$EC2_IP` → `54.193.42.100` (your actual IP)
- `$GITHUB_USERNAME` → `yourusername`
- `ssh-ec2` → `ssh -i ~/.ssh/ec2-remote-coding ec2-user@54.193.42.100`

The docs use variables for convenience, but everything works without them.

---

## Troubleshooting

### Variables not found

```bash
# Check if file is sourced
grep "exports.local" ~/.bashrc  # or ~/.zshrc

# Manually source
source ~/.exports.local

# Check variable
echo $EC2_IP
```

### Aliases not working

```bash
# Check if aliases are defined
alias | grep ssh-ec2

# Reload shell config
source ~/.bashrc  # or ~/.zshrc
```

### SSH config not updating

```bash
# Manually update
cat > ~/.ssh/config << EOF
Host ec2-admin
    HostName YOUR-IP-HERE
    User ec2-user
    IdentityFile ~/.ssh/ec2-remote-coding
EOF
```

---

## Complete Example

**Setup once:**
```bash
# Create and edit config
nano ~/.exports.local
# (add your values)

# Source it
echo '[ -f ~/.exports.local ] && source ~/.exports.local' >> ~/.bashrc
source ~/.bashrc

# Verify
echo $EC2_IP
```

**Daily usage:**
```bash
# Connect
ssh-ec2

# Upload files
scp-to-ec2 myfile.txt ec2-user@$EC2_IP:~/

# Work on EC2
cd ~/projects/remote-coding-demo
claude

# Done!
```

---

**That's it!** Your environment is now configured for easy remote development. 🚀
