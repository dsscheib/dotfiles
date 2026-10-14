#!/usr/bin/env bash
# No package installs, real-home deployments, or tmux plugin execution.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
for tool in shellcheck stow python3 zsh fish; do
  command -v "$tool" >/dev/null || { printf 'Missing check dependency: %s\n' "$tool" >&2; exit 1; }
done
shellcheck -x bootstrap.sh scripts/check.sh bash/.bashrc shell/.config/shell/common.sh
bash -n bootstrap.sh
bash -n scripts/check.sh
bash -n bash/.bashrc
bash -n shell/.config/shell/common.sh
zsh -n zsh/.zshrc
zsh -n shell/.config/shell/completion.zsh
fish --no-execute fish/.config/fish/config.fish
python3 -B -m unittest discover -s tests -v
python3 -B - <<'PY'
import ast
from pathlib import Path
for directory in ('scripts', 'tests'):
    for path in Path(directory).glob('*.py'):
        ast.parse(path.read_text(), filename=str(path))
PY
git diff --check
