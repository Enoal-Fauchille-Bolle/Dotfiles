#!/bin/bash

# Check the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <scan_time_in_seconds>"
    exit 1
fi

# Check if the argument is a valid number
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: the argument must be an integer."
    exit 1
fi

# Scan time
scan_time=$1

# Your scan command with the scan time
echo "Scanning for $scan_time seconds..."
pidstat -u 1 $scan_time | grep 'Average:' | sed 's/^Average://' | awk 'NR<2{print;next}{print|"sort -k7,7nr"}'

# Rest of your script here
echo "Scan completed."
