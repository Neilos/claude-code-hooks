# Claude Code Hooks

A collection of hooks for [Claude Code](https://claude.ai/code) — the CLI for Claude by Anthropic.

## Hooks

### `hooks/notify.sh` — Desktop Notifications

Sends a macOS desktop notification whenever Claude needs your attention. Clicking the notification banner focuses the exact Terminal window and tab running that Claude session.

The notification will not fire if that Terminal tab is already the active, focused window.

**Notification format:**

| Field | Content |
|-------|---------|
| Title | Working directory relative to home (e.g. `~/code/my-project`) |
| Message | Notification type (e.g. `Claude Code — Waiting for Input`) |

**Notification types:**

| Event | Message |
|-------|---------|
| Waiting for input | Claude Code — Waiting for Input |
| Needs permission | Claude Code — Needs Permission |
| Authenticated | Claude Code — Authenticated |
| Other | Claude Code |

---

## Setup

### 1. Install terminal-notifier (recommended)

```bash
brew install terminal-notifier
```

Without `terminal-notifier`, notifications will still fire via `osascript` but clicking them won't focus the Terminal window — it will jump to front immediately when the hook fires instead.

### 2. Install the hook scripts

```bash
mkdir -p ~/.claude/hooks
curl -o ~/.claude/hooks/notify.sh https://raw.githubusercontent.com/Neilos/claude-code-hooks/main/hooks/notify.sh
curl -o ~/.claude/hooks/focus-terminal.scpt https://raw.githubusercontent.com/Neilos/claude-code-hooks/main/hooks/focus-terminal.scpt
chmod +x ~/.claude/hooks/notify.sh
```

### 3. Register the hook in Claude Code settings

Add the following to `~/.claude/settings.json` (create it if it doesn't exist):

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/YOUR_USERNAME/.claude/hooks/notify.sh"
          }
        ]
      }
    ]
  }
}
```

Replace `YOUR_USERNAME` with your macOS username. Use an absolute path — tilde (`~`) is not expanded in Claude Code settings.

### 4. Enable notifications for terminal-notifier

1. Open **System Settings → Notifications**
2. Find **terminal-notifier** in the list
3. Set Alert Style to **Persistent** (stays until dismissed) or **Temporary** (auto-dismisses)
4. Enable **Desktop**, **Notification Centre**, and **Play sound**

### 5. Test it

```bash
echo '{"message": "Test notification", "type": "idle_prompt"}' | ~/.claude/hooks/notify.sh
```

You should see a notification banner. Clicking it will focus the Terminal window you ran the command from.

---

## How it works

When a `Notification` event fires, Claude Code runs the hook script and passes a JSON payload on stdin. The script:

1. Walks up the process tree to find the TTY of the parent Claude session
2. Checks if that Terminal tab is already the active, focused window — if so, exits silently
3. Resolves the working directory relative to `$HOME` for the notification title
4. Calls `terminal-notifier` with `-execute` pointing to `focus-terminal.scpt`, passing the TTY as an argument

`focus-terminal.scpt` is a permanent AppleScript that accepts a TTY argument and focuses the matching Terminal window. Because the TTY is passed at click-time rather than baked into a temp file, clicking the notification will focus the correct window no matter when you click it.

---

## Compatibility

- macOS only (uses AppleScript and Terminal.app)
- Requires [Claude Code](https://claude.ai/code)
- Requires [Homebrew](https://brew.sh) for `terminal-notifier`
