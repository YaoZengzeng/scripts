#!/bin/bash

# port forward kthena-router to localhost:80 first

resource="${1:-"modelroutes"}"

path="/debug/config_dump/$resource"

curl 127.0.0.1:8080$path | jq .
