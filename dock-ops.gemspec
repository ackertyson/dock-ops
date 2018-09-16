spec = Gem::Specification.new do |spec|
  spec.name = 'dock-ops'
  spec.summary = 'Docker CLI helpers.'
  spec.description = %{Docker CLI helpers, including many common development and deployment commands.}
  spec.author = 'Tyson Acker'
  spec.email = 'tyson@devmode.com'
  spec.homepage = 'https://github.com/ackertyson/dock-ops'
  spec.files = ['lib/dock-ops-core.rb', 'lib/dock-ops.rb', 'lib/term.rb']
  spec.executables = ['dock']
  spec.version = '0.2.19'
  spec.license = 'MIT'
end
