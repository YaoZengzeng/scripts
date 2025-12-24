#!/usr/bin/env bash

AUTHOR="yaozengzeng@huawei.com"
SINCE_DATE="2025-01-01"

# Repository paths array - edit this array to specify multiple repositories
# Example: REPOS=("/path/to/repo1" "/path/to/repo2" "/path/to/repo3")
REPOS=("/root/kmesh" "/root/kthena" "/root/agentcube" "/root/istio" "/root/orion")

function contributions {
  local repo_path="$1"
  
  if [ ! -d "$repo_path" ]; then
    echo "Error: Repository path does not exist: $repo_path" >&2
    return 1
  fi
  
  if [ ! -d "$repo_path/.git" ]; then
    echo "Error: Not a valid Git repository: $repo_path" >&2
    return 1
  fi
  
  cd "$repo_path" && git log --no-merges --since ${SINCE_DATE} --author "${AUTHOR}"  --numstat |\
    grep -v "vendor" |\
    grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" | sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$1+$2}END{print total}'
}

# Calculate statistics for each repository and sum them up
TOTAL=0
for repo in "${REPOS[@]}"; do
  repo_name=$(basename "$repo")
  repo_count=$(contributions "$repo")
  if [ $? -eq 0 ] && [ -n "$repo_count" ]; then
    echo "$repo_name: $repo_count"
    if [ "$repo_count" -eq "$repo_count" ] 2>/dev/null; then
      TOTAL=$((TOTAL + repo_count))
    fi
  fi
done

echo "----------------------------------------"
echo "Total: $TOTAL"

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period {
  git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}"  --numstat |\
    grep -v "vendor" |\
    grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" | sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$1+$2}END{print total}'
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function changes-period {
  git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}"  --numstat |\
    grep -v "vendor" |\
    grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
    grep -P "^\d+\t\d+|^commit|^Author"
}
