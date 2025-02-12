#!/bin/bash

# install uv first

cd $HOME

uv venv myenv --python 3.12 --seed

source myenv/bin/activate

uv pip install vllm

