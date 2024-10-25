#!/bin/bash

# fetch all tags
git fetch --tags

# fetch all branches
git fetch --all

# push all tags
git push origin --tags

# push all branches
git push origin --all

# checkout to specific tag
git checkout -b new-branch-name tags/v1.0
