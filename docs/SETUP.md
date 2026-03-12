# Complete Setup Guide

This guide walks you through deploying the Remote Coding Demo project to AWS with Amplify, Route 53, and optionally setting up remote development with EC2 and Claude Code.

## Environment Setup (Optional but Recommended)

Before starting, consider setting up environment variables and aliases to make the process easier.

**See: [Environment Setup Guide](ENVIRONMENT-SETUP.md)**

This is **completely optional** - you can manually type or copy-paste values instead. The guide uses variables like `$EC2_IP` and aliases like `ssh-ec2` for convenience, but you can replace them with actual values.

**Quick setup:**
```bash
# Add to ~/.exports.local
export EC2_IP="your-elastic-ip"
export GITHUB_USERNAME="yourusername"
alias ssh-ec2="ssh -i ~/.ssh/ec2-remote-coding ec2-user@\$EC2_IP"

# Source it
echo '[ -f ~/.exports.local ] && source ~/.exports.local' >> ~/.bashrc
source ~/.bashrc
```

---

## Prerequisites

- **AWS Account**: Sign up at aws.amazon.com (requires credit card)
- **GitHub Account**: Sign up at github.com
- **Anthropic API Key** (for Claude Code - optional):
  1. Go to console.anthropic.com
  2. Sign up and add payment method
  3. Navigate to API Keys → Create Key
  4. Start with $5 free credits
- **Domain in Route 53** (optional):
  - Register a domain in Route 53 (~$12/year for .com)
  - Or transfer existing domain to Route 53
  - Skip this for Amplify default domain

## Setup Order

You can set these up in parallel or sequentially:

**Must be sequential:**

1. GitHub repo → Amplify (Amplify needs a repo to connect to)
2. Amplify → Custom domain (need Amplify app first)

**Can be parallel:**

- EC2 setup (independent of Amplify)
- Claude Code setup (do after EC2 is ready)

**Recommended order:**

1. Create GitHub repo with index.html
2. Set up Amplify (get it deploying)
3. While waiting for Amplify, set up EC2
4. Add custom domain (optional)
5. Install Claude Code on EC2
6. Test end-to-end workflow

**Time estimates:**
- AWS Amplify setup: ~10 minutes
- Custom domain + SSL: ~30-45 minutes (waiting for SSL)
- EC2 instance launch: ~5 minutes
- Claude Code installation: ~5 minutes
- **Total first-time setup:** ~1-2 hours (mostly waiting for SSL)

---

## 0. Create Initial Repository

If you're starting from scratch:

```bash
# Create a new repository on GitHub (via web interface)
# Then clone it locally
git clone https://github.com/YOUR-USERNAME/remote-coding-demo.git
cd remote-coding-demo

# Create your index.html file
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World</title>
</head>
<body>
    <h1>Hello World!</h1>
    <p>Welcome to my site</p>
</body>
</html>
EOF

# Initial commit and push
git add index.html
git commit -m "Initial commit: Add Hello World page"
git push
```

**✅ Verify:** Check GitHub - you should see your index.html file in the repository

---

## 1. Repository Setup

If the repository already exists:

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/remote-coding-demo.git
cd remote-coding-demo
```

---

## 2. AWS Amplify Configuration

1. Go to AWS Amplify Console
2. Connect to your GitHub repository
3. Select the main branch
4. Deploy with default build settings (static HTML)
5. Wait for initial deployment to complete

**✅ Verify:** Visit your Amplify URL (e.g., `https://main.d1234abcd.amplifyapp.com`) to see your site live

---

## 3. Custom Domain (Optional)

1. In Amplify, go to "Domain management"
2. Add your Route 53 domain
3. Configure subdomain (e.g., demo.yourdomain.com)
4. Amplify auto-configures DNS records
5. SSL certificate issued automatically

**✅ Verify:**

- Run `nslookup demo.yourdomain.com` to confirm DNS is configured
- Visit `https://demo.yourdomain.com` once SSL is active
- Check for the green lock icon in your browser

---

