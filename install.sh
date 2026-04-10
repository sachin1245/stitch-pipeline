#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$HOME/.claude/plugins/stitch-pipeline"
REPO_URL="https://github.com/sachin1245/stitch-pipeline.git"

echo ""
echo "  stitch-pipeline installer"
echo "  ========================="
echo ""

# Ensure parent directory exists
mkdir -p "$HOME/.claude/plugins"

if [ -d "$PLUGIN_DIR/.git" ]; then
  echo "  Existing installation found. Updating..."
  cd "$PLUGIN_DIR"
  git pull --ff-only origin main 2>/dev/null || git pull origin main
  echo ""
  echo "  Updated successfully."
elif [ -d "$PLUGIN_DIR" ]; then
  echo "  Directory exists but is not a git repo."
  echo "  Back up and remove $PLUGIN_DIR, then re-run this script."
  exit 1
else
  echo "  Installing to $PLUGIN_DIR..."
  git clone "$REPO_URL" "$PLUGIN_DIR"
  echo ""
  echo "  Installed successfully."
fi

# Check for claude CLI
echo ""
if command -v claude &>/dev/null; then
  echo "  Claude CLI detected."
else
  echo "  Note: 'claude' CLI not found in PATH."
  echo "  Install Claude Code: https://docs.anthropic.com/en/docs/claude-code"
fi

echo ""
echo "  Next steps:"
echo ""
echo "  1. Add the Stitch MCP server (one-time):"
echo ""
echo "     claude mcp add stitch-mcp -s user \\"
echo "       -e GOOGLE_CLOUD_PROJECT=stitch-96cd6 \\"
echo "       -- npx -y stitch-mcp-auto"
echo ""
echo "  2. Restart Claude Code, then run in any project:"
echo ""
echo "     /stitch-pipeline"
echo ""
echo "  Docs: https://github.com/sachin1245/stitch-pipeline"
echo ""
