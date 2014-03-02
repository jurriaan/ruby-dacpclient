require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop'
require 'yard'
require 'rubocop/rake_task'
YARD::Rake::YardocTask.new

# Rake::TestTask.new do |t|
#   t.libs << 'lib/docparser'
#   t.test_files = FileList['test/lib/**/*_test.rb']
#   t.verbose = true
# end

task test: :rubocop do
end

Rubocop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['**/*.rb', 'Rakefile', 'dacpclient.gemspec', 'bin/*']
  # don't abort rake on failure
  task.options = ['-c', '.rubocop.yml']
  task.fail_on_error = true
end

task default: :test
