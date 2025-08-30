#!/bin/bash

# 循环执行100次
for i in {1..100}; do
    echo "=== 执行第 $i 次 ==="
    
    # 执行原始脚本并捕获输出
    output=$(bash llm/gateway/verify-ai-gateway-weighted-routing.sh 2>&1)
    
    # 显示输出
    echo "$output"
    
    # 在输出中grep指定的字符串
    echo "--- 查找 'deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B-v' ---"
    echo "$output" | grep "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B-v" || echo "未找到匹配的字符串"
    
    echo "=========================================="
    echo ""
    
    # 可选：添加延迟避免请求过于频繁
    sleep 0.1
done

echo "100次执行完成！"
