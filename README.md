# Remote Coding Demo

A demonstration project showcasing a complete remote development and deployment pipeline using AWS services and Claude Code CLI.

## Architecture Overview

This project demonstrates a modern serverless deployment workflow with remote development capabilities:

```
Local Machine / EC2 Instance
         ↓
    Git Push to GitHub
         ↓
    AWS Amplify (auto-deploy)
         ↓
    CloudFront CDN
         ↓
    Custom Domain (Route 53)
         ↓
    Live Website (HTTPS)
```

## Tech Stack

### Hosting & Deployment

- **AWS Amplify**: Continuous deployment from GitHub
  - Automatic builds on git push
  - CloudFront CDN integration
  - Free SSL/TLS certificates
  - Fast deployment on every push

- **Route 53**: DNS management
  - Custom subdomain configuration
  - Automatic DNS validation for SSL
  - Integration with CloudFront

- **CloudFront**: Global content delivery network
  - Edge locations worldwide
  - HTTPS enforcement
  - DDoS protection

### Development Environment

- **AWS EC2**: Remote development instance
  - Instance Type: t2.medium (4 GB RAM)
  - OS: Amazon Linux 2
  - SSH access for remote coding
  - Git configured with GitHub authentication

- **Claude Code CLI**: AI-powered development assistant
  - Installed on EC2 for remote coding
  - API key authentication (headless mode)
  - File editing, git operations, and more

## Setup Guide

### Prerequisites

- **AWS Account**: Sign up at aws.amazon.com (requires credit card)
- **GitHub Account**: Sign up at github.com
- **Anthropic API Key** (for Claude Code):
  1. Go to console.anthropic.com
  2. Sign up and add payment method
  3. Navigate to API Keys → Create Key
  4. Start with $5 free credits
- **Domain in Route 53** (optional):
  - Register a domain in Route 53 (~$12/year for .com)
  - Or transfer existing domain to Route 53
  - Skip this for Amplify default domain

### Setup Order

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

### 0. Create Initial Repository

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

### 1. Repository Setup

If the repository already exists:

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/remote-coding-demo.git
cd remote-coding-demo
```

### 2. AWS Amplify Configuration

1. Go to AWS Amplify Console
2. Connect to your GitHub repository
3. Select the main branch
4. Deploy with default build settings (static HTML)
5. Wait for initial deployment to complete

**✅ Verify:** Visit your Amplify URL (e.g., `https://main.d1234abcd.amplifyapp.com`) to see your site live

### 3. Custom Domain (Optional)

1. In Amplify, go to "Domain management"
2. Add your Route 53 domain
3. Configure subdomain (e.g., demo.yourdomain.com)
4. Amplify auto-configures DNS records
5. SSL certificate issued automatically

**✅ Verify:**

- Run `nslookup demo.yourdomain.com` to confirm DNS is configured
- Visit `https://demo.yourdomain.com` once SSL is active
- Check for the green lock icon in your browser

### 4. EC2 Development Instance

1. Launch EC2 instance (t2.medium recommended for Claude Code)
2. **Find your current IP address** (for security group):
   ```bash
   # On your local machine
   curl ifconfig.me
   # Or visit: https://whatismyipaddress.com
   ```
3. Configure security group:
   - **SSH (22) from your IP:**
     - Type: SSH
     - Port: 22
     - Source: `YOUR-IP-ADDRESS/32` (e.g., `203.0.113.42/32`)
   - **SSH (22) from EC2 Instance Connect service:**
     - Type: SSH
     - Port: 22
     - Source: Look up EC2 Instance Connect IP ranges for your region
     - Or use `0.0.0.0/0` for simplicity (less secure)
4. **Find your EC2 connection details:**
   - Go to AWS Console → EC2 → Instances
   - Select your instance
   - In the Details tab, find:
     - **Public IPv4 address** (e.g., `54.183.22.195`)
     - **Public IPv4 DNS** (e.g., `ec2-54-183-22-195.us-west-1.compute.amazonaws.com`)
   - Use either for SSH connection
5. Connect via SSH or EC2 Instance Connect
6. Install git and configure GitHub credentials:
   ```bash
   # On EC2
   sudo yum install git -y
   git config --global user.name "Your Name"
   git config --global user.email "your-email@example.com"
   ```

**✅ Verify:**

- SSH connection succeeds: `ssh -i ~/.ssh/your-key.pem ec2-user@YOUR-EC2-IP`
- Or EC2 Instance Connect works from AWS Console
- Git is installed: `git --version`

### 5. Claude Code CLI Setup

**Installation:**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Authentication:**

```bash
# Set API key (get from console.anthropic.com)
export ANTHROPIC_API_KEY="your-api-key-here"

# Make it permanent
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

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

### 6. Git Credentials on EC2

**Option A: Store credentials**

```bash
git config --global credential.helper store
git push  # Enter username and Personal Access Token once
```

**Option B: SSH keys**

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub  # Add to GitHub
git remote set-url origin git@github.com:YOUR-USERNAME/remote-coding-demo.git
```

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
# SSH into EC2 (replace with your actual key path and EC2 public IP/DNS)
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@ec2-54-123-45-67.us-west-1.compute.amazonaws.com

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

## Project Structure

```
remote-coding-demo/
├── index.html          # Main webpage
├── README.md          # This file
└── .git/              # Git repository
```

## Features

✅ **Continuous Deployment**: Push to GitHub → automatically deployed
✅ **Global CDN**: Fast loading worldwide via CloudFront
✅ **Custom Domain**: Professional subdomain with SSL
✅ **Remote Development**: Code from anywhere using EC2
✅ **AI-Assisted Coding**: Claude Code CLI for intelligent development
✅ **Simple Stack**: Pure HTML/CSS/JS - no build process needed

## Security Notes

- EC2 security groups limit SSH access to specific IPs
- GitHub credentials stored using git credential helper or SSH keys
- API keys stored as environment variables (not committed to git)
- SSL/TLS encryption on all web traffic
- CloudFront provides DDoS protection

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

## Resources

- [AWS Amplify Documentation](https://docs.aws.amazon.com/amplify/)
- [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Claude Code Documentation](https://code.claude.com/docs/)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

## License

This is a demonstration project for educational purposes.

---

**Built with AWS, GitHub, and Claude Code** 🚀
