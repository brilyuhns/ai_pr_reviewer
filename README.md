# PR Reviewer

An automated PR review tool that generates summaries and provides intelligent reviews using GitHub API and Perplexity API.

## Features

- Fetches PR details and diffs from GitHub
- Generates PR summaries
- Gets intelligent reviews using Perplexity API
- Posts summaries and reviews as PR comments
- Runs as a GitHub Action

## Setup

1. Install dependencies:
```bash
bundle install
```

2. Configure environment variables:
- Copy `.env.template` to `.env`
- Add your GitHub token and Perplexity API key

## Usage

### As a GitHub Action

Add the workflow file to your repository at `.github/workflows/pr-reviewer.yml`. The action will run automatically on new PRs or when requested via comment.

### Local Usage

```bash
ruby pr_reviewer.rb <pr_number>
```

## Configuration

The tool can be configured using environment variables or a config file. See `.env.template` for available options. 