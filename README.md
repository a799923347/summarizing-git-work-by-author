# Summarizing Git Work By Author

A Claude Code skill for summarizing Git commits by author across multiple repositories.

## Features

- Summarize commits across multiple local repositories
- Support for current branch or all local branches
- Multiple output formats: summary, details, and human-readable report
- Automatic author detection from git config
- Configurable commit limits
- Author discovery mode

## Installation

### Option 1: Install to Claude Code skills directory

```bash
# Clone this repository
git clone https://github.com/your-username/summarizing-git-work-by-author.git

# Copy to Claude Code skills directory
cp -r summarizing-git-work-by-author ~/.claude/skills/
```

### Option 2: Create a symlink (for development)

```bash
ln -s /path/to/summarizing-git-work-by-author ~/.claude/skills/summarizing-git-work-by-author
```

## Usage

Once installed, use the skill in Claude Code:

```
/summarizing-git-work-by-author
```

Claude will guide you through selecting:
- Repository scope
- Time range
- Branch scope
- Author to summarize

## Direct Script Usage

You can also use the bundled script directly:

```bash
# Show help
bash scripts/summarize_git_work.sh --help

# List authors in the time window
bash scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '1 week ago' \
  --list-authors

# Generate human-readable report
bash scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '1 week ago' \
  --format report

# Detailed output with commit limit
bash scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '3 weeks ago' \
  --author-pattern 'your-name|your.email@example.com' \
  --mode local-branches \
  --format details \
  --max-commits 20
```

## Requirements

- Bash shell
- Git
- Claude Code (for skill integration)

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
