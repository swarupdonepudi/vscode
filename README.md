# VS Code for terminal coding agents

My VS Code setup, in one command. I run Claude Code in VS Code's terminal, not in an editor's built-in agent, so this setup makes the terminal the main surface. It reads like my iTerm, works like iTerm on the keyboard, and every agent tab comes back after a restart.

## Set up a Mac

```sh
gh repo clone swarupdonepudi/vscode ~/scm/github.com/swarupdonepudi/vscode
~/scm/github.com/swarupdonepudi/vscode/setup.sh
```

`setup.sh` is safe to run again. It:

1. Installs VS Code with Homebrew if it's missing.
2. Copies SF Mono, Apple's monospaced font, from Terminal.app into `~/Library/Fonts`.
3. Saves your existing `settings.json` and `keybindings.json` next to themselves, then links both to this repo.
4. Installs the extensions in `extensions.txt`, and installs or upgrades [Agent Tabs](https://github.com/swarupdonepudi/agent-tabs) to its latest release.
5. Installs the Agent Tabs plugin for Claude Code.

Because the two files are links, a change made in VS Code lands in this repo. Commit and push it, and `git pull && ./setup.sh` brings it to your other Macs.

## What you get

**Look:** the Cursor Dark Midnight theme ([Cursor Themes for VS Code](https://marketplace.visualstudio.com/items?itemName=evanlong.cursor-themes)), and a terminal in calm blue-grey text (#8b97ae on #1e2127) set in SF Mono 14 with 1.35 line spacing. Markdown wraps at 100 characters.

**Keys in the terminal:**

| Keys | What it does |
|---|---|
| ⌘T | New tab running `claude --chrome` (Agent Tabs), from anywhere, even with no terminal open |
| ⌘⌥T | New Claude tab in a folder you pick (workspace folders, recent picks or Browse…), from anywhere |
| ⌘⇧T | New tab from a past conversation |
| ⌘W | Close the tab |
| ⌘R | Clear the screen, keep the scrollback |
| ⌘0 | Focus the terminal (the tab you were last in), from anywhere |
| ⌘1 to ⌘9 | Jump to terminal tab 1 to 9, from anywhere |
| ⌘⇧↩ | Focus the terminal and maximise it, from anywhere |
| ⇧↩ | In Claude Code, a new line instead of sending the message |
| ⌃↩ | In Claude Code, send now instead of queueing behind the running turn |
| ⌃- / ⌃⇧B | In Claude Code, undo the last edit / toggle brief mode |
| ⌘⌥↑ / ⌘⌥↓ | Previous / next terminal tab, wrapping around |

**Quiet:** no extension recommendations, no "History restored" banners, and a confirmation before ⌘W closes the window. On reopen, VS Code restores the windows you had open.

**One click focuses a terminal tab:** clicking a tab puts the cursor in it, like ⌘1–⌘9 do.

**Agent tabs that survive a restart:** quit VS Code and reopen it, and every Claude tab comes back in its own conversation.

## Claude Code keys

Every Claude Code shortcut works as it does in iTerm. Most keys need nothing: VS Code's terminal sends Claude the same bytes iTerm does. Four don't. Without the kitty keyboard protocol, VS Code's terminal sends ⇧↩ and ⌃↩ as a plain Enter, and sends ⌃- and ⌃⇧B as nothing at all. `keybindings.json` fixes them:

- ⇧↩ sends exactly what ⌥↩ sends (`ESC` then Enter), which Claude reads as a new line. In a zsh tab it acts like Enter.
- ⌃↩, ⌃- and ⌃⇧B send the sequences iTerm sends (`ESC[13;5u`, `ESC[45;5u`, `ESC[98;6u`). Claude reads them whether or not it turned the protocol on.

The mappings apply in every terminal tab. VS Code can't tell a Claude tab from a shell tab on macOS: its `claude` shell type exists only on Windows. So in a zsh tab, ⌃↩, ⌃- and ⌃⇧B send an escape code instead of nothing. Two keys behave like iTerm for a different reason: ⌃↑ and ⌃↓ belong to macOS Mission Control, and ⌘K clears the terminal in VS Code as it does in iTerm.

## Make it yours

- New agent tabs open in the first workspace folder. To pick another folder on a Mac, add `export AGENT_TABS_FOLDER=<folder name or ~/path>` to `~/.zshrc`, then quit and reopen VS Code (mine is `planton-platform`).
- `agentTabs.extraArgs` holds the flags every Claude tab starts with (mine is `--chrome`).

## License

MIT
