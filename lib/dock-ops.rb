require 'dock-ops-core'

class BadArgsError < StandardError; end
class NoModeError < StandardError; end
class RunFailedError < StandardError; end

# public commands for DockOps
class DockOps < DockOpsCore
  def initialize(config_version = 1)
    super config_version
  end

  def aliases(*)
    get_aliases.each_pair do |name, cmd|
      puts format('%<name>s => %<cmd>s', name: bling(name), cmd: cmd)
    end
  end

  def attach(args = [])
    delegate :docker, 'attach', to_array(args).unshift('--sig-proxy=false')
  end

  def build(args = nil)
    delegate :compose, 'build', args
  end

  def clean(*)
    containers = sys 'docker ps -f status=exited -a -q', true
    images = sys 'docker images -f dangling=true -a -q', true
    volumes = sys 'docker volume ls -f dangling=true -q', true
    if containers && !containers.empty?
      puts 'Containers...'
      delegate :docker, 'rm', containers
    end
    if images && !images.empty?
      puts "\nImages..."
      delegate :docker, 'rmi', ['-f', *images]
    end
    if volumes && !volumes.empty?
      puts "\nVolumes..."
      delegate :docker, 'volume', ['rm', *volumes]
    end
  end

  def config(args = [])
    delegate :compose, 'config', args
  end

  def down(args = [])
    delegate :compose, 'down', to_array(args).unshift('--remove-orphans')
  end

  def exec(args = [])
    delegate :compose, 'exec', args
  end

  def images(args = [])
    delegate :docker, 'images', args
  end

  def logs(args = [])
    delegate :compose, 'logs', to_array(args).unshift('-f')
  end

  def ls(*)
    find_yamls.each do |filename|
      servicenames = get_services filename
      next unless servicenames && !servicenames.empty?

      puts filename
      servicenames.each do |servicename|
        puts format('  - %<name>s', name: servicename) if servicename
      end
    end
  end

  def ps(args = [])
    delegate :compose, 'ps', args
  end

  def psa(args = [])
    delegate :docker, 'ps', args
  end

  def pull(args = [])
    delegate :docker, 'pull', args
  end

  def push(args = [])
    delegate :docker, 'push', args
  end

  def restart(args = [])
    delegate :compose, 'restart', args
  end

  def rls(args = [])
    delegate :machine, 'ls', args
  end

  def rmi(args = [])
    delegate :docker, 'rmi', args
  end

  def run(args = [])
    delegate :compose, 'run', to_array(args).unshift('--rm')
  end

  def scp(args = [])
    delegate :machine, 'scp', args
  end

  def setup(*)
    has_services = ->(arg) { get_services arg }
    yamls = find_yamls.select(&has_services) # only include YAMLs with defined services
    return bail 'No YAML files found' if yamls.empty?

    update_setup setup_ui yamls
  end

  def ssh(args = [])
    delegate :machine, 'ssh', args
  end

  def stop(argv = [])
    name, *args = argv
    raise(BadArgsError, 'Which service do you want to stop?') unless name && !name.empty?

    args.unshift container(name)
    delegate :docker, 'stop', args
  end

  def tag(args = [])
    delegate :docker, 'tag', args
  end

  def up(args = [])
    delegate :compose, 'up', args
  end
end
