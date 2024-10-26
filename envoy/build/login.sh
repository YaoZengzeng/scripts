#!/bin/bash

USERNAME="yaozengzeng"

CR_PAT=${1-"your-token"}

echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
