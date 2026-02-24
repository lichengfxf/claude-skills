#!/bin/bash

# task-loop.sh - 自动化开发循环脚本
# 功能：循环调用 task-loop-one 技能，直到所有任务完成

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 文件路径
TASKS_MD="TASKS.md"

echo -e "${BLUE}=== task-loop 自动化开发循环 ===${NC}"
echo "工作目录: $(pwd)"
echo ""

# 检查 TASKS.md 是否存在
if [ ! -f "$TASKS_MD" ]; then
    echo -e "${RED}错误: 当前目录未找到 TASKS.md 文件${NC}"
    exit 1
fi

# 检查是否所有任务都已完成
all_tasks_approved() {
    # 检查是否还有非 [APPROVED] 状态的任务
    local pending_count
    pending_count=$(grep -c "^\- \[\(TODO\|WIP\|DONE\|REVIEW\|REJECTED\|FIXING\|FIXED\)\] [0-9][0-9]-[0-9][0-9][0-9]" "$TASKS_MD" 2>/dev/null) || true

    if [ -z "$pending_count" ]; then
        pending_count=0
    fi

    if [ "$pending_count" -eq 0 ]; then
        return 0  # 所有任务都已完成
    else
        return 1  # 还有待处理任务
    fi
}

# 统计任务状态
count_tasks() {
    local total
    local approved
    local pending

    total=$(grep -c "^\- \[" "$TASKS_MD" 2>/dev/null) || true
    approved=$(grep -c "^\- \[APPROVED\]" "$TASKS_MD" 2>/dev/null) || true
    pending=$(grep -c "^\- \[\(TODO\|WIP\|DONE\|REVIEW\|REJECTED\|FIXING\|FIXED\)\]" "$TASKS_MD" 2>/dev/null) || true

    [ -z "$total" ] && total=0
    [ -z "$approved" ] && approved=0
    [ -z "$pending" ] && pending=0

    echo "总计: $total | 已完成: $approved | 待处理: $pending"
}

# 主循环
echo "=== task-loop 启动 ==="
echo "任务状态: $(count_tasks)"

iteration=0
while true; do
    iteration=$((iteration + 1))

    echo ""
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

    # 调用 task-loop-one 技能
    if claude skill task-loop-one; then
        echo "✅ task-loop-one 完成"
    else
        echo "❌ task-loop-one 执行失败"
        echo -e "${RED}task-loop-one 执行失败${NC}"
        exit 1
    fi

    # 短暂暂停，避免快速连续调用
    echo "⏳ 等待 2 秒后继续..."
    sleep 2
done

echo "=== task-loop 正常退出 ==="
