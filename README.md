# 按作者总结 Git 工作

一个用于跨多个仓库按作者总结 Git 提交的 Claude Code 技能。

## 功能特性

- 跨多个本地仓库总结提交
- 支持当前分支或所有本地分支
- 多种输出格式：摘要、详细信息和人类可读报告
- 从 git 配置自动检测作者
- 可配置的提交数量限制
- 作者发现模式

## 安装

### 选项 1：安装到 Claude Code 技能目录

```bash
# 克隆此仓库
git clone https://github.com/your-username/summarizing-git-work-by-author.git

# 复制到 Claude Code 技能目录
cp -r summarizing-git-work-by-author ~/.claude/skills/
```

### 选项 2：创建符号链接（用于开发）

```bash
ln -s /path/to/summarizing-git-work-by-author ~/.claude/skills/summarizing-git-work-by-author
```

## 使用方法

安装后，在 Claude Code 中使用该技能：

```
/summarizing-git-work-by-author
```

Claude 将引导你选择：
- 仓库范围
- 时间范围
- 分支范围
- 要总结的作者

## 直接使用脚本

你也可以直接使用附带的脚本：

```bash
# 显示帮助
bash scripts/summarize_git_work.sh --help

# 列出时间窗口内的作者
bash scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '1 week ago' \
  --list-authors

# 生成人类可读报告
bash scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '1 week ago' \
  --format report

# 带提交限制的详细输出
bash scripts/summarize_git_work.sh \
  --root /path/to/repos \
  --since '3 weeks ago' \
  --author-pattern 'your-name|your.email@example.com' \
  --mode local-branches \
  --format details \
  --max-commits 20
```

## 系统要求

- Bash shell
- Git
- Claude Code（用于技能集成）

## 许可证

MIT

## 贡献

欢迎贡献！请随时提交 Pull Request。
