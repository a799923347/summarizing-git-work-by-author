---
name: summarizing-git-work-by-author
description: 用于按作者汇总单个仓库或本地多个仓库目录下的 git 提交记录，尤其适用于结果依赖于分支范围、作者别名，或需要将提交详情整理成可用于汇报的总结的场景
---

# Summarizing Git Work By Author

## Overview

Use this skill to turn raw git history into a reliable author-based summary.

Default workflow:
- Confirm the scope: one repo or a directory containing many repos
- Confirm the branch scope: current branch or all local branches
- Confirm the time window and author match rule
- Run the bundled script for structured output
- If the author match is empty, list recent authors first and adjust the pattern
- Start from details, then derive a concise thematic summary for the user

## When To Use

Use this skill when the user asks for:
- Recent work by a specific author
- A summary across multiple local repositories
- A branch-aware review of local work
- A report, weekly summary, or topic-based digest from commit history

Do not use this skill when:
- The user only wants the status of the current working tree
- The request is about code review rather than commit history

## Core Rules

- The parent directory itself may not be a git repo. Check child repos before concluding there is no history.
- Author matching is often imperfect. If no commits match, run author discovery and check both name and email.
- State the counting rule explicitly:
  - Current branch mode avoids cross-branch duplication.
  - Local-branches mode can show the same commit in multiple branches.
- In local-branches mode, distinguish:
  - Per-branch visible commit counts
  - Repo-level unique commit counts across local branches
- Exclude merge commits by default unless the user asks for integration history.

## Script

Run the bundled script. In the examples below, `${SKILL_DIR}` refers to the directory containing this `SKILL.md` file — substitute it with the actual install path of this skill on your machine.

```bash
bash ${SKILL_DIR}/scripts/summarize_git_work.sh --help
```

Typical commands:

```bash
# Discover the exact author identity used in recent commits
bash ${SKILL_DIR}/scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '1 week ago' \
  --list-authors

# Current-branch summary (auto-detects author from git config)
bash ${SKILL_DIR}/scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '7 days ago'

# Human-readable report format (default max 10 commits per repo)
bash ${SKILL_DIR}/scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '1 week ago' \
  --format report

# Per-branch details with commit limit
bash ${SKILL_DIR}/scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '3 weeks ago' \
  --author-pattern 'your-name|your.email@example.com' \
  --mode local-branches \
  --format details \
  --max-commits 20
```

## Output Interpretation

**Structured formats (summary/details):**
- `REPO|...` starts a repository block.
- In `current` mode:
  - `SUMMARY|repo|count|latest_date|latest_hash|latest_subject`
  - `DETAIL|date|hash|subject`
- In `local-branches` mode:
  - `BRANCH|branch|count|latest_date|latest_hash|latest_subject`
  - `TOTAL_UNIQUE|n` is the repo-level de-duplicated count across local branches.

**Report format:**
Human-readable output with repository names, commit counts, and individual commit messages.
- Shows per-repo and per-branch statistics
- Lists recent commits (default 10, configurable via `--max-commits`)
- Displays grand total at the end

## Response Pattern

After collecting the raw output:
- First answer the factual question with the exact scope used.
- Then summarize by theme:
  - platform work
  - infrastructure or middleware
  - business features
  - docs or configuration
- Call out uncertainty when duplication is possible across branches.
- If the user wants a report, rewrite the summary into project-based, topic-based, or weekly language.

## Common Mistakes

- Using the parent directory as if it were a git repo.
- Matching only author name and missing commits recorded under email.
- Claiming "no changes" without checking local branches.
- Summing local-branch counts as if they were unique commits.
