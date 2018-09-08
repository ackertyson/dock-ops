require 'rake/clean'
require 'rake/testtask'

CLEAN.include('dock-ops*.gem')

task default: %w[install]

task :build do
  puts 'Building gem...'
  sh %{ gem build dock-ops.gemspec }
end

task :install => ['build'] do
  puts "\nInstalling (requires sudo access)..."
  sh %{ sudo gem install -f -l dock-ops }
end

task :completion do
  puts "\nCopying completion script..."
  sh %{ cp ./dock-ops-completion.bash ~/ }
  puts "  ***NOTE: you may need to add this line to your ~/.bash_profile (first character is 'dot'):"
  puts '    . ~/dock-ops-completion.bash'
  puts "  And then do 'source ~/.bash_profile' to reload that file in any open bash shells"
end

task :wrapper do
  puts "\nCopying wrapper script..."
  sh %{ cp ./dock-ops-wrapper.bash ~/ }
  puts "  ***NOTE: you may need to add this line to your ~/.bash_profile (first character is 'dot'):"
  puts '    . ~/dock-ops-wrapper.bash'
  puts "  And then do 'source ~/.bash_profile' to reload that file in any open bash shells"
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

task :dev => ['dist', 'install', 'completion', 'clean'] do
end

task :install_completion => ['install', 'completion'] do
end
