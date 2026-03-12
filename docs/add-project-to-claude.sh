#!/bin/bash
#
# Add Project to Claude User Access
# Creates symlink and sets proper permissions for a new project
#
# Usage: sudo ./add-project-to-claude.sh project-name
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

# Get project name
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide project name${NC}"
    echo "Usage: sudo $0 project-name"
    exit 1
fi

PROJECT_NAME="$1"
ACTUAL_USER="${SUDO_USER:-$USER}"
PROJECTS_ROOT="/home/$ACTUAL_USER/projects"
PROJECT_PATH="$PROJECTS_ROOT/$PROJECT_NAME"
CLAUDE_PROJECTS_DIR="/home/ec2-claude-user/projects"
SYMLINK_PATH="$CLAUDE_PROJECTS_DIR/$PROJECT_NAME"

echo -e "${GREEN}Adding project '$PROJECT_NAME' to Claude user access...${NC}\n"

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project not found at $PROJECT_PATH${NC}"
    echo "Available projects:"
    ls -1 "$PROJECTS_ROOT" 2>/dev/null || echo "  (none)"
    exit 1
fi

# Ensure developers group exists
if ! getent group developers > /dev/null 2>&1; then
    groupadd developers
    usermod -a -G developers "$ACTUAL_USER"
    usermod -a -G developers ec2-claude-user
    echo "Created 'developers' group"
fi

# Set group ownership and permissions
echo "Setting permissions..."
chown -R "$ACTUAL_USER:developers" "$PROJECT_PATH"
chmod -R g+rwX "$PROJECT_PATH"

# Set setgid bit on directories
find "$PROJECT_PATH" -type d -exec chmod g+s {} \;

echo -e "${GREEN}✓ Permissions set${NC}"

# Create symlink
if [ -L "$SYMLINK_PATH" ]; then
    echo -e "${YELLOW}Symlink already exists at $SYMLINK_PATH${NC}"
elif [ -e "$SYMLINK_PATH" ]; then
    echo -e "${RED}Error: $SYMLINK_PATH exists but is not a symlink${NC}"
    exit 1
else
    ln -s "$PROJECT_PATH" "$SYMLINK_PATH"
    chown -h ec2-claude-user:ec2-claude-user "$SYMLINK_PATH"
    echo -e "${GREEN}✓ Symlink created${NC}"
fi

# Add pre-commit hook if it's a git repo
if [ -d "$PROJECT_PATH/.git" ]; then
    HOOK_PATH="$PROJECT_PATH/.git/hooks/pre-commit"

    if [ -f "$HOOK_PATH" ]; then
        echo -e "${YELLOW}Pre-commit hook already exists${NC}"
    else
        echo "Adding pre-commit hook..."
        cat > "$HOOK_PATH" << 'HOOKEOF'
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

        chmod +x "$HOOK_PATH"
        echo -e "${GREEN}✓ Pre-commit hook added${NC}"
    fi

    # Update .gitignore
    GITIGNORE="$PROJECT_PATH/.gitignore"
    if grep -q "# Secrets and Credentials (added by setup script)" "$GITIGNORE" 2>/dev/null; then
        echo -e "${YELLOW}.gitignore already has secret protection${NC}"
    else
        echo "Updating .gitignore..."
        cat >> "$GITIGNORE" << 'IGNOREEOF'

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

        echo -e "${GREEN}✓ .gitignore updated${NC}"
    fi

    # Add as safe directory for ec2-claude-user
    echo "Configuring git safe directory..."
    su - ec2-claude-user -c "git config --global --add safe.directory '$PROJECT_PATH'"
    echo -e "${GREEN}✓ Added as safe directory${NC}"
else
    echo -e "${YELLOW}Not a git repository, skipping git configuration${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Project '$PROJECT_NAME' is now accessible!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo "Claude user can now access it at:"
echo "  cd ~/projects/$PROJECT_NAME"
echo ""
echo "Test it:"
echo "  sudo su - ec2-claude-user"
echo "  cd ~/projects/$PROJECT_NAME"
echo "  ls -la"
echo ""
