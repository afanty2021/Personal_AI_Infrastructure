#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  PAI Status Bar Export Script
#  从当前电脑导出状态栏配置，用于迁移到其他电脑
# ═══════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────
BLUE='\033[38;2;59;130;246m'
GREEN='\033[38;2;34;197;94m'
YELLOW='\033[38;2;234;179;8m'
RED='\033[38;2;239;68;68m'
SILVER='\033[38;2;203;213;225m'
STEEL='\033[38;2;51;65;85M'
RESET='\033[0m'
BOLD='\033[1m'

# ─── Helpers ───────────────────────────────────────────────────────────────
info()    { echo -e "  ${BLUE}ℹ${RESET} $1"; }
success() { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET} $1"; }
error()   { echo -e "  ${RED}✗${RESET} $1"; }

# ─── Banner ───────────────────────────────────────────────────────────────
echo ""
echo -e "${STEEL}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
echo -e "                        ${BLUE}PAI Status Bar${RESET} ${SILVER}Export${RESET}"
echo -e "${STEEL}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
echo ""

# ─── Detect OS ────────────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
info "Running on: $OS $ARCH"

# ─── Set paths ────────────────────────────────────────────────────────────
PAI_DIR="${HOME}/.claude"
EXPORT_DIR="${PAI_DIR}/export"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PACKAGE_NAME="pai-statusbar-${OS}-${ARCH}-${TIMESTAMP}"
PACKAGE_DIR="${EXPORT_DIR}/${PACKAGE_NAME}"

# ─── Create export directory ──────────────────────────────────────────────
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"
success "Created export directory: ${PACKAGE_DIR}"

# ─── Copy statusline script ───────────────────────────────────────────────
if [ -f "${PAI_DIR}/statusline-command.sh" ]; then
    cp "${PAI_DIR}/statusline-command.sh" "${PACKAGE_DIR}/"
    chmod +x "${PACKAGE_DIR}/statusline-command.sh"
    success "Exported statusline-command.sh"
else
    error "statusline-command.sh not found at ${PAI_DIR}/statusline-command.sh"
    exit 1
fi

# ─── Extract and export statusLine config from settings.json ───────────────
if [ -f "${PAI_DIR}/settings.json" ]; then
    # Extract the statusLine configuration
    STATUS_LINE_CONFIG=$(jq -c '.statusLine // empty' "${PAI_DIR}/settings.json" 2>/dev/null || echo '{}')
    if [ "$STATUS_LINE_CONFIG" != "null" ] && [ -n "$STATUS_LINE_CONFIG" ]; then
        echo "$STATUS_LINE_CONFIG" > "${PACKAGE_DIR}/statusline-config.json"
        success "Exported statusLine configuration"
    else
        warn "No statusLine config found in settings.json"
        # Create a default config template
        cat > "${PACKAGE_DIR}/statusline-config.json" << 'EOF'
{
  "type": "command",
  "command": "~/.claude/statusline-command.sh"
}
EOF
        info "Created default statusLine config template"
    fi
else
    warn "settings.json not found, creating default config"
    cat > "${PACKAGE_DIR}/statusline-config.json" << 'EOF'
{
  "type": "command",
  "command": "~/.claude/statusline-command.sh"
}
EOF
fi

# ─── Create install script ─────────────────────────────────────────────────
cat > "${PACKAGE_DIR}/install.sh" << 'INSTALL_SCRIPT_EOF'
#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  PAI Status Bar Install Script
#  在目标电脑上安装状态栏配置
# ═══════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────
BLUE='\033[38;2;59;130;246m'
GREEN='\033[38;2;34;197;94m'
YELLOW='\033[38;2;234;179;8m'
RED='\033[38;2;239;68;68m'
SILVER='\033[38;2;203;213;225m'
STEEL='\033[38;2;51;65;85M'
RESET='\033[0m'

info()    { echo -e "  ${BLUE}ℹ${RESET} $1"; }
success() { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET} $1"; }
error()   { echo -e "  ${RED}✗${RESET} $1"; }

# ─── Banner ───────────────────────────────────────────────────────────────
echo ""
echo -e "${STEEL}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
echo -e "                        ${BLUE}PAI Status Bar${RESET} ${SILVER}Installer${RESET}"
echo -e "${STEEL}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
echo ""

# ─── Detect OS ────────────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
info "Target platform: $OS $ARCH"

# ─── Set paths ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAI_DIR="${HOME}/.claude"
TARGET_SCRIPT="${PAI_DIR}/statusline-command.sh"
TARGET_SETTINGS="${PAI_DIR}/settings.json"

# ─── Create PAI directory if not exists ────────────────────────────────────
if [ ! -d "$PAI_DIR" ]; then
    mkdir -p "$PAI_DIR"
    success "Created PAI directory: $PAI_DIR"
else
    info "PAI directory exists: $PAI_DIR"
fi

# ─── Backup existing statusline script ────────────────────────────────────
if [ -f "$TARGET_SCRIPT" ]; then
    BACKUP_FILE="${PAI_DIR}/statusline-command.sh.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$TARGET_SCRIPT" "$BACKUP_FILE"
    info "Backed up existing script to: $(basename "$BACKUP_FILE")"
fi

# ─── Install statusline script ─────────────────────────────────────────────
if [ -f "${SCRIPT_DIR}/statusline-command.sh" ]; then
    cp "${SCRIPT_DIR}/statusline-command.sh" "$TARGET_SCRIPT"
    chmod +x "$TARGET_SCRIPT"
    success "Installed statusline-command.sh"
else
    error "statusline-command.sh not found in package"
    exit 1
fi

