#!/bin/bash

# Check if any arguments are provided
if [ "$#" -eq 0 ]; then
    echo "Please provide at least one Docker image name as an argument."
    exit 1
fi

# Iterate over all command line arguments
for image in "$@"; do
    # Use sed to replace the image's Hub
    new_image=$(echo "$image" | sed 's|^[^/]*|localhost:5000|')
    echo "$new_image"
    docker tag $image $new_image
    docker push $new_image
done
