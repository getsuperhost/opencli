#!/bin/bash

# Watcher script to monitor changes in a directory
WATCH_DIR="/var/log/openpanel"
LOG_FILE="/var/log/watcher.log"

# Ensure the log file exists
touch "$LOG_FILE"

# Monitor the directory for changes
inotifywait -m -r -e modify,create,delete "$WATCH_DIR" --format '%T %w %f %e' --timefmt '%Y-%m-%d %H:%M:%S' >> "$LOG_FILE" &
