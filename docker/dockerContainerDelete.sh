#!/bin/bash

# Usage: bash dockerContainerDelete.sh $image

for i in `docker ps | grep $1 | awk '{print $1}'`
do
  docker rm -f $i
done

