task default: %w[build]

task :build do
  puts 'Building gem...'
  sh %{ gem build dock-ops.gemspec }
end

task :test do
  puts 'Running tests...'
  ruby "test/dock-ops.rb"
  puts "\n"
end

task :dist => ['test', 'build'] do
end
