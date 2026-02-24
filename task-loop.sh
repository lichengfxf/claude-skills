#!/bin/bash

# task-loop.sh - 自动化开发循环脚本
# 功能：循环调用 task-loop-one 技能，直到所有任务完成
# 参考：/home/code/work/github/bjarne/AutoCode/bjarne

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 重试设置
MAX_RETRIES=3
RETRY_DELAY=5

# 文件路径
TASKS_MD="TASKS.md"

echo -e "${BLUE}=== task-loop 自动化开发循环 ===${NC}"
echo "工作目录: $(pwd)"
echo ""

# 检查 TASKS_MD 是否存在
if [ ! -f "$TASKS_MD" ]; then
    echo -e "${RED}错误: 当前目录未找到 TASKS.md 文件${NC}"
    exit 1
fi

#==============================================================================
# 处理 JSON 流输出
#==============================================================================
process_json_stream() {
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            if command -v jq >/dev/null 2>&1; then
                # 提取 message.content 数组中的文本内容
                echo "$line" | jq -r '
                    if .message and .message.content then
                        .message.content[] |
                            if .type == "text" then
                                .text
                            elif .type == "tool_use" then
                                if .name == "Bash" then
                                    "\n>>> [Bash] \(.input.command // "")"
                                elif .name == "Read" then
                                    "\n>>> [Read] \(.input.file_path // "")"
                                elif .name == "Write" or .name == "Edit" then
                                    "\n>>> [\(.name)] \(.input.file_path // "")"
                                else
                                    "\n>>> [\(.name)]"
                                end
                            elif .type == "tool_result" then
                                if .content and (.content | type) == "string" then
                                    .content
                                elif .content and (.content | type) == "object" and .content.text then
                                    .content.text
                                else
                                    empty
                                end
                            else
                                empty
                            end
                    else
                        empty
                    end
                ' 2>/dev/null
            else
                # 没有 jq 时，直接输出原始行
                echo "$line"
            fi
        fi
    done
}

#==============================================================================
# 运行 claude（带重试机制）
# 用法：run_claude "prompt"
#==============================================================================
run_claude() {
    local prompt="$1"
    local attempt=1
    local exit_code=0

    local prompt_size=${#prompt}

    echo -e "${CYAN}  调用 Claude (提示词: $prompt_size 字节)${NC}"

    while [[ $attempt -le $MAX_RETRIES ]]; do
        # 运行 claude 命令，通过 process_json_stream 处理输出
        claude --verbose -p --output-format stream-json --dangerously-skip-permissions "$prompt" 2>&1 | process_json_stream
        exit_code=${PIPESTATUS[0]}

        # 检查是否成功
        if [[ $exit_code -eq 0 ]]; then
            return 0
        fi

        # 失败处理
        echo -e "${YELLOW}  Claude 失败 (第 $attempt/$MAX_RETRIES 次尝试, 退出码: $exit_code)${NC}"

        if [[ $attempt -lt $MAX_RETRIES ]]; then
            echo -e "${YELLOW}  ${RETRY_DELAY}s 后重试...${NC}"
            sleep $RETRY_DELAY
        fi

        ((attempt++))
    done

    echo -e "${RED}  已达最大重试次数 ($MAX_RETRIES 次)${NC}"
    return 1
}

#==============================================================================
# 检查是否所有任务都已完成
#==============================================================================
all_tasks_approved() {
    # 检查是否还有非 [APPROVED] 状态的任务
    local pending_count
    pending_count=$(grep -cE "^- \[(TODO|WIP|DONE|REVIEW|REJECTED|FIXING|FIXED)\]" "$TASKS_MD" 2>/dev/null) || true

    if [ -z "$pending_count" ]; then
        pending_count=0
    fi

    if [ "$pending_count" -eq 0 ]; then
        return 0  # 所有任务都已完成
    else
        return 1  # 还有待处理任务
    fi
}

#==============================================================================
# 统计任务状态
#==============================================================================
count_tasks() {
    local total
    local approved
    local pending

    total=$(grep -c "^- \[" "$TASKS_MD" 2>/dev/null) || true
    approved=$(grep -c "^- \[APPROVED\]" "$TASKS_MD" 2>/dev/null) || true
    pending=$(grep -cE "^- \[(TODO|WIP|DONE|REVIEW|REJECTED|FIXING|FIXED)\]" "$TASKS_MD" 2>/dev/null) || true

    [ -z "$total" ] && total=0
    [ -z "$approved" ] && approved=0
    [ -z "$pending" ] && pending=0

    echo "总计: $total | 已完成: $approved | 待处理: $pending"
}

#==============================================================================
# 主循环
#==============================================================================
echo "=== task-loop 启动 ==="
echo "任务状态: $(count_tasks)"
echo ""

iteration=0
while true; do
    iteration=$((iteration + 1))

    echo "=== 迭代 #$iteration ==="

    # 检查是否所有任务都已完成
    if all_tasks_approved; then
        echo "🎉 所有任务已完成！"

        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}🎉 恭喜！所有任务已完成！${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        break
    fi

    # 显示当前任务状态
    task_status=$(count_tasks)
    echo "当前状态: $task_status"

    echo ""
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${BLUE}🔄 执行第 $iteration 次循环${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "任务状态: ${YELLOW}$task_status${NC}"
    echo ""

    # 构建提示词：使用 task-loop-one 技能
    prompt="使用 task-loop-one 技能完成一次开发循环。"

    # 调用 run_claude
    if run_claude "$prompt"; then
        echo "✅ 迭代 #$iteration 完成"
    else
        echo "❌ 迭代 #$iteration 执行失败"
        echo -e "${RED}执行失败${NC}"
        exit 1
    fi

    # 短暂暂停，避免快速连续调用
    echo ""
    echo "⏳ 等待 2 秒后继续..."
    sleep 2
    echo ""
done

echo "=== task-loop 正常退出 ==="