## 4. EC2 Development Instance (Optional)

### Launch Instance

1. Launch EC2 instance (t2.medium recommended for Claude Code)

### Configure Security Group

2. **Find your current IP address:**
   ```bash
   # On your local machine
   curl ifconfig.me
   # Or visit: https://whatismyipaddress.com
   ```

3. **Configure security group:**
   - **SSH (22) from your IP:**
     - Type: SSH
     - Port: 22
     - Source: `YOUR-IP-ADDRESS/32` (e.g., `203.0.113.42/32`)
   - **SSH (22) from EC2 Instance Connect service:**
     - Type: SSH
     - Port: 22
     - Source: Look up EC2 Instance Connect IP ranges for your region
     - Or use `0.0.0.0/0` for simplicity (less secure)

### Connect to Instance

4. **Find your EC2 connection details:**
   - Go to AWS Console → EC2 → Instances
   - Select your instance
   - In the Details tab, find:
     - **Public IPv4 address** (e.g., `54.183.22.195`)
     - **Public IPv4 DNS** (e.g., `ec2-54-183-22-195.us-west-1.compute.amazonaws.com`)
   - Use either for SSH connection

5. Connect via SSH or EC2 Instance Connect

6. **Install git and configure:**
   ```bash
   # On EC2
   sudo yum install git -y
   git config --global user.name "Your Name"
   git config --global user.email "your-email@example.com"
   ```

**✅ Verify:**

- SSH connection succeeds: `ssh-ec2` (or `ssh -i ~/.ssh/ec2-remote-coding ec2-user@$EC2_IP`)
- Or EC2 Instance Connect works from AWS Console
- Git is installed: `git --version`

---

## 5. Claude Code CLI Setup (Optional)

**Installation:**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Authentication:**

```bash
# Create secure secrets file (important: keeps API key safe from other users)
touch ~/.secrets
chmod 600 ~/.secrets

# Add API key to secure file (get from console.anthropic.com)
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.secrets

# Source it from .bashrc
echo '[ -f ~/.secrets ] && source ~/.secrets' >> ~/.bashrc
source ~/.bashrc
```

**Why use `.secrets` instead of `.bashrc`?**
- `.bashrc` is world-readable (permissions 644), so other users can see it
- `.secrets` has restricted permissions (600), protecting your API key

**Usage:**

```bash
cd ~/remote-coding-demo
claude
```

**✅ Verify:**

- `claude --version` shows version number
- `echo $ANTHROPIC_API_KEY` shows your API key
- `claude` starts successfully and shows prompt
- Select "Anthropic Console account - API usage billing" when prompted

---

## 6. Git Credentials on EC2

**Option A: Store credentials**

```bash
git config --global credential.helper store
git push  # Enter username and Personal Access Token once
```

**Option B: SSH keys**

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub  # Add to GitHub at https://github.com/settings/keys
git remote set-url origin git@github.com:YOUR-USERNAME/remote-coding-demo.git
```

---

## Development Workflow

### From Local Machine

```bash
# Make changes locally
vim index.html

# Commit and push
git add .
git commit -m "Update site"
git push

# Amplify auto-deploys automatically
```

### From EC2 Instance

```bash
# SSH into EC2 (using alias from environment setup)
ssh-ec2

# Or without environment setup:
ssh -i ~/.ssh/ec2-remote-coding ec2-user@$EC2_IP

# Or if using EC2 Instance Connect (no key file needed)
# Just click "Connect" in AWS Console → EC2 Instance Connect

# Navigate to project
cd ~/remote-coding-demo

# Use Claude Code for AI-assisted development
claude

# Or edit manually
nano index.html

# Push changes
git add .
git commit -m "Update from EC2"
git push

# Amplify auto-deploys
```

### With Claude Code on EC2

```bash
# Start Claude
claude

# Ask Claude to make changes
"Update the page to add a new section about our tech stack"

