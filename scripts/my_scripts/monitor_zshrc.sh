#!/bin/bash
file="$HOME/.zshrc"
logfile="$HOME/zshrc_changes.log"

inotifywait -m "$file" -e modify | while read path action file; do
    echo "$(date): $file was modified" >> "$logfile"
    notify-send "Alert" "$(file) was modified"
done
