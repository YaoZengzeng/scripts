#!/bin/bash

NAMESPACE="${1:-ollama}"

helm delete ollama --namespace $NAMESPACE