# ─── Update settings.json ─────────────────────────────────────────────────
# Ensure jq is available
if ! command -v jq &>/dev/null; then
    warn "jq not found. Attempting to install..."

    if [[ "$OS" == "Darwin" ]]; then
        if command -v brew &>/dev/null; then
            brew install jq
        else
            error "Homebrew not found. Please install jq manually: brew install jq"
            exit 1
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &>/dev/null; then
            sudo yum install -y jq
        else
            error "Please install jq manually"
            exit 1
        fi
    fi
fi

# Merge statusLine config into settings.json
if [ -f "${SCRIPT_DIR}/statusline-config.json" ]; then
    # Read the config
    STATUS_CONFIG=$(cat "${SCRIPT_DIR}/statusline-config.json")

    # Update or create settings.json
    if [ -f "$TARGET_SETTINGS" ]; then
        # Backup settings.json
        cp "$TARGET_SETTINGS" "${TARGET_SETTINGS}.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backed up settings.json"

        # Merge statusLine config
        TEMP_FILE=$(mktemp)
        jq --argjson sl "$STATUS_CONFIG" '.statusLine = $sl' "$TARGET_SETTINGS" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$TARGET_SETTINGS"
        success "Updated settings.json with statusLine config"
    else
        # Create new settings.json
        cat > "$TARGET_SETTINGS" << EOF
{
  "statusLine": $STATUS_CONFIG
}
EOF
        success "Created settings.json with statusLine config"
    fi
else
    warn "statusline-config.json not found, creating default config"
    # Add default config to settings.json
    if [ -f "$TARGET_SETTINGS" ]; then
        TEMP_FILE=$(mktemp)
        jq '.statusLine = {"type": "command", "command": "~/.claude/statusline-command.sh"}' "$TARGET_SETTINGS" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$TARGET_SETTINGS"
    else
        cat > "$TARGET_SETTINGS" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  }
}
EOF
    fi
    success "Added default statusLine config to settings.json"
fi

# ─── Verify installation ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
success "PAI Status Bar installed successfully!"
echo ""
echo -e "${SILVER}  Installed files:${RESET}"
echo -e "    • ${BLUE}~/.claude/statusline-command.sh${RESET}"
echo -e "    • ${BLUE}~/.claude/settings.json${RESET} (updated)"
echo ""
echo -e "${YELLOW}  Next steps:${RESET}"
echo -e "    1. Restart Claude Code"
echo -e "    2. The status bar should appear at the bottom of the terminal"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
INSTALL_SCRIPT_EOF

chmod +x "${PACKAGE_DIR}/install.sh"
success "Created install script"

# ─── Create README ─────────────────────────────────────────────────────────
cat > "${PACKAGE_DIR}/README.md" << 'EOF'
# PAI Status Bar - 迁移包

此包包含 PAI 状态栏配置，可在其他电脑上安装以获得相同的状态栏效果。

## 状态栏效果

```
CC 1.0.0 → project-name [main] ✓ (45%) ⏰ 14:30 🤖 glm-4.7
```

显示内容：
- **CC 版本** - Claude Code 版本号
- **项目名** - 当前工作目录名称
- **Git 分支** - 当前 Git 分支（如果在仓库中）
- **Git 状态** - ✓ 表示干净，✗ 表示有未提交更改
- **上下文使用率** - 当前会话上下文使用百分比
- **时间** - 当前时间
- **模型** - 当前使用的 AI 模型

## 安装步骤

### 方法一：自动安装（推荐）

```bash
cd pai-statusbar-*
./install.sh
```

### 方法二：手动安装

1. 复制 `statusline-command.sh` 到 `~/.claude/`：
```bash
cp statusline-command.sh ~/.claude/
chmod +x ~/.claude/statusline-command.sh
```

2. 在 `~/.claude/settings.json` 中添加（或更新）：
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  }
}
```

3. 重启 Claude Code

## 系统要求

- **操作系统**: macOS 或 Linux
- **依赖**: jq (JSON 处理工具)，会自动安装
- **Claude Code**: 已安装 Claude Code CLI

## 卸载

编辑 `~/.claude/settings.json`，删除 `statusLine` 配置段。

## 故障排除

如果状态栏不显示：
1. 确认 `~/.claude/statusline-command.sh` 有执行权限
2. 确认 `~/.claude/settings.json` 中的路径正确
3. 重启 Claude Code
4. 检查 Claude Code 是否支持 statusLine 配置

## 自定义

编辑 `~/.claude/statusline-command.sh` 可以自定义状态栏的显示内容和样式。
EOF

success "Created README"

# ─── Create package ───────────────────────────────────────────────────────
cd "$EXPORT_DIR"
tar czf "${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}/"
PACKAGE_PATH="${EXPORT_DIR}/${PACKAGE_NAME}.tar.gz"

# ─── Summary ───────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
success "PAI Status Bar package created successfully!"
echo ""
echo -e "${SILVER}  Package location:${RESET}"
echo -e "    ${BLUE}${PACKAGE_PATH}${RESET}"
echo ""
echo -e "${SILVER}  Package contents:${RESET}"
echo -e "    • statusline-command.sh    (状态栏脚本)"
echo -e "    • statusline-config.json   (配置模板)"
echo -e "    • install.sh               (安装脚本)"
echo -e "    • README.md                (说明文档)"
echo ""
echo -e "${YELLOW}  Transfer to target computer:${RESET}"
echo -e "    scp ${PACKAGE_PATH} user@target:~/"
echo ""
echo -e "${YELLOW}  Install on target computer:${RESET}"
echo -e "    cd ~"
echo -e "    tar xzf ${PACKAGE_NAME}.tar.gz"
echo -e "    cd ${PACKAGE_NAME}"
echo -e "    ./install.sh"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
EOF
