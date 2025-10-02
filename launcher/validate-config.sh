#!/bin/bash
# 配置验证脚本 - 检查是否使用了不安全的默认密码

# 颜色输出函数
red(){
    echo -e "\033[31m$1\033[0m"
}

yellow(){
    echo -e "\033[33m$1\033[0m"
}

green(){
    echo -e "\033[32m$1\033[0m"
}

# 检查 .env 文件是否存在
if [ ! -f "${APP_PATH}/.env" ]; then
    red "❌ 错误: .env 文件不存在!"
    yellow "请复制 .env.example 为 .env 并修改配置:"
    echo "   cp .env.example .env"
    exit 1
fi

# 不安全的默认密码列表
UNSAFE_PASSWORDS=(
    "got2changthispwd"
    "CHANGE_ME_NOW"
    "password"
    "123456"
    "admin"
    "root"
)

FOUND_ISSUES=false

# 检查是否使用了不安全的默认密码
for pwd in "${UNSAFE_PASSWORDS[@]}"; do
    if grep -q "$pwd" "${APP_PATH}/.env" 2>/dev/null; then
        if [ "$FOUND_ISSUES" = false ]; then
            red "=========================================="
            red "⚠️  安全警告: 检测到不安全的默认密码！"
            red "=========================================="
            FOUND_ISSUES=true
        fi
        yellow "发现不安全密码: '$pwd'"
    fi
done

# 检查密码强度（长度至少8位）
while IFS='=' read -r key value; do
    # 跳过注释和空行
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue

    # 检查包含 PASSWORD 的变量
    if [[ "$key" =~ PASSWORD ]]; then
        # 移除可能的引号
        value=$(echo "$value" | sed 's/["'\'']//g')

        # 检查密码长度
        if [ ${#value} -lt 8 ]; then
            if [ "$FOUND_ISSUES" = false ]; then
                red "=========================================="
                red "⚠️  安全警告: 检测到弱密码！"
                red "=========================================="
                FOUND_ISSUES=true
            fi
            yellow "密码过短 ($key): 长度 ${#value} 字符 (建议至少 12 字符)"
        fi
    fi
done < "${APP_PATH}/.env"

if [ "$FOUND_ISSUES" = true ]; then
    echo ""
    red "❌ 配置验证失败！"
    echo ""
    yellow "安全建议:"
    echo "  1. 使用至少 12 字符的强密码"
    echo "  2. 包含大小写字母、数字和特殊字符"
    echo "  3. 不要使用常见单词或默认密码"
    echo "  4. 每个服务使用不同的密码"
    echo ""
    yellow "修改 .env 文件后重新运行此脚本或 ./run.sh"
    echo ""
    exit 1
else
    green "✅ 配置验证通过！"
    exit 0
fi
