on run argv
    set myTTY to item 1 of argv
    tell application "Terminal"
        activate
        repeat with w in every window
            repeat with t in every tab of w
                if tty of t contains myTTY then
                    set selected tab of w to t
                    set index of w to 1
                    return
                end if
            end repeat
        end repeat
    end tell
end run
