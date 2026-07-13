#!/bin/bash
# Verify the EPD-disaggregated Qwen2-VL deployment end-to-end.
# Port-forwards the proxy Service and sends a real multimodal (image) request.
set -euo pipefail

NS="${NS:-epd-disagg}"
SVC="${SVC:-epd-proxy}"
LOCAL_PORT="${LOCAL_PORT:-8000}"
MODEL="${MODEL:-Qwen/Qwen2-VL-2B-Instruct}"
# Canonical vLLM test image (two cats). The vLLM engines fetch it, so the Pod
# needs egress. Override IMAGE_URL with a data: URL for a fully offline test.
IMAGE_URL="${IMAGE_URL:-http://images.cocodataset.org/val2017/000000039769.jpg}"

echo ">> Port-forwarding svc/$SVC ($LOCAL_PORT -> 8000)..."
kubectl -n "$NS" port-forward "svc/$SVC" "$LOCAL_PORT:8000" >/tmp/epd-pf.log 2>&1 &
PF=$!
trap 'kill "$PF" 2>/dev/null || true' EXIT

echo ">> Waiting for proxy /health..."
for _ in $(seq 1 30); do
  curl -sf "localhost:$LOCAL_PORT/health" >/dev/null 2>&1 && break
  sleep 2
done

echo ">> /v1/models :"
curl -s "localhost:$LOCAL_PORT/v1/models" | python3 -m json.tool || true

echo
echo ">> Sending multimodal chat request (image + text)..."
curl -s "localhost:$LOCAL_PORT/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "'"$MODEL"'",
    "messages": [
      {"role": "user", "content": [
        {"type": "image_url", "image_url": {"url": "'"$IMAGE_URL"'"}},
        {"type": "text", "text": "What is in this image? Answer in one sentence."}
      ]}
    ],
    "max_tokens": 64,
    "temperature": 0
  }' | tee /tmp/epd-resp.json
echo

echo
echo ">> Assistant reply:"
python3 -c "import json; d=json.load(open('/tmp/epd-resp.json')); print(d['choices'][0]['message']['content'])" \
  && echo ">> SUCCESS: EPD-disaggregated model responded." \
  || { echo ">> FAILED: see /tmp/epd-resp.json and pod logs."; exit 1; }
