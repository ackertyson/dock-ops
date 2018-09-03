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
  ruby "test/*.rb"
  puts "\n"
end

task :dist => ['test', 'build'] do
end

task :dev => ['dist', 'install'] do
end
