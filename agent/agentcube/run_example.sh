#!/bin/bash

python3 << 'EOF'
from agentcube import CodeInterpreterClient

#with CodeInterpreterClient(name="my-interpreter") as client:
#    result = client.run_code("python", "print('Hello from AgentCube!')")
#    print(result)

client = CodeInterpreterClient(name="my-interpreter")
result = client.run_code("python", "print('hello')")
print(result)
EOF
