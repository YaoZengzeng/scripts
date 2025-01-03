#!/bin/bash


HOST="${HOST:-localhost:4000}"

curl -v http://$HOST/models
