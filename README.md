# AI PR Reviewer

An AI-powered Pull Request reviewer that uses the Perplexity API to provide actionable feedback on your pull requests.

## Features

- Automatically reviews pull requests using AI
- Provides actionable feedback on code quality, bugs, security, and performance
- Adds inline comments for specific code feedback
- Integrates with GitHub Actions for automated reviews
- Supports both manual and automated workflows

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ai_pr_reviewer'
```

And then execute:
```bash
$ bundle install
```

Or install it globally:
```bash
$ gem install ai_pr_reviewer
```

## Configuration

1. For local usage, create a `.env` file in your project root with the following variables:
```
GITHUB_TOKEN=your_github_token_here
GITHUB_REPOSITORY=owner/repo_name
PERPLEXITY_API_KEY=your_perplexity_api_key_here
```

2. For GitHub Actions, add these secrets to your repository:
- `GITHUB_TOKEN` (automatically provided by GitHub Actions)
- `PERPLEXITY_API_KEY` (add this in your repository secrets)
- Run `ai_pr_review install` to automatically install a GitHub Actions workflow file in your repository's `.github/workflows` directory.


## Usage

### Command Line

Review a specific PR:
```bash
$ ai-pr-review PR_NUMBER
```

### GitHub Actions

The installed workflow will automatically review pull requests when:
- A new PR is opened
- An existing PR is updated
- A PR is reopened

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/brilyuhns/ai_pr_reviewer.

## License

The gem is available as open source under the terms of the MIT License. 