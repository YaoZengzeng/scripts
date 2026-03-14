#!/bin/bash

HASH=$(docker run --rm filebrowser/filebrowser hash password)

docker run  \
  -p 3389:80 \
  -v /root/images:/srv \
  -e FB_USERNAME=yaozengzeng \
  -e FB_PASSWORD=$HASH \
  -v /root/filebrowser.db:/database.db filebrowser/filebrowser
