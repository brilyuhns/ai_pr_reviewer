require "bundler/gem_tasks"
require "rspec/core/rake_tasks"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop] 