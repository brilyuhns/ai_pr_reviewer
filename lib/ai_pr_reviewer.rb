require "ai_pr_reviewer/version"
require "fileutils"

module AiPrReviewer
  class Error < StandardError; end
  
  class << self
    def install_github_actions
      source = File.join(File.dirname(__FILE__), '..', 'templates', 'github', 'workflows', 'ai_pr_review.yml')
      target_dir = File.join(Dir.pwd, '.github', 'workflows')
      target = File.join(target_dir, 'ai_pr_review.yml')
      
      FileUtils.mkdir_p(target_dir)
      if File.exist?(target)
        puts "GitHub Actions workflow already exists at #{target}"
      else
        FileUtils.cp(source, target)
        puts "Successfully installed GitHub Actions workflow at #{target}"
      end
    end
  end
end

# Hook into gem installation
if defined?(Gem::Installer) && defined?(Gem::Installer::post_install)
  Gem::Installer::post_install do |installer|
    if installer.spec.name == 'ai_pr_reviewer'
      AiPrReviewer.install_github_actions
    end
  end
end 