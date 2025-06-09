require_relative 'lib/ai_pr_reviewer/version'

Gem::Specification.new do |spec|
  spec.name          = "ai_pr_reviewer"
  spec.version       = AiPrReviewer::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "AI-powered Pull Request reviewer using Perplexity API"
  spec.description   = "Automatically review Pull Requests using AI to provide actionable feedback, inline comments, and suggestions for improvement"
  spec.homepage      = "https://github.com/yourusername/ai_pr_reviewer"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*",
    "templates/**/*",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]
  
  spec.bindir        = "exe"
  spec.executables   = ["ai-pr-review"]
  spec.require_paths = ["lib"]

  spec.add_dependency "octokit", "~> 6.1"
  spec.add_dependency "dotenv", "~> 2.8"
  spec.add_dependency "json", "~> 2.6"
  spec.add_dependency "httparty", "~> 0.21"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end 