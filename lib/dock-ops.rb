require 'term'
require 'yaml'
require 'fileutils'

class BadArgsError < StandardError; end
class BadModeError < StandardError; end
class RunFailedError < StandardError; end

class DockOps
  def initialize(argv)
    @term = Term.new
    cmd, *opts = parse_args argv
    load_config()
    return self.send(cmd.to_sym) unless opts.length > 0
    self.send cmd.to_sym, opts
  rescue BadModeError
    bail "You're trying to use a mode (development/production/etc.) that doesn't exist"
  rescue NoMethodError
    bail "'#{cmd}' is not a choice: build, clean, config, down, ls, ps, rls, run, scp, ssh, stop, up, unuse, use"
  rescue => e
    puts e
    puts e.backtrace
  end

  def as_args(arr) # convert array to space-delimited list (single-quoting elements as needed)
    arr = [arr] unless arr.kind_of? Array
    fn = -> arg { quote arg }
    arr.map(&fn).join(' ')
  end

  def bail(msg)
    abort "DOCK-TOOLS: #{msg}"
  end

  def build(service)
    sys "#{compose} build #{service}"
  end

  def clean
    containers = sys "docker ps -f status=exited -a -q", :true
    images = sys "docker images -f dangling=true -a -q", :true
    volumes = sys "docker volume ls -f dangling=true -q", :true
    # don't SYS() these because we don't care about "failure"...
    %x[docker rm #{as_args containers}] if containers and containers.length > 0
    %x[docker rmi -f #{as_args images}] if images and images.length > 0
    %x[docker volume rm #{as_args volumes}] if volumes and volumes.length > 0
  end

  def compose(yamls=nil)
    input = yamls ? yamls : get_config()
    flag = -> arg { "-f #{arg}" }
    return "docker-compose #{input.map(&flag).join(' ')}"
  end

  def config
    yamls = find_yamls
    @term.show 'Available YAML files:'
    @term.show numbered yamls
    @term.show ''
    @term.show 'Commands:'
    @term.show '- [1, 2, ..., N] Add YAML file'
    @term.show '- [BACKSPACE] Remove YAML file'
    @term.show '- [C]ancel (exit without saving changes)'
    @term.show '- [ENTER] or e[X]it (save changes)'
    @term.show ''
    @term.show "In #{@mode.upcase} mode, Docker Compose commands should use:"
    update_config config_ui yamls, get_config()
  end

  def config_ui(yamls, current)
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
    puts e
    puts e.backtrace
  end

  def confirm_create_config_store
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
    sys "docker ps -q -f name=#{name}", :true
  end

  def default_config
    return {
      :development => ['docker-compose.development.yaml', 'docker-compose.yaml'],
      :production => ['docker-compose.yaml']
    }
  end

  def down
    sys "#{compose} down --remove-orphans"
  end

  def find_yamls
    Dir.glob '*.y{a,}ml'
  end

  def get_config
    raise BadModeError unless @mode and @cnfg[@mode]
    @cnfg[@mode]
  end

  def load_config
    @cnfg = default_config()
    home = Dir.home
    pwd = Dir.pwd
    config_dir = File.join home, '.dock-ops'
    project_config_dir = File.join config_dir, pwd
    yaml = IO.read File.join(project_config_dir, "#{@mode}.yaml")
    @cnfg[@mode] = Psych.load yaml
  rescue => e
    puts e
    puts e.backtrace
  end

  def ls
    find_yamls.each do |file|
      puts file
      services(file).each do |filename|
        puts sprintf "  - %s", filename
      end
    end
  end

  def numbered(arr)
    arr = [arr] unless arr.kind_of? Array
    fn = lambda { |arg, i| "#{i + 1}. #{arg}" }
    arr.map.with_index(&fn)
  end

  def parse_args(argv)
    flags = ['-p', '-m', '--production']
    if flags.include?(argv[0])
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
    return argv
  end

  def ps
    sys "docker ps"
  end

  def quote(str) # single-quote strings which contain a space
    return str unless str.include?(' ')
    return "'#{str}'"
  end

  def rls
    sys "docker-machine ls"
  end

  def run(name, *args)
    sys "#{compose} run --rm #{service name} #{as_args args}"
  end

  def scp(args)
    sys "docker-machine scp #{as_args args}"
  end

  def service(name) # parse docker-compose*.yaml files for NAME service
    result, *rest = services('docker-compose.development.yaml').select do |candidate|
      /#{Regexp.escape(name)}/ =~ candidate
    end
    bail("more than one matching service for '#{name}'") if rest
    return result
  end

  def services(path) # return names of all services in docker-compose*.yaml files
    yaml = Psych.load_file path
    does_extend = :false
    yaml['services'].keys #.each_pair do |name, config|
      # config.each_pair do |k, v|
      #   if k == 'extends'
      #     does_extend = :true
      #     puts File.exist? File.absolute_path(prod)
      #     puts File.absolute_path(v['file']) == prod
      #   end
      # end
    # end
  end

  def stop(name=nil)
    sys "docker stop #{as_args container(name)}"
  end

  def ssh(args)
    sys "docker-machine ssh #{as_args args}"
  end

  def sys(cmd, capture=:false)
    return system(cmd) unless capture == :true
    output = %x[#{cmd} 2>&1]
    return raise(RunFailedError, output) if $?.exitstatus > 0
    output.strip.lines.map { |line| line.strip }
  end

  def unuse
    sys "eval $(docker-machine env -u)"
  end

  def up(args)
    sys "#{compose} up #{as_args args}"
  end

  def update_config(args)
    should_save, yamls = args
    if should_save == :false
      puts ''
      return
    end
    @cnfg[@mode] = yamls
    puts "\n#{@mode.upcase} mode will now use: #{compose yamls}"
    write_config()
  rescue => e
    puts e
    puts e.backtrace
  end

  def use(name)
    sys "eval $(docker-machine env #{name})"
  end

  def write_config
    home = Dir.home
    pwd = Dir.pwd
    config_dir = File.join home, '.dock-ops'
    project_config_dir = File.join config_dir, pwd
    unless Dir.exist? config_dir
      proceed = confirm_create_config_store()
      return if proceed == :false
      FileUtils.mkpath config_dir
    end
    FileUtils.mkpath project_config_dir unless Dir.exist? project_config_dir
    IO.write File.join(project_config_dir, "#{@mode}.yaml"), Psych.dump(get_config)
  rescue => e
    puts e
    puts e.backtrace
  end

end
