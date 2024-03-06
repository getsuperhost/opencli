#!/bin/bash
username="$1"
# Function to disable UFW rules for ports containing the username
disable_ports_in_ufw() {
  # Get the line numbers to delete
  line_numbers=$(ufw status numbered | awk -F'[][]' -v user="$username" '$NF ~ " " user "$" {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' |sort -rn)
                #ufw status numbered | awk '$NF ~ /stefan/' | awk -F '[][]' '/\[/{print "[" $2 "]"}' | sed 's/[][]//g'

  # Loop through each line number and delete the corresponding rule
  for line_number in $line_numbers; do
    yes | ufw delete $line_number
    echo "Deleted rule #$line_number"
  done
}

disable_ports_in_ufw
