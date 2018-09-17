require 'yaml'
require 'term'

class BadArgsError < StandardError; end
class CmdExistsError < StandardError; end
class NoModeError < StandardError; end
class RunFailedError < StandardError; end

class DockOpsCore
  def initialize(config_version=1)
    @cnfg = Hash.new
    @config_dir = '.dock-ops'
    @config_version = config_version
    @term = Term.new
  end

  def main(argv)
    cmd, *opts = parse_args argv
    load_setup()
    return puts(with_completion opts) if cmd == :completion
    if cmd == :alias
      name, *args = opts
      return create_alias name, args
    end
    return with_working_dir(opts) if cmd == :working_dir
    if cmd == :native
      handler, command, *args = opts
      return delegate(handler, command, args)
    end

    if get_commands.include? cmd
      self.send cmd.to_sym, opts
    elsif get_alias(cmd)
      require 'csv'
      # preserve single-quoted shell arguments (double-quoted args are going to puke here)...
      args = CSV.parse_line get_alias(cmd), { col_sep: ' ', quote_char: "'" }
      return main args.unshift('-m', @mode.to_s)
    else
      bail "'#{cmd}' is not a choice: #{completion_commands.join ', '}"
    end
  rescue CmdExistsError => e
    bail e
  rescue BadArgsError => e
    STDERR.puts e.backtrace
    bail e
  rescue ArgumentError
    bail "bad inputs: '#{as_args argv}'; this might be because you're not in a Docker-equipped project?"
  rescue Interrupt # user hit Ctrl-c
    puts "\nQuitting..."
  rescue NoModeError
    bail "You somehow tried to work with a MODE which doesn't exist."
  rescue RunFailedError => e
    bail e
  rescue => e
    STDERR.puts e.backtrace
    bail e
  end

  private ### internal methods #############

  def as_args(arr) # convert array to space-delimited list (single-quoting elements as needed)
    return '' unless arr
    arr = [arr] unless arr.kind_of?(Array)
    with_quotes = -> arg { quote arg }
    arr.compact.map(&with_quotes).join(' ')
  end

  def bail(msg)
    abort "DOCK-OPS: #{msg}"
  end

  def bling(text)
    @term.color text, get_mode_color
  end

  def completion_commands
    commands = get_commands()
    commands.concat get_aliases.keys
  end

  def completion_containers
    `docker ps --format "{{.Names}}"`
  end

  def completion_images(with_tags=:false)
    format = with_tags == :true ? '{{.Repository}}:{{.Tag}}' : '{{.Repository}}'
    `docker images --format "#{format}"`
  end

  def completion_machines
    `docker-machine ls --format "{{.Name}}"`
  end

  def completion_services
    has_services = -> arg { get_services arg }
    yamls = find_yamls(get_mode).select(&has_services) # only include YAMLs with defined services
    candidates = []
    yamls.each do |yaml|
      candidates.concat get_services yaml
    end
    return candidates.uniq
  end

  def compose(yamls=nil)
    input = yamls ? yamls : get_setup()['compose_files']
    flag = -> filename { "-f #{filename}" }
    return "docker-compose #{input.map(&flag).join(' ')}"
  end

  def confirm_create_setup_store
    @term.show "\nNo '#{File.join Dir.home, @config_dir}' directory found; okay to create? (y/N)"
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

  def create_alias(name, args)
    if get_commands.include? name
      raise CmdExistsError, "'#{name}' is a built-in command and can't be used as an alias name."
    end
    @cnfg[@mode]['aliases'][name] = as_args args
    write_setup()
  end

  def default_setup
    base = {
      'version' => @config_version,
      'aliases' => {}
    }
    base['compose_files'] = case @mode
      when :development
        ['docker-compose.development.yaml']
      when :production
        ['docker-compose.yaml']
      else
        []
      end
    return base
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

  def find_yamls(mode=nil)
    show_all = '*.y{a,}ml'
    pattern = mode ? (@cnfg[mode] ? @cnfg[mode]['compose_files'] : show_all) : show_all
    Dir.glob(pattern).sort
  end

  def get_alias(name)
    get_aliases()[name]
  end

  def get_aliases
    get_setup()['aliases']
  end

  def get_commands
    return [
      'aliases',
      'attach',
      'build',
      'clean',
      'config',
      'down',
      'exec',
      'images',
      'logs',
      'ls',
      'ps',
      'push',
      'pull',
      'rls',
      'rmi',
      'run',
      'scp',
      'setup',
      'ssh',
      'stop',
      'tag',
      'up'
    ]
  end

  def get_mode
    @mode
  end

  def get_mode_color
    colors = {
      :development => :aqua,
      :production => :red,
      :other => :green
    }
    return colors[@mode] ? colors[@mode] : colors[:other]
  end

  def get_services(path) # return names of all services in docker-compose*.yaml files
    yaml = Psych.load_file path
    yaml['services'].keys
  rescue NoMethodError
    # probably not a docker-compose file!
  end

  def get_setup
    @cnfg.has_key?(@mode) ? @cnfg[@mode] : default_setup
  end

  def load_setup
    @cnfg[@mode] = default_setup # set default in case file IO fails
    setup_dir = File.join Dir.home, @config_dir
    project_setup_dir = File.join setup_dir, Dir.pwd
    yaml = IO.read File.join(project_setup_dir, "#{@mode}.yaml")
    @cnfg[@mode] = normalize Psych.load yaml
  rescue Errno::ENOENT
    # no existing setup file for this project/mode
  end

  def normalize(cnfg)
    if cnfg.kind_of?(Array) # version 0
      return default_setup.merge({ 'compose_files' => cnfg })
    end
    return case cnfg['version']
    when 1
      cnfg
    else
      bail "What, you're making up config file versions now?"
    end
  end

  def numbered(arr) # prepend numeric cardinal to each (string) element of ARR
    arr = [arr] unless arr.kind_of?(Array)
    with_color = lambda { |text, i| "#{bling(i + 1)}. #{text}" }
    arr.map.with_index(&with_color)
  end

  def parse_args(argv=[])
    raise BadArgsError unless argv.kind_of?(Array) and argv.length > 0
    args = []
    for_completion = false
    if argv[0] == 'complete' # request for shell completion options
      argv.shift
      for_completion = true
    end
    for_alias = nil
    for_native = nil
    working_dir = nil
    @mode = :development
    while argv.length > 0
      case argv[0]
      when '-a', '--alias'
        argv.shift
        for_alias = argv.shift
      when '-m'
        argv.shift
        @mode = argv.shift.to_sym
      when '-p', '--production'
        argv.shift
        @mode = :production
      when '-nc', '--compose'
        argv.shift
        for_native = :compose
      when '-nd', '--docker'
        argv.shift
        for_native = :docker
      when '-nm', '--machine'
        argv.shift
        for_native = :machine
      # when '-w', '--working-dir'
      #   argv.shift
      #   working_dir = argv.shift
      else # no more flags; everything else is CMD [ARGS...]
        args = argv.shift argv.length
      end
    end
    raise BadArgsError unless args
    args.unshift :native, for_native if for_native
    # argv.unshift working_dir if working_dir
    args.unshift :alias, for_alias if for_alias
    args.unshift :completion if for_completion
    return args
  end

  def quote(str) # single-quote strings which contain a space
    return str unless str.include?(' ')
    return "'#{str}'"
  end

  def setup_ui(yamls)
    show_ui yamls
    selected = to_array get_setup()['compose_files']
    do_save = :false
    loop do
      @term.content "% #{compose selected}"
      c = @term.readc
      c = c.to_i if /[1-9]/ =~ c
      case c
      when 1..9
        yaml = yamls[c - 1]
        selected.push(yaml) if yaml and !selected.include?(yaml)
      when "\177" # backspace
        selected.pop()
      when "\r" # enter
        do_save = :true
        break
      when 'c', 'C'
        do_save = :false
        break
      end
    end
    return do_save, selected
  end

  def show_ui(yamls)
    @term.show [
      'Available YAML files:',
      numbered(yamls),
      '',
      'Commands:',
      "- [#{bling 1}, #{bling 2}, ..., #{bling 'N'}] Add YAML file",
      "- [#{bling 'BACKSPACE'}] Remove YAML file",
      "- [#{bling 'C'}]ancel (exit without saving changes)",
      "- [#{bling 'ENTER'}] (exit and save changes)",
      '',
      "In #{get_mode.upcase} mode, Docker Compose commands should use:"
    ]
  end

  def sys(cmd, capture=:false) # exec shell command
    return system(cmd) unless capture == :true
    output = %x[#{cmd} 2>&1]
    return raise(RunFailedError, output) if $?.exitstatus > 0
    output.strip.lines.map { |line| line.strip }
  end

  def to_array(value)
    return [] unless value
    return value if value.kind_of?(Array)
    [value]
  end

  def update_setup(args)
    should_save, yamls = args
    if should_save == :false
      puts "\nNo changes saved."
      return
    end
    @cnfg[@mode]['compose_files'] = yamls
    write_setup()
  end

  def with_completion(argv=[])
    cmd = argv.shift
    return case cmd
    when 'build', 'exec', 'logs', 'run', 'up'
      completion_services.join(' ')
    when 'images'
      completion_images
    when 'push', 'rmi', 'tag'
      completion_images(:true)
    when 'attach', 'stop'
      completion_containers
    when 'scp', 'ssh', 'use'
      completion_machines
    else
      completion_commands.join(' ')
    end
  end

  def with_working_dir(args=[])
    path, cmd, *opts = args
    Dir.chdir(path) do
      self.send cmd.to_sym, opts
    end
  end

  def write_setup
    require 'fileutils'
    setup_dir = File.join Dir.home, @config_dir
    unless Dir.exist? setup_dir
      if confirm_create_setup_store() == :false
        puts "\nAborting setup (no changes saved)."
        return
      end
      FileUtils.mkpath setup_dir
    end
    project_setup_dir = File.join setup_dir, Dir.pwd
    FileUtils.mkpath project_setup_dir unless Dir.exist? project_setup_dir
    project_setup_file = File.join(project_setup_dir, "#{@mode}.yaml")
    IO.write project_setup_file, Psych.dump(get_setup)
    puts "\nSaved to file #{project_setup_file}"
  end

end
