require 'rake/clean'
require 'rake/testtask'

CLEAN.include('dock-ops*.gem')

task default: %w[build]

task :build do
  puts 'Building gem...'
  sh %{ gem build dock-ops.gemspec }
end

task :install => ['build'] do
  puts "\nInstalling (requires sudo access)..."
  sh %{ sudo gem install -f -l dock-ops }
end

task :test do
  puts 'Running tests...'
  Rake::TestTask.new do |t|
    t.libs = ["lib"]
    t.warning = true
    t.verbose = true
    t.test_files = FileList['test/*.rb']
    puts "\n"
  end
end

task :dist => ['test', 'build'] do
end

task :dev => ['dist', 'install', 'clean'] do
end
