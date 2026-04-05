#!/bin/bash
# Claude Code notification hook
# Sends a desktop notification and focuses the Terminal window running this Claude session.
#
# With terminal-notifier (brew install terminal-notifier):
#   Clicking the notification focuses the right Terminal window.
# Without terminal-notifier:
#   Notification fires and the Terminal window is immediately brought to front.

# Find the TTY of the Claude session by walking up the process tree.
# When hooks run, stdin is piped so `tty` returns "not a tty" — instead
# we look at the parent process's TTY.
MY_TTY=$(ps -p $PPID -o tty= 2>/dev/null | tr -d ' ')
[[ -z "$MY_TTY" || "$MY_TTY" == "??" ]] && MY_TTY=$(ps -p $(ps -p $PPID -o ppid= | tr -d ' ') -o tty= 2>/dev/null | tr -d ' ')

# Parse notification JSON from stdin
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty' 2>/dev/null)
NOTIF_TYPE=$(echo "$INPUT" | jq -r '.type // empty' 2>/dev/null)
[[ -z "$MESSAGE" ]] && MESSAGE="Claude needs your attention"

# Build a human-friendly title from notification type
case "$NOTIF_TYPE" in
  permission_prompt) TITLE="Claude Code — Needs Permission" ;;
  idle_prompt)       TITLE="Claude Code — Waiting for Input" ;;
  auth_success)      TITLE="Claude Code — Authenticated" ;;
  *)                 TITLE="Claude Code" ;;
esac

# Write the AppleScript to a temp file to avoid quoting issues in -execute
# Use PID-based naming — macOS mktemp doesn't support suffixes after X's
FOCUS_SCRIPT="/tmp/claude-focus-$$.scpt"
cat > "$FOCUS_SCRIPT" <<APPLESCRIPT
tell application "Terminal"
    activate
    repeat with w in every window
        repeat with t in every tab of w
            if tty of t contains "${MY_TTY}" then
                set selected tab of w to t
                set index of w to 1
                return
            end if
        end repeat
    end repeat
end tell
APPLESCRIPT

if command -v terminal-notifier &>/dev/null; then
    # Click the notification banner → focus the exact Terminal tab
    terminal-notifier \
        -title "$TITLE" \
        -message "$MESSAGE" \
        -sound "default" \
        -activate "com.apple.Terminal" \
        -execute "osascript ${FOCUS_SCRIPT}"
    # Clean up temp file after a generous window for clicking
    (sleep 120 && rm -f "$FOCUS_SCRIPT") &
else
    # No terminal-notifier: show system notification and immediately focus
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Ping\""
    osascript "$FOCUS_SCRIPT"
    rm -f "$FOCUS_SCRIPT"
fi
