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
  - ~1-2 minute deployment time

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
- AWS Account
- GitHub Account
- Anthropic API Key (for Claude Code)
- Domain managed in Route 53 (optional)

### 1. Repository Setup
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
5. Wait for initial deployment (~2-3 minutes)

### 3. Custom Domain (Optional)
1. In Amplify, go to "Domain management"
2. Add your Route 53 domain
3. Configure subdomain (e.g., demo.yourdomain.com)
4. Amplify auto-configures DNS records
5. SSL certificate issued automatically (~15-30 minutes)

### 4. EC2 Development Instance
1. Launch EC2 instance (t2.medium recommended for Claude Code)
2. Configure security group:
   - SSH (22) from your IP
   - SSH (22) from EC2 Instance Connect service IPs
3. Connect via SSH or EC2 Instance Connect
4. Install git and configure GitHub credentials

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

# Amplify auto-deploys in ~1-2 minutes
```

### From EC2 Instance
```bash
# SSH into EC2
ssh -i ~/.ssh/your-key.pem ec2-user@your-ec2-ip

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
