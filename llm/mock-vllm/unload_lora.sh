#!/bin/bash

#!/bin/bash

POD="${1:-default}"

LORA="${2:-default}"

kubectl exec $POD -- \
    curl -X POST http://localhost:8000/v1/unload_lora_adapter \
    -H "Content-Type: application/json" \
    -d "{\"lora_name\": \"$LORA\"}"
