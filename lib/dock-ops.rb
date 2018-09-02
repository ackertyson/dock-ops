require 'term'
require 'yaml'
require 'fileutils'

class BadArgsError < StandardError; end
class NoModeError < StandardError; end
class RunFailedError < StandardError; end

class DockOps
  def initialize
    @term = Term.new
  end

  def as_args(arr) # convert array to space-delimited list (single-quoting elements as needed)
    arr = [arr] unless arr.kind_of? Array
    fn = -> arg { quote arg }
    arr.compact.map(&fn).join(' ')
  end

  def bail(msg)
    abort "DOCK-OPS: #{msg}"
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
    input = yamls ? yamls : get_setup()
    flag = -> arg { "-f #{arg}" }
    return "docker-compose #{input.map(&flag).join(' ')}"
  end

  def config
    sys "#{compose} config"
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
    sys "docker ps -q -f name=#{name}", :true
  end

  def default_setup
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

  def get_setup
    raise NoModeError unless @mode
    mode = @mode.to_sym
    @cnfg[mode] = [] unless @cnfg.has_key? mode
    @cnfg[mode]
  end

  def load_setup
    @cnfg = default_setup()
    home = Dir.home
    pwd = Dir.pwd
    setup_dir = File.join home, '.dock-ops'
    project_setup_dir = File.join setup_dir, pwd
    yaml = IO.read File.join(project_setup_dir, "#{@mode}.yaml")
    @cnfg[@mode.to_sym] = Psych.load yaml
  rescue Errno::ENOENT => e
    puts "No existing setup; using default (do 'dock setup' to define for this project)"
  rescue => e
    puts e
    puts e.backtrace
  end

  def logs(args)
    sys "#{compose} logs #{as_args args}"
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

  def scp(remote)
    sys "docker-machine scp #{as_args remote}"
  end

  def service(name) # parse docker-compose*.yaml files for NAME service
    candidates = []
    get_setup.each do |yaml|
      put yaml
      services(yaml).each do |item|
        candidates.push(item) unless candidates.include? item
      end
    end
    puts 'service', candidates
    match, *rest = candidates.select do |candidate|
      /#{Regexp.escape(name)}/ =~ candidate
    end
    bail("more than one matching service for '#{name}'") if rest
    return match
  end

  def services(path) # return names of all services in docker-compose*.yaml files
    yaml = Psych.load_file path
    # does_extend = :false
    # yaml['services'].each_pair do |name, config|
    #   config.each_pair do |k, v|
    #     if k == 'extends'
    #       does_extend = :true
    #       puts File.exist? File.absolute_path(v['file'])
    #     end
    #   end
    # end
    yaml['services'].keys
  end

  def setup
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
    update_setup setup_ui yamls, get_setup()
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
    puts e
    puts e.backtrace
  end

  def stop(name)
    raise BadArgsError unless name and name.length > 0
    sys "docker stop #{as_args container(as_args name)}"
  end

  def ssh(remote)
    sys "docker-machine ssh #{as_args remote}"
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

  def update_setup(args)
    should_save, yamls = args
    if should_save == :false
      puts "\nNo changes saved."
      return
    end
    @cnfg[@mode] = yamls
    puts "\n\n#{@mode.upcase} mode will now use: #{compose yamls}"
    write_setup()
  rescue => e
    puts e
    puts e.backtrace
  end

  def use(name)
    sys "eval $(docker-machine env #{name})"
  end

  def work(argv) # MAIN (entry point)
    cmd, *opts = parse_args argv
    load_setup()
    return self.send(cmd.to_sym) unless opts.length > 0
    self.send cmd.to_sym, opts
  rescue NoMethodError
    bail "'#{cmd}' is not a choice: build, clean, config, down, logs, ls, ps, rls, run, scp, setup, ssh, stop, up, unuse, use"
  rescue NoModeError
    bail "You somehow tried to work with a MODE which doesn't exist"
  rescue Interrupt # user hit Ctrl-c
    puts "\nQuitting..."
  rescue => e
    puts e
    puts e.backtrace
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
    puts "Saved to file #{project_setup_file}"
  rescue => e
    puts e
    puts e.backtrace
  end

end

dock = DockOps.new
dock.work(ARGV)
