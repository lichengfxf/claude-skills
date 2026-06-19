---
name: current-task-archive
description: |
  归档当前工作目录所属项目的 current-task/README.md 到 current-task/archive/。
  当用户要求归档、收尾、保存、结束当前任务记录，或把 current-task/README.md 归入 archive 时使用。
  这是全局技能，适用于任意包含 current-task/README.md 的项目；不要依赖特定工作区路径。
---

# 当前任务归档

把 `current-task/README.md` 归档到 `current-task/archive/`，并记录归档日志。

## 必须规则

- 这是全局技能，不能依赖任何特定项目目录。
- 以当前工作目录向上查找最近的 `current-task/README.md`，将其所在目录作为任务项目根目录。
- 对用户输出始终使用相对任务项目根目录的路径，不要输出项目绝对路径。
- 源文件固定为 `current-task/README.md`。
- 归档目录固定为 `current-task/archive/`。
- 归档文件名必须体现任务含义，不能只使用时间戳或 `README.md`。
- 每次归档都要追加日志到 `current-task/archive/archive.log`。
- 默认归档后清空 `current-task/README.md`，保留空文件用于下一次任务记录。

## 推荐流程

1. 如果当前回合还没有满足工作区启动阅读要求，先按工作区规则完成启动阅读。
2. 读取 `current-task/README.md`，确认它存在且不是空文件。
3. 使用技能目录中的脚本执行归档。不要假设当前项目中存在 `.codex/skills/...`：

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/current-task-archive/scripts/archive_current_task.sh"
```

4. 如果用户明确给了任务标题或归档名，把它作为脚本参数：

```bash
bash "${CODEX_HOME:-$HOME/.codex}/skills/current-task-archive/scripts/archive_current_task.sh" "轻型工作空间永中 Office 与 QAX 并存修复"
```

如果运行环境设置了不同的 Codex 技能目录，按实际技能安装路径解析 `scripts/archive_current_task.sh`；不要改为项目内相对 `.codex/skills/...` 或任何特定项目路径。

5. 归档后检查：
   - 新增的 `current-task/archive/*.md` 文件存在。
   - `current-task/archive/archive.log` 有对应记录。
   - `current-task/README.md` 已保留为空文件。

## 输出要求

最终回复用户时只说明归档文件相对路径、日志相对路径，以及 `current-task/README.md` 已清空并保留为空文件。
