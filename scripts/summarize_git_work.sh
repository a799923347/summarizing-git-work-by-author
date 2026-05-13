#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  summarize_git_work.sh --root DIR [options]

Options:
  --root DIR                 Directory containing one or more child git repositories.
  --since EXPR               Git time expression. Default: 3 weeks ago (supports "7 days ago", "1 month ago", etc.)
  --author-pattern REGEX     Pattern passed to git log --author. Auto-detects from git config if not specified.
  --mode MODE                current | local-branches. Default: current
  --format FORMAT            summary | details | report. Default: summary
  --max-commits N            Limit commits per repo in details/report mode. Default: unlimited (report: 10)
  --include-merges           Include merge commits. Default: false
  --list-authors             List unique authors in the time window and exit.
  --help                     Show this help text.

Notes:
  - The script scans child repositories at ROOT/*/.git.
  - In local-branches mode, the same commit may appear in multiple branches.
  - TOTAL_UNIQUE is de-duplicated across local branches within a repository.
  - report format provides a human-readable summary with headers and separators.
EOF
}

ROOT=""
SINCE="3 weeks ago"
AUTHOR_PATTERN=""
AUTHOR_GIT_PATTERN=""
MODE="current"
FORMAT="summary"
MAX_COMMITS=0
INCLUDE_MERGES=0
LIST_AUTHORS=0
AUTHORS_TMP=""
TOTAL_COMMITS=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --since)
      SINCE="${2:-}"
      shift 2
      ;;
    --author-pattern)
      AUTHOR_PATTERN="${2:-}"
      AUTHOR_GIT_PATTERN="${AUTHOR_PATTERN//|/\\|}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --format)
      FORMAT="${2:-}"
      shift 2
      ;;
    --max-commits)
      MAX_COMMITS="${2:-}"
      shift 2
      ;;
    --include-merges)
      INCLUDE_MERGES=1
      shift
      ;;
    --list-authors)
      LIST_AUTHORS=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$ROOT" ]; then
  echo "--root is required" >&2
  usage >&2
  exit 1
fi

if [ ! -d "$ROOT" ]; then
  echo "Root directory does not exist: $ROOT" >&2
  exit 1
fi

if [ "$MODE" != "current" ] && [ "$MODE" != "local-branches" ]; then
  echo "Invalid --mode: $MODE" >&2
  exit 1
fi

if [ "$FORMAT" != "summary" ] && [ "$FORMAT" != "details" ] && [ "$FORMAT" != "report" ]; then
  echo "Invalid --format: $FORMAT" >&2
  exit 1
fi

# Default author from git config if not specified
if [ -z "$AUTHOR_PATTERN" ] && [ "$LIST_AUTHORS" -eq 0 ]; then
  DEFAULT_AUTHOR="$(git config user.name 2>/dev/null || echo 'your-name')"
  AUTHOR_PATTERN="$DEFAULT_AUTHOR"
  AUTHOR_GIT_PATTERN="$DEFAULT_AUTHOR"
fi

# Default max commits for report format (empty or 0 means use default)
if [ "$FORMAT" = "report" ]; then
  case "$MAX_COMMITS" in
    ''|0) MAX_COMMITS=10 ;;
  esac
fi

GIT_LOG_COMMON=(--since="$SINCE" --date=short)
if [ -n "$AUTHOR_PATTERN" ]; then
  GIT_LOG_COMMON+=(--author="$AUTHOR_GIT_PATTERN")
fi
if [ "$INCLUDE_MERGES" -eq 0 ]; then
  GIT_LOG_COMMON+=(--no-merges)
fi

has_any_repo=0

print_list_authors() {
  local repo="$1"
  git -C "$repo" log --since="$SINCE" --format='%an|%ae' 2>/dev/null || true
}

if [ "$LIST_AUTHORS" -eq 1 ]; then
  AUTHORS_TMP="$(mktemp)"
  trap 'rm -f "$AUTHORS_TMP"' EXIT
fi

print_current_summary() {
  local repo="$1"
  local name="$2"
  local lines latest count display_lines

  lines=$(git -C "$repo" log "${GIT_LOG_COMMON[@]}" --pretty=format:'%ad|%h|%s' 2>/dev/null || true)
  [ -z "$lines" ] && return

  count=$(printf '%s\n' "$lines" | wc -l | tr -d ' ')
  latest=$(printf '%s\n' "$lines" | sed -n '1p')
  TOTAL_COMMITS=$((TOTAL_COMMITS + count))

  if [ "$FORMAT" = "report" ]; then
    printf '【%s】提交数: %s\n' "$name" "$count"
    display_lines="$lines"
    if [ "$MAX_COMMITS" -gt 0 ]; then
      display_lines=$(sed -n "1,${MAX_COMMITS}p" <<< "$lines")
    fi
    printf '%s\n' "$display_lines" | sed 's/^/    - /'
    echo ""
  else
    printf 'SUMMARY|%s|%s|%s\n' "$name" "$count" "$latest"
    if [ "$FORMAT" = "details" ]; then
      display_lines="$lines"
      if [ "$MAX_COMMITS" -gt 0 ]; then
        display_lines=$(sed -n "1,${MAX_COMMITS}p" <<< "$lines")
      fi
      printf '%s\n' "$display_lines" | sed 's/^/DETAIL|/'
    fi
  fi
}

print_local_branch_output() {
  local repo="$1"
  local name="$2"
  local found=0
  local ref lines count latest unique_total display_lines

  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    lines=$(git -C "$repo" log "$ref" "${GIT_LOG_COMMON[@]}" --pretty=format:'%ad|%h|%s' 2>/dev/null || true)
    [ -z "$lines" ] && continue

    if [ "$found" -eq 0 ]; then
      if [ "$FORMAT" = "report" ]; then
        printf '## 【%s】\n' "$name"
      else
        printf 'REPO|%s\n' "$name"
      fi
      found=1
    fi

    count=$(printf '%s\n' "$lines" | wc -l | tr -d ' ')
    latest=$(printf '%s\n' "$lines" | sed -n '1p')

    if [ "$FORMAT" = "report" ]; then
      printf '  [%s] %s commits (latest: %s)\n' "$ref" "$count" "$(printf '%s' "$latest" | cut -d'|' -f1,3 | tr '|' ' ')"
    else
      printf 'BRANCH|%s|%s|%s\n' "$ref" "$count" "$latest"
    fi

    if [ "$FORMAT" = "details" ] || [ "$FORMAT" = "report" ]; then
      display_lines="$lines"
      if [ "$MAX_COMMITS" -gt 0 ]; then
        display_lines=$(sed -n "1,${MAX_COMMITS}p" <<< "$lines")
      fi
      if [ "$FORMAT" = "report" ]; then
        printf '%s\n' "$display_lines" | sed 's/^/      - /'
      else
        printf '%s\n' "$display_lines" | sed 's/^/DETAIL|/'
        printf 'ENDBRANCH\n'
      fi
    fi
  done < <(git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)

  [ "$found" -eq 0 ] && return

  unique_total=$(
    git -C "$repo" log --branches "${GIT_LOG_COMMON[@]}" --format='%H' 2>/dev/null \
      | sort -u \
      | wc -l \
      | tr -d ' '
  )
  TOTAL_COMMITS=$((TOTAL_COMMITS + unique_total))

  if [ "$FORMAT" = "report" ]; then
    printf '  唯一提交总数: %s\n\n' "$unique_total"
  else
    printf 'TOTAL_UNIQUE|%s\n' "$unique_total"
    printf 'ENDREPO\n'
  fi
}

for gitdir in "$ROOT"/*/.git; do
  [ -d "$gitdir" ] || continue
  has_any_repo=1
  repo="${gitdir%/.git}"
  name="${repo##*/}"

  if ! git -C "$repo" rev-parse --verify HEAD >/dev/null 2>&1; then
    continue
  fi

  if [ "$LIST_AUTHORS" -eq 1 ]; then
    print_list_authors "$repo" >> "$AUTHORS_TMP"
    continue
  fi

  if [ "$MODE" = "current" ]; then
    print_current_summary "$repo" "$name"
  else
    print_local_branch_output "$repo" "$name"
  fi
done

if [ "$has_any_repo" -eq 0 ]; then
  echo "No child git repositories found under: $ROOT" >&2
  exit 1
fi

if [ "$LIST_AUTHORS" -eq 1 ]; then
  sort -u "$AUTHORS_TMP"
fi

# Print total for report format
if [ "$FORMAT" = "report" ] && [ "$LIST_AUTHORS" -eq 0 ]; then
  echo "========================================"
  echo "总计: $TOTAL_COMMITS 次提交"
fi
