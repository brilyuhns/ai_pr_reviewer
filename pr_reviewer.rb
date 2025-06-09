#!/usr/bin/env ruby

require 'octokit'
require 'dotenv'
require 'json'
require 'httparty'

# Load environment variables
Dotenv.load('.env')

class PRReviewer
  def initialize
    # @github_client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    # @repository = ENV['GITHUB_REPOSITORY']
    @github_client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    @repository = ENV['GITHUB_REPOSITORY']
  end

  def review_pr(pr_number)
    begin
      # Fetch PR details
      pr = @github_client.pull_request(@repository, pr_number)
      puts "Reviewing PR ##{pr_number}: #{pr.title}"

      # Get PR diff
      diff = @github_client.pull_request(@repository, pr_number, accept: 'application/vnd.github.v3.diff')
      
      # Generate summary
      summary = generate_summary(pr, diff)
      puts summary
      
      # Get review from Perplexity
      review = get_perplexity_review(pr, diff)
      
      # Post comments
      # post_review_comments(pr_number, summary, review)
      
      puts "Review completed successfully!"
    rescue Octokit::Error => e
      puts "GitHub API Error: #{e.message}"
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end

  private

  def generate_summary(pr, diff)
    # TODO: Implement summary generation
    "## PR Summary\n\n" \
    "**Title:** #{pr.title}\n" \
    "**Author:** #{pr.user.login}\n" \
    "**Changed Files:** #{pr.changed_files}\n" \
    "**Additions:** #{pr.additions}\n" \
    "**Deletions:** #{pr.deletions}\n"
  end

  def system_prompt
    <<~PROMPT
      You are an experienced code reviewer. Provide concise, constructive, actionable feedback.
      I REQUIRE EXTREME BREVITY - use minimal words and only include actionable feedback.
      As a code reviewer, focus on actionable feedback around the following areas:
        1. Code quality and best practices: SKIP SECTION IF THE PR DOES NOT IMPACT CODE QUALITY AND BEST PRACTICES OR CREATE NEW CODE QUALITY AND BEST PRACTICES
        2. Potential bugs or issues: SKIP SECTION IF THE PR DOES NOT IMPACT POTENTIAL BUGS OR ISSUES OR CREATE NEW POTENTIAL BUGS OR ISSUES
        3. Security concerns: SKIP SECTION IF THE PR DOES NOT IMPACT SECURITY OR CREATE NEW SECURITY CONCERNS
        4. Performance implications: SKIP SECTION IF THE PR DOES NOT IMPACT PERFORMANCE OR CREATE NEW PERFORMANCE IMPLICATIONS
        5. Suggestions for improvement: SKIP SECTION IF THE PR DOES NOT IMPACT SUGGESTIONS FOR IMPROVEMENT OR CREATE NEW SUGGESTIONS FOR IMPROVEMENT
      ONLY PROVIDE ACTIONABLE FEEDBACK. Do not provide feedback that is not actionable. If for any of the areas the feedback is not actionable, skip the area.
      CRITICAL INSTRUCTIONS:
      - Please format your response as a JSON object with the following structure. Ensure the feedback is in markdown format: 
        {
          "summary": "overall review summary",
          "inlineComments": [
            { "path": "file_path", "line": line_number, "body": "comment text" }
          ],
          "generalFeedback": "general feedback text",
          "performanceFeedback": "performance feedback text",
          "securityFeedback": "security feedback text",
          "testingRecommendation": "testing recommendation text"
        }
      - USE PR description as context if available
      - NEVER include a section if it has no critical, actionable feedback.
      - NEVER include phrases like "No X issues found" - simply omit that section.
      - Use bullet points for all feedback items.
      - Sort feedback by criticality (highest first).
      - ONLY flag issues that are definitively problems, not speculative concerns.
    PROMPT
  end

  def user_prompt(pr, diff)
  <<~PROMPT
    As a code reviewer, provide feedback for the following PR:
     Pull Request Details:
     Title: #{pr.title}
     Description: #{pr.body}
     
     Changes (diff):
     #{diff}
   PROMPT
  end

  def get_perplexity_review(pr, diff)
    begin
      api_key = ENV['PERPLEXITY_API_KEY']
      raise "Perplexity API key not found in environment variables" if api_key.nil?

      # Prepare the prompt for the review
      prompt = user_prompt(pr, diff)

      # Make request to Perplexity API
      response = HTTParty.post(
        'https://api.perplexity.ai/chat/completions',
        headers: {
          'Authorization' => "Bearer #{api_key}",
          'Content-Type' => 'application/json'
        },
        body: {
          model: 'sonar-pro',
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: prompt }
          ]
        }.to_json
      )

      if response.success?
        result = JSON.parse(response.body)
        review_text = result['choices'][0]['message']['content']
        p "## AI Review\n\n#{review_text}"
      else
        raise "Perplexity API Error: #{response.code} - #{response.body}"
      end
    rescue StandardError => e
      puts "Error generating review: #{e.message}"
      "## AI Review\n\nError generating review: #{e.message}"
    end
  end

  def post_review_comments(pr_number, summary, review)
    p comment = [summary, review].join("\n\n")
    @github_client.add_comment(@repository, pr_number, comment)
  end
end

# Run the script
if ARGV.length != 1
  puts "Usage: ruby #{$0} <pr_number>"
  exit 1
end

reviewer = PRReviewer.new
reviewer.review_pr(ARGV[0].to_i) 