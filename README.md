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
4. Installs the extensions in `extensions.txt` and [Agent Tabs](https://github.com/swarupdonepudi/agent-tabs).
5. Installs the Agent Tabs plugin for Claude Code.

Because the two files are links, a change made in VS Code lands in this repo. Commit and push it, and `git pull` brings it to your other Macs.

## What you get

**Look:** the Cursor Dark Midnight theme ([Cursor Themes for VS Code](https://marketplace.visualstudio.com/items?itemName=evanlong.cursor-themes)), and a terminal in calm blue-grey text (#8b97ae on #1e2127) set in SF Mono 14 with 1.35 line spacing. Markdown wraps at 100 characters.

**Keys in the terminal:**

| Keys | What it does |
|---|---|
| ⌘T | New tab running `claude --chrome` (Agent Tabs) |
| ⌘⇧T | New tab from a past conversation |
| ⌘W | Close the tab |
| ⌘R | Clear the screen, keep the scrollback |
| ⌘0 | Focus the terminal (the tab you were last in), from anywhere |
| ⌘1 to ⌘9 | Jump to terminal tab 1 to 9, from anywhere |
| ⌘⇧↩ | Focus the terminal and maximise it, from anywhere |

**Quiet:** no extension recommendations, no "History restored" banners, and a confirmation before ⌘W closes the window. On reopen, VS Code restores the windows you had open.

**Agent tabs that survive a restart:** quit VS Code and reopen it, and every Claude tab comes back in its own conversation.

## Make it yours

- `agentTabs.defaultFolder` in `settings.json` is the workspace folder new agent tabs open in (mine is `planton-platform`).
- `agentTabs.extraArgs` holds the flags every Claude tab starts with (mine is `--chrome`).

## License

MIT
