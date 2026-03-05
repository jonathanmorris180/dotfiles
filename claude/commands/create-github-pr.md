---
allowed-tools: Bash(gh pr:*)
description: Automatically create a pull request based on the current branch and commits.
---

# Create GitHub PR

Automatically create a pull request based on the current branch and commits.

## Purpose

This command streamlines the process of creating GitHub pull requests by analyzing your current branch, staged/unstaged changes, and commit history to generate an appropriate PR title and description.

## Instructions

1. Analyze the current git branch and ensure it's not the main branch
2. Check for uncommitted changes and prompt user to commit if necessary
3. Push the current branch to origin if not already pushed
4. Generate a meaningful PR title based on commit messages and changes
5. Create a comprehensive PR description including summary and test plan
6. Use `gh pr create` to create the pull request
7. Return the PR URL to the user

## Parameters

- `--draft`: Create the PR as a draft (optional)
- `--base <branch>`: Specify the base branch (defaults to main/master)
- `--title <title>`: Override the auto-generated title
- `--body <body>`: Override the auto-generated description

## Examples

### Example 1: Basic Usage
When the user says "/create-github-pr" you should:
1. Check current branch status
2. Ensure all changes are committed
3. Push branch if needed
4. Generate title and description from commits
5. Create the PR and return the URL

### Example 2: Draft PR
When the user says "/create-github-pr --draft" you should create a draft PR that can be marked ready for review later.

## Notes

- Requires `gh` CLI to be installed and authenticated
- Will fail if not on a feature branch (protects against PRs from main)
- Auto-generates meaningful titles and descriptions based on commit history
- Includes standard test plan template in PR description
- Respects branch protection rules and repository settings