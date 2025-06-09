#!/usr/bin/env ruby

require 'octokit'
require 'dotenv'
require 'json'
require 'httparty'

# Load environment variables
Dotenv.load('.env')

class PRReviewer
  def initialize
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
      post_review_comments(pr_number, summary, review)
      
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
          "inline_comments": [
            { "path": "file_path", "line": line_number, "body": "comment text" }
          ],
          "general_feedback": "general feedback text",
          "performance_feedback": "performance feedback text",
          "security_feedback": "security feedback text",
          "testing_recommendation": "testing recommendation text"
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
        # p "## AI Review\n\n#{review_text}"
      else
        raise "Perplexity API Error: #{response.code} - #{response.body}"
      end
    rescue StandardError => e
      puts "Error generating review: #{e.message}"
      "## AI Review\n\nError generating review: #{e.message}"
    end
  end


  ### sample review
#   {
# "summary": "Basic model structure is in place, but needs enhancements for a complete appointment system.",
# "inline_comments": [
# { "path": "app/models/appointment.rb", "line": 2, "body": "Consider adding validations for appointment_time to ensure it's not in the past and falls within valid business hours." },
# { "path": "app/models/appointment.rb", "line": 3, "body": "Add status tracking (pending, confirmed, canceled) and duration attributes for a more complete appointment model." },
# { "path": "db/migrate/20250609115307_create_appointments.rb", "line": 5, "body": "Consider adding additional fields like duration, status, and contact information for the appointment maker." }
# ],
# "general_feedback": "- Consider implementing a two-sided appointment relationship (user making vs. user receiving the appointment)\n- Add an index on appointment_time to optimize queries for date ranges\n- Consider using a BookingType or category to classify different appointment types",
# "testing_recommendation": "- Add validation tests to ensure appointment times are valid\n- Test appointment creation and cancellation flow",
# "performance_feedback": "- Consider using a background job for appointment confirmation emails\n- Optimize queries for appointment search by time range",
# "security_feedback": "- Add authentication to the appointment creation and cancellation endpoints\n- Consider using a secure token for appointment confirmation"
# }

  def post_review_comments(pr_number, summary, review)
    begin
      # Parse the review JSON
      review_data = JSON.parse(review)
      
      # Create the main review body with general feedback
      main_comment = []
      main_comment << "# AI Review Summary\n\n#{review_data['summary']}" if review_data['summary']
      main_comment << "\n\n## General Feedback\n#{review_data['general_feedback']}" if review_data['general_feedback']
      main_comment << "\n\n## Performance Feedback\n#{review_data['performance_feedback']}" if review_data['performance_feedback']
      main_comment << "\n\n## Security Feedback\n#{review_data['security_feedback']}" if review_data['security_feedback']
      main_comment << "\n\n## Testing Recommendations\n#{review_data['testing_recommendation']}" if review_data['testing_recommendation']
      
      # Get the PR's latest commit SHA
      pr_commits = @github_client.pull_request_commits(@repository, pr_number)
      latest_commit_sha = pr_commits.last.sha
      
      # Prepare review parameters
      review_params = {
        commit_id: latest_commit_sha,
        body: main_comment.join,
        event: 'COMMENT'
      }
      
      # Add inline comments if they exist
      if review_data['inline_comments']&.any?
        review_params[:comments] = review_data['inline_comments'].map do |comment|
          {
            path: comment['path'],
            position: comment['line'],
            body: comment['body']
          }
        end
      end
      
      # Create a single review with both body and inline comments
      @github_client.create_pull_request_review(
        @repository,
        pr_number,
        review_params
      )
      
      puts "Successfully posted review!"
    rescue JSON::ParserError => e
      puts "Error parsing review JSON: #{e.message}"
      # Fallback to posting the raw review if JSON parsing fails
      @github_client.add_comment(@repository, pr_number, [summary, review].join("\n\n"))
    rescue Octokit::Error => e
      puts "GitHub API Error: #{e.message}"
    rescue StandardError => e
      puts "Error posting review: #{e.message}"
    end
  end
end

# Run the script
if ARGV.length != 1
  puts "Usage: ruby #{$0} <pr_number>"
  exit 1
end

reviewer = PRReviewer.new
reviewer.review_pr(ARGV[0].to_i) 