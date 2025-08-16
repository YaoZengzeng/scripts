#!/bin/sh
echo "\nSigned-off-by: $(git config user.name) <$(git config user.email)>" >> "$1"

### Put this in your .git/hooks/commit-msg
### chmod +x .git/hooks/commit-msg
