#!/bin/bash
#
# EC2 Claude User Setup Script
# Sets up a restricted user for Claude Code with proper security isolation
#
# Usage: sudo ./setup-claude-user.sh
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}EC2 Claude User Setup Script${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

# Get the actual user who ran sudo (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
    echo -e "${RED}Error: Cannot determine the original user${NC}"
    exit 1
fi

echo -e "${YELLOW}This script will:${NC}"
echo "  1. Create ec2-claude-user"
echo "  2. Set up project directory"
echo "  3. Install Claude Code"
echo "  4. Configure git"
echo "  5. Set up security hooks"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# ============================================
# Phase 1: Create User
# ============================================
echo -e "\n${GREEN}[1/7] Creating ec2-claude-user...${NC}"

if id "ec2-claude-user" &>/dev/null; then
    echo -e "${YELLOW}User ec2-claude-user already exists, skipping...${NC}"
else
    useradd -m ec2-claude-user  # -m creates home directory
    echo -e "${GREEN}✓ User created${NC}"
fi

# ============================================
# Phase 2: Set Up Shared Projects Directory
# ============================================
echo -e "\n${GREEN}[2/7] Setting up shared projects directory...${NC}"

# Create shared projects directory structure
PROJECTS_ROOT="/home/$ACTUAL_USER/projects"
CLAUDE_PROJECTS_DIR="/home/ec2-claude-user/projects"

# Create projects directory for ec2-user if it doesn't exist
if [ ! -d "$PROJECTS_ROOT" ]; then
    mkdir -p "$PROJECTS_ROOT"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$PROJECTS_ROOT"
    echo "Created $PROJECTS_ROOT"
fi

# Move remote-coding-demo if it's not already in projects/
OLD_LOCATION="/home/$ACTUAL_USER/remote-coding-demo"
if [ -d "$OLD_LOCATION" ] && [ "$OLD_LOCATION" != "$PROJECTS_ROOT/remote-coding-demo" ]; then
    echo "Moving remote-coding-demo to projects directory..."
    mv "$OLD_LOCATION" "$PROJECTS_ROOT/"
fi

# Create a shared group for project access
if ! getent group developers > /dev/null 2>&1; then
    groupadd developers
    echo "Created 'developers' group"
fi

# Add both users to developers group
usermod -a -G developers "$ACTUAL_USER"
usermod -a -G developers ec2-claude-user

# Set group ownership and permissions on projects directory
chown -R "$ACTUAL_USER:developers" "$PROJECTS_ROOT"
chmod -R g+rwX "$PROJECTS_ROOT"
# Set setgid bit so new files inherit group ownership
find "$PROJECTS_ROOT" -type d -exec chmod g+s {} \;

# Allow traversal through ec2-user's home directory
# This lets ec2-claude-user access /home/ec2-user/projects/ through symlinks
chmod o+x "/home/$ACTUAL_USER"
echo "Enabled home directory traversal for symlink access"

echo -e "${GREEN}✓ Shared projects directory configured${NC}"

# Create Claude user's projects directory with symlinks
echo "Creating symlinks for ec2-claude-user..."
mkdir -p "$CLAUDE_PROJECTS_DIR"

# Symlink all existing projects
for project in "$PROJECTS_ROOT"/*/ ; do
    if [ -d "$project" ]; then
        project_name=$(basename "$project")
        symlink_path="$CLAUDE_PROJECTS_DIR/$project_name"

        if [ ! -L "$symlink_path" ]; then
            ln -s "$project" "$symlink_path"
            echo "  → Created symlink: $project_name"
        else
            echo "  ✓ Symlink exists: $project_name"
        fi
    fi
done

chown -R ec2-claude-user:ec2-claude-user "$CLAUDE_PROJECTS_DIR"
echo -e "${GREEN}✓ Project symlinks created${NC}"

# ============================================
# Phase 3: Install Claude Code
# ============================================
echo -e "\n${GREEN}[3/7] Installing Claude Code for ec2-claude-user...${NC}"

# Run installation as ec2-claude-user
su - ec2-claude-user -c 'bash -c "curl -fsSL https://claude.ai/install.sh | bash"'

# Add to PATH in bashrc if not already there
if ! grep -q "/.local/bin" /home/ec2-claude-user/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/ec2-claude-user/.bashrc
fi

echo -e "${GREEN}✓ Claude Code installed${NC}"

# ============================================
# Phase 4: Configure Git
# ============================================
echo -e "\n${GREEN}[4/7] Configuring git...${NC}"

su - ec2-claude-user -c 'git config --global user.name "Claude Bot"'
su - ec2-claude-user -c 'git config --global user.email "claude-bot@noreply.github.com"'
su - ec2-claude-user -c 'git config --global credential.helper store'

# Add all projects as safe directories (fixes "dubious ownership" error)
for project in "$PROJECTS_ROOT"/*/ ; do
    if [ -d "$project/.git" ]; then
        su - ec2-claude-user -c "git config --global --add safe.directory '$project'"
        echo "  ✓ Added $(basename "$project") as safe directory"
    fi
done

echo -e "${GREEN}✓ Git configured${NC}"

# ============================================
# Phase 5: Create Pre-commit Hooks for All Projects
# ============================================
echo -e "\n${GREEN}[5/7] Setting up pre-commit hooks for secret scanning...${NC}"

# Function to add pre-commit hook to a project
add_precommit_hook() {
    local project_path="$1"
    local hook_path="$project_path/.git/hooks/pre-commit"

    if [ ! -d "$project_path/.git" ]; then
        echo "  ⊘ Skipping $project_path (not a git repo)"
        return
    fi

    cat > "$hook_path" << 'HOOKEOF'
#!/bin/bash

echo "🔍 Scanning for secrets..."

# Check staged changes for common secret patterns
if git diff --cached | grep -iE "sk-ant-|ghp_|AKIA|aws_secret|api[_-]?key.*=|password.*=|secret.*=|token.*=|-----BEGIN"; then
    echo ""
    echo "⚠️  WARNING: Possible secret detected in staged changes!"
    echo ""
    echo "Problematic lines:"
    git diff --cached | grep -iE "sk-ant-|ghp_|AKIA|aws_secret|api[_-]?key|password|secret|token|-----BEGIN" --color=always
    echo ""
    echo "If this is a false positive, you can bypass with: git commit --no-verify"
    echo ""
    exit 1
fi

echo "✅ No secrets detected"
exit 0
HOOKEOF

    chmod +x "$hook_path"
    echo "  ✓ Added to $(basename "$project_path")"
}

# Add pre-commit hooks to all git projects
for project in "$PROJECTS_ROOT"/*/ ; do
    if [ -d "$project" ]; then
        add_precommit_hook "$project"
    fi
done

echo -e "${GREEN}✓ Pre-commit hooks configured${NC}"

# ============================================
# Phase 6: Update .gitignore for All Projects
# ============================================
echo -e "\n${GREEN}[6/7] Updating .gitignore for secret protection...${NC}"

# Function to update .gitignore
update_gitignore() {
    local project_path="$1"
    local gitignore="$project_path/.gitignore"

    if [ ! -d "$project_path/.git" ]; then
        echo "  ⊘ Skipping $project_path (not a git repo)"
        return
    fi

    # Check if our section already exists
    if grep -q "# Secrets and Credentials (added by setup script)" "$gitignore" 2>/dev/null; then
        echo "  ✓ $(basename "$project_path") already has secret protection"
        return
    fi

    cat >> "$gitignore" << 'IGNOREEOF'

# ============================================
# Secrets and Credentials (added by setup script)
# ============================================
.env
.env.*
*.key
*.pem
*.p12
id_rsa*
*.credentials
*_credentials
config.local.*
secrets/
.aws/
*.secret

# API keys and tokens
*api_key*
*apikey*
*token*
*.token
*secret*

# AWS credentials
credentials
config
IGNOREEOF

    echo "  ✓ Updated $(basename "$project_path")/.gitignore"
}

# Update .gitignore for all git projects
for project in "$PROJECTS_ROOT"/*/ ; do
    if [ -d "$project" ]; then
        update_gitignore "$project"
    fi
done

echo -e "${GREEN}✓ .gitignore files updated${NC}"

# ============================================
# Phase 7: Set Up SSH Directory
# ============================================
echo -e "\n${GREEN}[7/7] Setting up SSH directory...${NC}"

SSH_DIR="/home/ec2-claude-user/.ssh"
mkdir -p "$SSH_DIR"
touch "$SSH_DIR/authorized_keys"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"
chown -R ec2-claude-user:ec2-claude-user "$SSH_DIR"

echo -e "${GREEN}✓ SSH directory created${NC}"

# ============================================
# Summary
# ============================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${YELLOW}Next steps (manual):${NC}\n"

echo "1. Generate SSH key on your LOCAL machine:"
echo "   ssh-keygen -t ed25519 -f ~/.ssh/ec2-claude-key"
echo ""

echo "2. Add public key to ec2-claude-user authorized_keys:"
echo "   cat ~/.ssh/ec2-claude-key.pub  # Copy this"
echo "   # Then on EC2:"
echo "   sudo nano $SSH_DIR/authorized_keys  # Paste and save"
echo ""

echo "3. Test SSH access:"
echo "   ssh -i ~/.ssh/ec2-claude-key ec2-claude-user@YOUR-ELASTIC-IP"
echo ""

echo "4. Create GitHub Personal Access Token:"
echo "   https://github.com/settings/tokens"
echo "   - Note: 'EC2 Claude Bot Token'"
echo "   - Scope: 'repo' only"
echo ""

echo "5. SSH as ec2-claude-user and set up API key:"
echo "   touch ~/.secrets && chmod 600 ~/.secrets"
echo "   echo 'export ANTHROPIC_API_KEY=\"sk-ant-YOUR-KEY\"' >> ~/.secrets"
echo "   echo '[ -f ~/.secrets ] && source ~/.secrets' >> ~/.bashrc"
echo "   source ~/.bashrc"
echo ""

echo "6. Test git push (will prompt for GitHub token first time):"
echo "   cd ~/projects/remote-coding-demo"
echo "   git pull"
echo ""

echo "7. Test Claude Code:"
echo "   cd ~/projects/remote-coding-demo"
echo "   claude"
echo ""

echo -e "${YELLOW}Adding New Projects:${NC}\n"
echo "To add a new project for Claude to access:"
echo "1. Create/clone project in $PROJECTS_ROOT/"
echo "2. Run this script again, or manually:"
echo "   sudo ln -s $PROJECTS_ROOT/new-project /home/ec2-claude-user/projects/"
echo "   sudo chmod -R g+rwX $PROJECTS_ROOT/new-project"
echo ""

echo -e "${GREEN}User setup complete!${NC}"
echo -e "${GREEN}Projects location: $PROJECTS_ROOT${NC}"
echo -e "${GREEN}Claude symlinks: /home/ec2-claude-user/projects/${NC}\n"
