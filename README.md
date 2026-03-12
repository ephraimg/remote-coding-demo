# Remote Coding Demo

A demonstration of modern serverless deployment with AWS Amplify, custom domains via Route 53, global CDN, and secure remote development using Claude Code CLI.

## 🏗️ Architecture

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

## ✨ Features

- ✅ **Continuous Deployment** - Push to GitHub → automatically deployed
- ✅ **Global CDN** - Fast loading worldwide via CloudFront
- ✅ **Custom Domain** - Professional subdomain with SSL/TLS
- ✅ **Remote Development** - Code from anywhere using EC2
- ✅ **AI-Assisted Coding** - Claude Code CLI for intelligent development
- ✅ **Simple Stack** - Pure HTML/CSS/JS, no build process

## 🛠️ Tech Stack

**Hosting & Deployment:**
- AWS Amplify (auto-build & deploy)
- CloudFront (global CDN)
- Route 53 (DNS management)

**Development:**
- AWS EC2 (remote coding environment)
- Claude Code CLI (AI pair programmer)
- Git/GitHub (version control)

## 📚 Documentation

**Getting Started:**
- **[Environment Setup](docs/ENVIRONMENT-SETUP.md)** - Configure variables & aliases (optional but recommended)
- **[Complete Setup Guide](docs/SETUP.md)** - Deploy this project to AWS step-by-step
- **[Claude User Setup](docs/CLAUDE-USER-SETUP.md)** - Secure remote development environment

**What's Included:**
- Step-by-step AWS configuration
- Environment variables and convenient aliases
- Security best practices
- Cost breakdown
- Troubleshooting guide
- Automated setup scripts

## 🚀 Quick Start

1. **Clone and deploy:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/remote-coding-demo.git
   cd remote-coding-demo
   ```

2. **Follow the [Setup Guide](docs/SETUP.md)**

3. **Push changes and watch them deploy automatically**

## 💰 Estimated Costs

- **AWS Amplify:** $0-5/month (small sites)
- **Route 53:** $0.50-1/month (optional)
- **EC2:** $0-34/month (optional, stop when not using)
- **Claude Code API:** $0.50-5/month (optional)

Most components have generous free tiers!

## 📖 Project Structure

```
remote-coding-demo/
├── index.html                      # Main webpage
├── README.md                       # This file
└── docs/                           # Documentation
    ├── SETUP.md                    # Complete deployment guide
    ├── CLAUDE-USER-SETUP.md        # Secure development setup
    ├── setup-claude-user.sh        # Automated user setup script
    └── add-project-to-claude.sh    # Helper script for new projects
```

## 🔒 Security

- EC2 security groups limit SSH access
- Secrets isolated via restricted user accounts
- Pre-commit hooks scan for exposed credentials
- SSL/TLS encryption on all web traffic
- CloudFront provides DDoS protection

## 📝 License

This is a demonstration project for educational purposes.

---

**Built with AWS, GitHub, and Claude Code** 🚀

*For detailed setup instructions, see the [docs](docs/) directory.*
