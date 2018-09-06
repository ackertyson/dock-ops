require 'yaml'
require 'fileutils'
require 'term'

class BadArgsError < StandardError; end
class NoModeError < StandardError; end
class RunFailedError < StandardError; end

class DockOps
  def initialize
    @term = Term.new
  end

  def build(args)
    delegate :compose, 'build', args
  end

  def clean(args=nil)
    containers = sys "docker ps -f status=exited -a -q", :true
    images = sys "docker images -f dangling=true -a -q", :true
    volumes = sys "docker volume ls -f dangling=true -q", :true
    # don't DockOps.sys() these because we don't care about "failure"...
    if containers and containers.length > 0
      puts 'Containers...'
      system("docker rm #{as_args containers}")
    end
    if images and images.length > 0
      puts "\nImages..."
      system("docker rmi -f #{as_args images}")
    end
    if volumes and volumes.length > 0
      puts "\nVolumes..."
      system("docker volume rm #{as_args volumes}")
    end
  end

  def commands(args=nil)
    puts get_commands.join ' '
  end

  def config(args=[])
    delegate :compose, 'config', args
  end

  def down(args=[])
    args.unshift '--remove-orphans'
    delegate :compose, 'down', args
  end

  def images(args=[])
    delegate :docker, 'images', args
  end

  def logs(args)
    delegate :compose, 'logs', args
  end

  def ls
    find_yamls.each do |filename|
      servicenames = get_services filename
      if servicenames and servicenames.length > 0
        puts filename
        servicenames.each do |servicename|
          puts(sprintf "  - %s", servicename) if servicename
        end
      end
    end
  end

  def ps(args=[])
    delegate :docker, 'ps', args
  end

  def pull(args)
    delegate :docker, 'pull', args
  end

  def push(args)
    delegate :docker, 'push', args
  end

  def rls(args=[])
    delegate :machine, 'ls', args
  end

  def rmi(args)
    delegate :docker, 'rmi', args
  end

  def run(argv=[])
    name, *args = argv
    args.unshift '--rm', get_service(name)
    delegate :compose, 'run', args
  end

  def scp(args)
    delegate :machine, 'scp', args
  end

  def services(args=nil)
    has_services = -> arg { get_services arg }
    yamls = find_yamls.select(&has_services) # only include YAMLs with defined services
    candidates = []
    yamls.each do |yaml|
      candidates.concat get_services yaml
    end
    puts as_args candidates.uniq
  end

  def setup(args=nil)
    has_services = -> arg { get_services arg }
    with_color = lambda { |color, text| @term.color text, color }
    bling = with_color.curry.call get_mode_color
    yamls = find_yamls.select(&has_services) # only include YAMLs with defined services
    @term.show [
      'Available YAML files:',
      numbered(yamls, bling),
      '',
      'Commands:',
      "- [#{bling.call 1}, #{bling.call 2}, ..., #{bling.call 'N'}] Add YAML file",
      "- [#{bling.call 'BACKSPACE'}] Remove YAML file",
      "- [#{bling.call 'C'}]ancel (exit without saving changes)",
      "- [#{bling.call 'ENTER'}] or e[#{bling.call 'X'}]it (save changes)",
      '',
      "In #{@mode.upcase} mode, Docker Compose commands should use:"
    ]
    update_setup setup_ui yamls, get_setup()
  rescue => e
    STDERR.puts e
  end

  def ssh(args)
    delegate :machine, 'ssh', args
  end

  def stop(argv)
    name, *args = argv
    raise BadArgsError unless name and name.length > 0
    args.unshift container(name)
    delegate :docker, 'stop', args
  end

  def tag(args)
    delegate :docker, 'tag', args
  end

  def up(args=[])
    delegate :compose, 'up', args
  end

  def work(argv) # MAIN (entry point)
    cmd, *opts = parse_args argv
    load_setup()
    return with_working_dir(opts) if cmd == :working_dir
    if cmd == :native
      handler, command, *args = opts
      return delegate(handler, command, args)
    end
    self.send cmd.to_sym, opts
  rescue ArgumentError
    bail "bad inputs: '#{as_args argv}'; this might be because you're not in a Docker-equipped project?"
  rescue BadArgsError => e
    STDERR.puts e
    STDERR.puts e.backtrace
  rescue Interrupt # user hit Ctrl-c
    puts "\nQuitting..."
  rescue NoMethodError
    bail "'#{cmd}' is not a choice: #{get_commands.join ', '}"
  rescue NoModeError
    bail "You somehow tried to work with a MODE which doesn't exist."
  rescue RunFailedError => e
    STDERR.puts e
    bail 'Oops!'
  rescue => e
    STDERR.puts e
    STDERR.puts e.backtrace
  end

  private ### internal methods #############

  def as_args(arr) # convert array to space-delimited list (single-quoting elements as needed)
    arr = [arr] unless arr.kind_of? Array
    with_quotes = -> arg { quote arg }
    arr.compact.map(&with_quotes).join(' ')
  end

  def bail(msg)
    abort "DOCK-OPS: #{msg}"
  end

  def compose(yamls=nil)
    input = yamls ? yamls : get_setup()
    flag = -> arg { "-f #{arg}" }
    return "docker-compose #{input.map(&flag).join(' ')}".chomp
  end

  def confirm_create_setup_store
    @term.show 'No ~/.dock-ops directory found; okay to create? (y/N)'
    c = @term.readc
    case c
    when 'y'
      return :true
    else
      return :false
    end
  end

  def container(name) # find running container NAME
    raise BadArgsError unless name and name.length > 0
    sys "docker ps -q -f name=#{name}", :true
  end

  def default_setup
    return {
      :development => ['docker-compose.development.yaml'],
      :production => ['docker-compose.yaml']
    }
  end

  def delegate(target, cmd, args) # pass args through to Docker
    case target
    when :compose
      sys "#{compose} #{cmd} #{as_args args}"
    when :docker
      sys "docker #{cmd} #{as_args args}"
    when :machine
      sys "docker-machine #{cmd} #{as_args args}"
    else
      raise BadArgsError
    end
  end

  def find_yamls
    Dir.glob('*.y{a,}ml').sort
  end

  def get_mode_color
    colors = {
      :development => :aqua,
      :production => :red,
      :other => :green
    }
    return colors[@mode] ? colors[@mode] : colors[:other]
  end

  def get_service(name) # parse docker-compose*.yaml files for NAME service
    raise BadArgsError unless name and name.length > 0
    candidates = []
    get_setup.each do |yaml|
      get_services(yaml).each do |item|
        candidates.push(item) unless candidates.include? item
      end
    end
    match, *rest = candidates.select do |candidate|
      /^#{Regexp.escape(name)}$/ =~ candidate
    end
    return match
  end

  def get_services(path) # return names of all services in docker-compose*.yaml files
    yaml = Psych.load_file path
    yaml['services'].keys
  rescue NoMethodError
    return # probably not a docker-compose file!
  end

  def get_setup
    raise NoModeError unless @mode
    mode = @mode.to_sym
    @cnfg[mode] = [] unless @cnfg.has_key? mode
    @cnfg[mode]
  end

  def get_commands
    return ['build', 'clean', 'config', 'down', 'images', 'logs', 'ls', 'ps', 'push', 'pull', 'rls', 'rmi', 'run', 'scp', 'setup', 'ssh', 'stop', 'tag', 'up']
  end

  def load_setup
    @cnfg = default_setup()
    home = Dir.home
    pwd = Dir.pwd
    setup_dir = File.join home, '.dock-ops'
    project_setup_dir = File.join setup_dir, pwd
    yaml = IO.read File.join(project_setup_dir, "#{@mode}.yaml")
    @cnfg[@mode.to_sym] = Psych.load yaml
  rescue Errno::ENOENT
    # no existing setup file for this project/mode
  rescue => e
    STDERR.puts e
    STDERR.puts e.backtrace
  end

  def numbered(arr, highlight=nil) # prepend numeric cardinal to each (string) element of ARR
    arr = [arr] unless arr.kind_of? Array
    with_color = lambda { |arg, i| "#{highlight ? "#{highlight.call(i + 1)}" : i + 1}. #{arg}" }
    arr.map.with_index(&with_color)
  rescue => e
    STDERR.puts e
  end

  def parse_args(argv)
    flags = {
      :mode => ['-m', '-p', '--production'],
      :native => ['-nc', '--compose', '-nd', '--docker', '-nm', '--machine'],
      :working_dir => ['-w']
    }
    if flags[:mode].include?(argv[0])
      flag = argv.shift
      case flag
      when '-p', '--production'
        @mode = :production
      when '-m'
        @mode = argv.shift
      else
        @mode = :development
      end
    else
      @mode = :development
    end

    if flags[:native].include?(argv[0]) # flag for delegate handling
      flag = argv.shift
      case flag
      when '-nc', '--compose'
        argv.unshift :compose
      when '-nd', '--docker'
        argv.unshift :docker
      when '-nm', '--machine'
        argv.unshift :machine
      end
      argv.unshift :native
    end

    if flags[:working_dir].include?(argv[0]) # flag for working dir
      flag = argv.shift
      argv.unshift :working_dir
    end

    return argv
  end

  def quote(str) # single-quote strings which contain a space
    return str unless str.include?(' ')
    return "'#{str}'"
  end

  def setup_ui(yamls, current)
    do_save = :false
    loop do
      @term.content "% #{compose current}"
      c = @term.readc
      c = c.to_i if /[1-9]/ =~ c
      case c
      when 1..9
        yaml = yamls[c - 1]
        current.push(yaml) if yaml and !current.include?(yaml)
      when "\177" # backspace
        current.pop()
      when 'x', 'X', "\r" # enter
        do_save = :true
        break
      when 'c', 'C'
        do_save = :false
        break
      end
    end
    return do_save, current
  rescue => e
    STDERR.puts e
    STDERR.puts e.backtrace
  end

  def sys(cmd, capture=:false) # exec shell command
    return system(cmd) unless capture == :true
    output = %x[#{cmd} 2>&1]
    return raise(RunFailedError, output) if $?.exitstatus > 0
    output.strip.lines.map { |line| line.strip }
  end

  def update_setup(args)
    should_save, yamls = args
    if should_save == :false
      puts "\nNo changes saved."
      return
    end
    @cnfg[@mode] = yamls
    write_setup()
  rescue => e
    STDERR.puts e
    STDERR.puts e.backtrace
  end

  def with_working_dir(args)
    path, cmd, *opts = args
    Dir.chdir(path) do
      self.send cmd.to_sym, opts
    end
  end

  def write_setup
    home = Dir.home
    pwd = Dir.pwd
    setup_dir = File.join home, '.dock-ops'
    project_setup_dir = File.join setup_dir, pwd
    unless Dir.exist? setup_dir
      proceed = confirm_create_setup_store()
      return if proceed == :false
      FileUtils.mkpath setup_dir
    end
    FileUtils.mkpath project_setup_dir unless Dir.exist? project_setup_dir
    project_setup_file = File.join(project_setup_dir, "#{@mode}.yaml")
    IO.write project_setup_file, Psych.dump(get_setup)
    puts "\nSaved to file #{project_setup_file}"
  rescue => e
    STDERR.puts e
    STDERR.puts e.backtrace
  end

end
