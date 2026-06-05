#!/bin/bash
# test_classify.sh - 测试邮件分类服务

echo -n "请输入邮件内容（可包含空格）: "
read -r content

# 如果输入为空，使用默认示例
if [ -z "$content" ]; then
    content="紧急会议通知 明天上午10点"
    echo "使用默认内容: $content"
fi

curl -X POST http://localhost:9800/classify \
  -H "Content-Type: application/json" \
  -d '{"instances":[{"token":["'"$content"'"]}]}'