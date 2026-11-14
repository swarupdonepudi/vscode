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

# Agent Tabs comes from its latest GitHub release, and is upgraded when a newer one is out.
release=$(curl -fsSL "https://api.github.com/repos/$AGENT_TABS_REPO/releases/latest" || true)
latest=$(printf '%s\n' "$release" | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -n 1)
url=$(printf '%s\n' "$release" | sed -n 's/.*"browser_download_url": *"\([^"]*\.vsix\)".*/\1/p' | head -n 1)
current=$("$CODE" --list-extensions --show-versions 2>/dev/null | grep -i '^swarupdonepudi\.agent-tabs@' | sed 's/.*@//' || true)
if [ -n "$current" ] && { [ -z "$latest" ] || [ "$current" = "$latest" ]; }; then
  say "ok   swarupdonepudi.agent-tabs $current"
elif [ -n "$url" ]; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/agent-tabs.vsix" "$url"
  "$CODE" --install-extension "$tmp/agent-tabs.vsix" --force >/dev/null
  rm -rf "$tmp"
  say "ok   swarupdonepudi.agent-tabs $latest installed"
else
  say "!!   couldn't find the Agent Tabs release; install it from https://github.com/$AGENT_TABS_REPO/releases"
fi

# 5. The Agent Tabs Claude plugin, so tabs come back after a restart and show
#    what each agent is doing. Installed if missing, upgraded otherwise.
step "Claude Code plugin"
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace list 2>/dev/null | grep -q "agent-tabs" ||
    claude plugin marketplace add "$AGENT_TABS_REPO" >/dev/null
  if claude plugin list 2>/dev/null | grep -q "agent-tabs@agent-tabs"; then
    claude plugin marketplace update agent-tabs >/dev/null 2>&1 || true
    claude plugin update agent-tabs@agent-tabs >/dev/null 2>&1 || true
    say "ok   agent-tabs plugin up to date (restart Claude sessions to apply)"
  else
    claude plugin install agent-tabs@agent-tabs >/dev/null
    say "ok   agent-tabs plugin installed"
  fi
else
  say "!!   Claude Code isn't installed. Install it (https://claude.com/claude-code), then run this again."
fi

# 6. Claude Code's own terminal progress bar off. Agent Tabs' status icon uses
#    the same terminal signal, and Claude's own would overwrite its alert icon.
step "Claude Code settings"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
# Sets the key with macOS's built-in JavaScript: every other key and Claude's
# 2-space format stay as they were, and a linked file is written through the link.
# shellcheck disable=SC2016 # JavaScript, not shell: $ is literal
PROGRESS_JS='ObjC.import("Foundation");
function run(argv) {
  const path = $(argv[0]).stringByResolvingSymlinksInPath.js;
  const text = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null);
  const settings = text.isNil() ? {} : JSON.parse(text.js);
  if (settings.terminalProgressBarEnabled === false) return "already";
  settings.terminalProgressBarEnabled = false;
  $(JSON.stringify(settings, null, 2) + "\n").writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
  return "set";
}'
mkdir -p "$HOME/.claude"
if [ -f "$CLAUDE_SETTINGS" ] && grep -q '"terminalProgressBarEnabled": *false' "$CLAUDE_SETTINGS"; then
  say "ok   Claude's own progress bar already off"
else
  [ -f "$CLAUDE_SETTINGS" ] && cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.before-setup-$STAMP"
  if result=$(osascript -l JavaScript -e "$PROGRESS_JS" "$CLAUDE_SETTINGS" 2>&1); then
    say "ok   Claude's own progress bar $( [ "$result" = set ] && echo "turned off" || echo "already off" )"
  else
    say "!!   couldn't edit $CLAUDE_SETTINGS ($result). Set \"terminalProgressBarEnabled\": false in it yourself."
  fi
fi

# 7. Short titles for plain shell tabs. VS Code shows the title the shell sets,
#    and oh-my-zsh's default is user@host:~/path.
step "Shell tab titles"
ZSHRC="$HOME/.zshrc"
# shellcheck disable=SC2016 # written into ~/.zshrc as is
TITLE_LINE='[[ "$TERM_PROGRAM" == vscode ]] && ZSH_THEME_TERM_TITLE_IDLE="zsh"'
if [ ! -f "$ZSHRC" ] || ! grep -q 'source .*oh-my-zsh\.sh' "$ZSHRC"; then
  say "ok   not needed (~/.zshrc doesn't load oh-my-zsh)"
elif grep -qF "$TITLE_LINE" "$ZSHRC"; then
  say "ok   short shell titles already set"
else
  backup="$ZSHRC.before-setup-$STAMP"
  cp "$ZSHRC" "$backup"
  awk -v line="$TITLE_LINE" '{ print }
    !done && /^[[:space:]]*source[[:space:]].*oh-my-zsh\.sh/ {
      print "# VS Code tabs show the shell'"'"'s own title (Agent Tabs puts a status icon before it), so an idle shell reads \"zsh\""
      print line
      done = 1
    }' "$backup" >"$ZSHRC"
  if grep -qF "$TITLE_LINE" "$ZSHRC" && zsh -n "$ZSHRC"; then
    say "ok   short shell titles set (your old ~/.zshrc is saved as $(basename "$backup"))"
  else
    cp "$backup" "$ZSHRC"
    say "!!   couldn't add the short-title line to ~/.zshrc; it's unchanged. Add this after oh-my-zsh loads: $TITLE_LINE"
  fi
fi

step "Done"
say "Quit VS Code (⌘Q) and reopen it if it was open: Agent Tabs brings every Claude tab back."
