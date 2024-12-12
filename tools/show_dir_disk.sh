#!/bin/bash

DIR=${1:-.}

echo "disk usage:"
echo "====================="
du -h --max-depth=1 "$DIR" | sort -hr
echo "====================="
