on run argv
    set myTTY to item 1 of argv
    tell application "iTerm2"
        activate
        repeat with w in every window
            repeat with t in every tab of w
                repeat with s in every session of t
                    if tty of s contains myTTY then
                        select t
                        set index of w to 1
                        return
                    end if
                end repeat
            end repeat
        end repeat
    end tell
end run