# Claude will edit files, you review, then push
git push
```

---

## Cost Breakdown

### AWS Amplify

- Build minutes: 1,000 free/month, then $0.01/min
- Hosting: 15 GB free/month, then $0.15/GB
- **Typical cost**: $0-5/month for small sites

### Route 53

- Hosted zone: $0.50/month
- DNS queries: $0.40/million queries (after first billion)
- **Typical cost**: $0.50-1/month

### EC2 (t2.medium)

- Compute: ~$0.047/hour (us-west-1)
- Storage: ~$0.10/GB/month
- **Typical cost**: $34/month if running 24/7, or $0-2/month if stopped when not in use

### Claude Code API

- Pay-as-you-go usage
- Claude 3.5 Sonnet: $3/million input tokens, $15/million output tokens
- **Typical cost**: $0.50-5/month for moderate development

---

## Common Pitfalls

### EC2 Memory Requirements

- ❌ **t2.micro (1 GB)** - Claude Code installation will fail with "Killed" error
- ❌ **t2.small (2 GB)** - Still too small for Claude Code
- ✅ **t2.medium (4 GB)** - Minimum for Claude Code
- ✅ **t2.large (8 GB)** - Better performance

**Why it fails:** The Claude Code installer requires significant memory. On undersized instances, the Linux OOM (Out of Memory) killer terminates the process.

### GitHub Authentication

- ❌ **Don't use your GitHub password** - Git operations will fail
- ✅ **Use Personal Access Token** (for HTTPS) or SSH keys
- Token must have **"repo"** scope
- Generate tokens at: https://github.com/settings/tokens
- Store token securely - you won't see it again after creation

### Claude Code Auth Warning

```
Auth conflict: Using ANTHROPIC_API_KEY instead of Anthropic Console key...
```

- ✅ **This warning is harmless** - ignore it
- Claude will work correctly using your API key
- It's just informing you which auth method is active
- Don't run `claude /logout` unless you know what you're doing

### EC2 Public IP Changes

- **Warning:** Public IP changes when you stop/start an instance
- **Solution 1:** Use Elastic IP for consistent address ($0.005/hr when instance stopped)
- **Solution 2:** Use EC2 Instance Connect (no SSH key needed, IP-independent)
- **Solution 3:** Update your SSH config after each restart

### Security Group "Source" Field

- Common error: "CIDR block, a security group ID or a prefix list has to be specified"
- **Fix:** You must fill in the "Source" field
  - For your IP: Use `YOUR-IP/32` or select "My IP" from dropdown
  - For anywhere: Use `0.0.0.0/0` or select "Anywhere-IPv4"
  - For EC2 Instance Connect: Use specific IP range for your region

### Git Credential Helper

- After setting `git config --global credential.helper store`
- Credentials are saved to `~/.git-credentials` in **plain text**
- This is fine for single-user dev instances
- For production/shared systems, use SSH keys instead

---

## Troubleshooting

### Amplify build fails

- Check build logs in Amplify console
- Verify build settings (should be minimal for static HTML)

### Cannot SSH to EC2

- Check security group allows your IP on port 22
- Verify EC2 instance is running
- Check SSH key permissions: `chmod 400 ~/.ssh/your-key.pem`

### Git push authentication fails

- Use Personal Access Token, not password
- Generate at: https://github.com/settings/tokens
- Token needs "repo" scope

### Claude Code auth issues

- Verify: `echo $ANTHROPIC_API_KEY`
- Select "Anthropic Console account - API usage billing" when prompted
- Ignore "auth conflict" warning (harmless)

---

## Advanced: Secure Remote Development

For a secure, isolated development environment with Claude Code, see:

**[Claude User Setup Guide](CLAUDE-USER-SETUP.md)**

This guide covers:
- Setting up a restricted `ec2-claude-user` for security
- Preventing secret exposure
- Multi-project configuration
- Automated setup scripts

---

## Resources

- [AWS Amplify Documentation](https://docs.aws.amazon.com/amplify/)
- [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Claude Code Documentation](https://code.claude.com/docs/)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

---

**Ready to deploy?** Start with step 0 and work your way through! 🚀
