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

# Build relative path from home directory for use as notification title
REL_PATH="${PWD/#$HOME/~}"

# Permanent focus script — TTY is passed as an argument at runtime
FOCUS_SCRIPT="$(dirname "$0")/focus-terminal.scpt"

# Skip notification if this Terminal tab is already the active, focused window
IS_ACTIVE=$(osascript 2>/dev/null <<APPLESCRIPT
tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
end tell
if frontApp is "Terminal" then
    tell application "Terminal"
        set frontTab to selected tab of front window
        if tty of frontTab contains "${MY_TTY}" then
            return "active"
        end if
    end tell
end if
return "inactive"
APPLESCRIPT
)
[[ "$IS_ACTIVE" == "active" ]] && exit 0

if command -v terminal-notifier &>/dev/null; then
    # Click the notification banner → focus the exact Terminal tab
    terminal-notifier \
        -title "$REL_PATH" \
        -message "$TITLE" \
        -sound "default" \
        -activate "com.apple.Terminal" \
        -execute "osascript ${FOCUS_SCRIPT} ${MY_TTY}"
else
    # No terminal-notifier: show system notification and immediately focus
    osascript -e "display notification \"$TITLE\" with title \"$REL_PATH\" sound name \"Ping\""
    osascript "$FOCUS_SCRIPT" "$MY_TTY"
fi
