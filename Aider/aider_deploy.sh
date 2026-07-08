#!/bin/bash
set -e

# 1. Install system prerequisites non-interactively
sudo apt-get update -y
sudo apt-get install -y pipx python3-venv git

# 2. Deploy core AI package isolated via pipx
pipx install aider-chat
pipx ensurepath

# Core Fix: Force inject pipx path into active shell session to prevent execution blocks
export PATH="$HOME/.local/bin:$PATH"

# 3. Scaffold runtime environment directories matching flattened enterprise rules
AIDER_DIR="$HOME/.aider"
mkdir -p "$AIDER_DIR/roles"
mkdir -p "$AIDER_DIR/prompts"
mkdir -p "$AIDER_DIR/user"

# 4. Inject global execution alias into shell profile
grep -q 'aider-run' "$HOME/.bashrc" || echo "alias aider-run='$AIDER_DIR/aider_run.sh'" >> "$HOME/.bashrc"

echo "[SUCCESS] Guest package installation and path scaffolding complete."
