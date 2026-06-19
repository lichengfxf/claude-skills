#!/usr/bin/env bash
set -euo pipefail

SOURCE="current-task/README.md"
ARCHIVE_DIR="current-task/archive"
LOG_FILE="${ARCHIVE_DIR}/archive.log"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

find_task_root() {
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/$SOURCE" ]]; then
            printf '%s\n' "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done

    return 1
}

extract_title() {
    awk '
        BEGIN { in_task = 0 }
        /^##[[:space:]]*任务[[:space:]]*$/ { in_task = 1; next }
        /^##[[:space:]]+/ && in_task { exit }
        in_task {
            line = $0
            gsub(/^[[:space:]>#*-]+/, "", line)
            gsub(/[[:space:]]+$/, "", line)
            if (line != "") {
                print line
                exit
            }
        }
    ' "$SOURCE"
}

fallback_title() {
    awk '
        /^#[[:space:]]+/ {
            line = $0
            sub(/^#[[:space:]]+/, "", line)
            if (line != "当前任务记录" && line != "") {
                print line
                exit
            }
        }
    ' "$SOURCE"
}

sanitize_title() {
    local title="$1"
    title="$(printf '%s' "$title" | tr '\n\r\t' '   ')"
    title="$(printf '%s' "$title" | sed -E 's/[\/:*?"<>|\\]+/-/g; s/[[:space:]]+/-/g; s/-+/-/g; s/^-//; s/-$//')"
    title="${title:0:80}"
    if [[ -z "$title" ]]; then
        title="current-task"
    fi
    printf '%s' "$title"
}

task_root="$(find_task_root)" || die "missing ${SOURCE} in current directory or its ancestors"
cd "$task_root"

[[ -f "$SOURCE" ]] || die "missing ${SOURCE}"
[[ -s "$SOURCE" ]] || die "${SOURCE} is empty"

mkdir -p "$ARCHIVE_DIR"

raw_title="${1:-}"
if [[ -z "$raw_title" ]]; then
    raw_title="$(extract_title || true)"
fi
if [[ -z "$raw_title" ]]; then
    raw_title="$(fallback_title || true)"
fi
if [[ -z "$raw_title" ]]; then
    raw_title="current-task"
fi

safe_title="$(sanitize_title "$raw_title")"
timestamp="$(date '+%Y%m%d-%H%M%S')"
archive_file="${ARCHIVE_DIR}/${timestamp}_${safe_title}.md"

if [[ -e "$archive_file" ]]; then
    suffix=1
    while [[ -e "${archive_file%.md}-${suffix}.md" ]]; do
        suffix=$((suffix + 1))
    done
    archive_file="${archive_file%.md}-${suffix}.md"
fi

cp "$SOURCE" "$archive_file"
: > "$SOURCE"

{
    printf '%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$archive_file" "$raw_title"
} >> "$LOG_FILE"

printf 'archived: %s\n' "$archive_file"
printf 'log: %s\n' "$LOG_FILE"
printf 'cleared: %s\n' "$SOURCE"
