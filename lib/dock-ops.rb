require 'dock-ops-core'

class BadArgsError < StandardError; end
class NoModeError < StandardError; end
class RunFailedError < StandardError; end

class DockOps < DockOpsCore
  def initialize(config_version=1)
    super config_version
  end

  def aliases(args=nil)
    get_aliases().each_pair do |name, cmd|
      puts(sprintf "%s => %s", bling(name), cmd)
    end
  rescue => e
    puts e
  end

  def attach(args=[])
    delegate :docker, 'attach', to_array(args).unshift('--sig-proxy=false')
  end

  def build(args=nil)
    delegate :compose, 'build', args
  end

  def clean(args=nil)
    containers = sys "docker ps -f status=exited -a -q", :true
    images = sys "docker images -f dangling=true -a -q", :true
    volumes = sys "docker volume ls -f dangling=true -q", :true
    if containers and containers.length > 0
      puts 'Containers...'
      delegate :docker, 'rm', containers
    end
    if images and images.length > 0
      puts "\nImages..."
      delegate :docker, 'rmi', ['-f', *images]
    end
    if volumes and volumes.length > 0
      puts "\nVolumes..."
      delegate :docker, 'volume', ['rm', *volumes]
    end
  end

  def config(args=[])
    delegate :compose, 'config', args
  end

  def down(args=[])
    delegate :compose, 'down', to_array(args).unshift('--remove-orphans')
  end

  def exec(args=[])
    delegate :compose, 'exec', args
  end

  def images(args=[])
    delegate :docker, 'images', args
  end

  def logs(args=[])
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

  def pull(args=[])
    delegate :docker, 'pull', args
  end

  def push(args=[])
    delegate :docker, 'push', args
  end

  def rls(args=[])
    delegate :machine, 'ls', args
  end

  def rmi(args=[])
    delegate :docker, 'rmi', args
  end

  def run(args=[])
    delegate :compose, 'run', to_array(args).unshift('--rm')
  end

  def scp(args=[])
    delegate :machine, 'scp', args
  end

  def setup(args=nil)
    has_services = -> arg { get_services arg }
    yamls = find_yamls.select(&has_services) # only include YAMLs with defined services
    return bail 'No YAML files found' unless yamls.length > 0
    update_setup setup_ui yamls
  end

  def ssh(args=[])
    delegate :machine, 'ssh', args
  end

  def stop(argv=[])
    name, *args = argv
    raise(BadArgsError, 'Which service do you want to stop?') unless name and name.length > 0
    args.unshift container(name)
    delegate :docker, 'stop', args
  end

  def tag(args=[])
    delegate :docker, 'tag', args
  end

  def up(args=[])
    delegate :compose, 'up', args
  end

end
