require 'yaml'
require 'dock-ops-core'

class BadArgsError < StandardError; end
class NoModeError < StandardError; end
class RunFailedError < StandardError; end

class DockOps < DockOpsCore
  def initialize
    super
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

  def ls(args=nil)
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
      "In #{get_mode.upcase} mode, Docker Compose commands should use:"
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

end
