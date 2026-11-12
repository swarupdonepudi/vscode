#!/bin/sh
# Set up VS Code on this Mac to match the repo: settings, keyboard shortcuts,
# extensions, the SF Mono font and the Agent Tabs Claude plugin.
# Safe to run again: it only changes what isn't already in place.
set -eu

REPO=$(cd "$(dirname "$0")" && pwd)
USER_DIR="$HOME/Library/Application Support/Code/User"
APP="/Applications/Visual Studio Code.app"
STAMP=$(date +%Y%m%d-%H%M%S)
AGENT_TABS_REPO="swarupdonepudi/agent-tabs"

say() { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }

[ "$(uname -s)" = "Darwin" ] || { say "This setup is for macOS."; exit 1; }

# 1. VS Code and its `code` command
step "VS Code"
if [ ! -d "$APP" ]; then
  if command -v brew >/dev/null 2>&1; then
    brew install --cask visual-studio-code
  else
    say "Install VS Code from https://code.visualstudio.com (or install Homebrew), then run this again."
    exit 1
  fi
fi
CODE=$(command -v code 2>/dev/null || true)
[ -n "$CODE" ] || CODE="$APP/Contents/Resources/app/bin/code"
say "ok   $("$CODE" --version | head -n 1)"

# 2. SF Mono, the terminal font. macOS ships it inside Terminal.app.
step "SF Mono"
mkdir -p "$HOME/Library/Fonts"
copied=0
for f in /System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SF-Mono-*.otf; do
  [ -e "$f" ] || continue
  if [ ! -e "$HOME/Library/Fonts/$(basename "$f")" ]; then
    cp "$f" "$HOME/Library/Fonts/"
    copied=$((copied + 1))
  fi
done
say "ok   SF Mono installed ($copied new files)"

# 3. Settings and keyboard shortcuts, linked into this repo
step "Settings and shortcuts"
mkdir -p "$USER_DIR"
link() {
  src="$REPO/$1"
  dst="$USER_DIR/$1"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "ok   $1 already linked"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.before-setup-$STAMP"
    say "     your old $1 is saved as $1.before-setup-$STAMP"
  fi
  ln -s "$src" "$dst"
  say "ok   $1 linked to this repo"
}
link settings.json
link keybindings.json

# 4. Extensions
step "Extensions"
installed=$("$CODE" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
has_ext() { printf '%s\n' "$installed" | grep -qx "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"; }
while IFS= read -r ext || [ -n "$ext" ]; do
  case "$ext" in "" | \#*) continue ;; esac
  if has_ext "$ext"; then
    say "ok   $ext"
  else
    "$CODE" --install-extension "$ext" >/dev/null
    say "ok   $ext installed"
  fi
done <"$REPO/extensions.txt"

if has_ext "swarupdonepudi.agent-tabs"; then
  say "ok   swarupdonepudi.agent-tabs"
else
  url=$(curl -fsSL "https://api.github.com/repos/$AGENT_TABS_REPO/releases/latest" |
    sed -n 's/.*"browser_download_url": *"\([^"]*\.vsix\)".*/\1/p' | head -n 1)
  if [ -n "$url" ]; then
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/agent-tabs.vsix" "$url"
    "$CODE" --install-extension "$tmp/agent-tabs.vsix" >/dev/null
    rm -rf "$tmp"
    say "ok   swarupdonepudi.agent-tabs installed from its latest release"
  else
    say "!!   couldn't find the Agent Tabs release; install it from https://github.com/$AGENT_TABS_REPO/releases"
  fi
fi

# 5. The Agent Tabs Claude plugin, so tabs come back after a restart
step "Claude Code plugin"
if command -v claude >/dev/null 2>&1; then
  if claude plugin list 2>/dev/null | grep -q "agent-tabs@agent-tabs"; then
    say "ok   agent-tabs plugin"
  else
    claude plugin marketplace list 2>/dev/null | grep -q "agent-tabs" ||
      claude plugin marketplace add "$AGENT_TABS_REPO" >/dev/null
    claude plugin install agent-tabs@agent-tabs >/dev/null
    say "ok   agent-tabs plugin installed"
  fi
else
  say "!!   Claude Code isn't installed. Install it (https://claude.com/claude-code), then run this again."
fi

step "Done"
say "Reload VS Code once (⌘⇧P → Reload Window) if it was open."
