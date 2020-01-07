#!/bin/bash

# Usage: bash dockerImageDelete.sh $image

for i in `docker images | grep $1 | awk '{print $3}'`
do
  docker rmi -f $i
done

