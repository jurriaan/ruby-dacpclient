require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rubocop'
require 'yard'

YARD::Rake::YardocTask.new

task test: :rubocop do
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['**/*.rb', 'Rakefile', 'dacpclient.gemspec', 'bin/*']
  task.options = ['-a']
  task.fail_on_error = true
end

task default: :test
