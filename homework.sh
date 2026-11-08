#!/bin/bash

# Load cookies from the cookies.txt file if it exists
if [ -f "cookies.txt" ]; then
    source cookies.txt
fi

# Verify the Cookie String is actually loaded
if [ -z "$FULL_COOKIE_STRING" ]; then
    echo "Error: Missing cookies. Please add the Full Cookie String to cookies.txt"
    exit 1
fi
