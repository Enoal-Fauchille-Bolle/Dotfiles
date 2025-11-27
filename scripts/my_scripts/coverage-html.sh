#!/usr/bin/bash
mkdir -p coverage
gcovr -r . --html --html-details -o coverage/coverage.html --exclude tests/
python -m webbrowser "./coverage/coverage.html"
