#!/bin/bash
set -euo pipefail

echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# .zshrc に PATH を追加（未追加の場合のみ）
ZSHRC="${HOME}/.zshrc"
if [ -f "$ZSHRC" ] && ! grep -q 'local/bin/env' "$ZSHRC"; then
    echo 'source $HOME/.local/bin/env' >> "$ZSHRC"
    echo "Added uv to .zshrc PATH"
fi

echo "uv setup complete."
