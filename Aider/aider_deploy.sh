#!/bin/bash
set -e

# 1. Install system prerequisites non-interactively
sudo apt-get update -y
sudo apt-get install -y pipx python3-venv git

# 2. Deploy core AI package isolated via pipx with explicit version locking
# Pinning version prevents upstream updates from breaking middleware config compatibility
pipx install aider-chat==0.74.0 --force
pipx ensurepath

# Core Fix: Force inject pipx path into active shell session to prevent execution blocks
export PATH="$HOME/.local/bin:$PATH"

# 3. Inject global execution alias into shell profile
AIDER_DIR="$HOME/.aider"
grep -q 'aider-run' "$HOME/.bashrc" || echo "alias aider-run='$AIDER_DIR/aider_run.sh'" >> "$HOME/.bashrc"

echo "[SUCCESS] Guest package installation and profile aliases aligned."
