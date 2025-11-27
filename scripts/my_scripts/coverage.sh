#!/usr/bin/bash
gcovr --exclude tests/ --json-summary -o coverage.json 2> /dev/null
if [ $? -ne 0 ]; then
    echo "Error: gcovr command failed."
    exit 1
fi
echo "Lines: $(grep -o '"line_percent": [0-9.]*' coverage.json | tail -n 1 | grep -o '[0-9.]*')"
echo "Branches: $(grep -o '"line_percent": [0-9.]*' coverage.json | head -n 1 | grep -o '[0-9.]*')"
rm coverage.json
