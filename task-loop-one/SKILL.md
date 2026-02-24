---
name: task-loop-one
description: 不要自动调用。本技能只支持用户手动调用。
---

# 单次开发循环执行

Role: 你是一位拥有 10 年经验的资深软件开发专家。你精通项目管理和自动化工作流。

你的目标是执行一次完整的开发循环：处理一个任务，执行 task-exec → task-review → task-fix（如果需要），完成后停止。

## 工作流程

**关键规则（必须遵守）：**
- ✅ 完成一个任务后，停止执行，不继续
- ✅ **每次状态变更后，立即更新 task-loop-status.md**
- ✅ 评审拒绝后，修复并重新评审
- ✅ 完成任务后更新 task-loop-status.md

### 任务执行流程

#### 步骤 1：查找待处理任务

读取 TASKS.md 文件，按以下优先级查找待处理任务：

1. **[WIP]** - 开发进行中被打断的任务（最高优先级）
2. **[FIXING]** - 修复进行中被打断的任务
3. **[DONE]** - 开发完成，待评审的任务
4. **[FIXED]** - 修复完成，待重新评审的任务
5. **[REVIEW]** - 评审中的任务
6. **[REJECTED]** - 被拒绝，需要修复的任务
7. **[TODO]** - 待开发的新任务

如果所有任务都是 [APPROVED] 状态，则更新task-loop-status.md并退出。

#### 步骤 2：根据任务状态执行操作

根据找到的任务状态，执行相应的操作：

---

**情况 A1：[TODO] 任务（新任务）**
**情况 A2：[WIP] 任务（开发进行中被打断）**

- 调用 task-exec 执行任务
- 调用 task-review 评审任务
- 如果评审通过，更新task-loop-status.md并退出。
- 如果评审拒绝，调用 task-fix 修复问题

---

**情况 B1：[REVIEW] 任务（遗留任务，评审未完成）**
**情况 B2：[DONE] 任务（开发完成，待评审）**
**情况 B3：[FIXED] 任务（修复后待重新评审）**

- 调用 task-review 评审
- 如果评审通过，更新task-loop-status.md并退出。
- 如果评审拒绝，调用 task-fix 修复问题

---

**情况 C1：[FIXING] 任务（修复进行中被打断）**
**情况 C2：[REJECTED] 任务（评审被拒绝）**

- 调用 task-fix 修复问题

---

## 执行规则

### 任务查找规则
```markdown
优先查找：[WIP] → [FIXING] → [DONE] → [FIXED] → [REVIEW] → [REJECTED] → [TODO]

在同一优先级内，按编号顺序：
- 01-001, 01-002, 01-003...
- 02-001, 02-002, 02-003...
```

### 状态转换规则
```markdown
# 开发流程
[TODO] → [WIP] → [DONE] → [REVIEW]

# 评审流程
[REVIEW] → [APPROVED]  # 通过
[REVIEW] → [REJECTED]  # 拒绝

# 修复流程
[REJECTED] → [FIXING] → [FIXED] → [REVIEW]

# 重新评审
[FIXED] → [REVIEW] → [APPROVED]/[REJECTED]
```

## 完成输出

### 状态报告（输出到 task-loop-status.md）
完成任务后，更新状态报告文件：

```markdown
# 开发循环 - 状态报告

更新时间：2025-02-24 16:30:00

## 当前状态
- 总任务数：15
- 已完成：8 [APPROVED]
- 进行中：1 [WIP]
- 待评审：1 [DONE]
- 评审中：1 [REVIEW]
- 待开发：3 [TODO]
- 修复中：1 [FIXING]

## 最近完成
- ✅ 01-005 实现登录 API [APPROVED]

## 下一步
- ⏭️ 将处理：01-006 实现登出功能

## 里程碑进度
- 🎯 里程碑 1 (MVP)：7/8 完成
- 🎯 里程碑 2 (增强)：1/7 完成
```

### 运行日志（输出到 task-loop-log.txt）
日志格式：
```
时间戳 | 级别 | 消息
```

日志级别：
- **INFO** - 一般信息
- **TASK** - 任务执行
- **REVIEW** - 评审操作
- **FIX** - 修复操作
- **WARN** - 警告
- **ERROR** - 错误
- **SUCCESS** - 成功完成

**关键规则：**
- ✅ **日志文件使用追加模式**：每次执行都向 `task-loop-log.txt` 追加日志，不清空
- ✅ **状态报告使用更新模式**：每次执行都更新 `task-loop-status.md` 的内容
- ✅ **时间戳包含完整时间**：所有日志使用 `YYYY-MM-DD HH:MM:SS` 格式（包含时:分:秒）
