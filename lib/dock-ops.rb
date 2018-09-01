require 'yaml'

class RunFailedError < StandardError; end

class DockOps
  def initialize(argv)
    @dock = "docker-compose -f docker-compose.yaml"
    @dock_dev = "docker-compose -f docker-compose.development.yaml"
    cmd, *opts = argv
    self.send cmd.to_sym, *opts
  rescue NoMethodError
    bail "'#{cmd}' is not a choice: build, clean, down, ls, ps, rls, run, scp, ssh, stop, up, unuse, use"
  end

  def as_args(arr) # convert array to space-delimited list (single-quoting elements as needed)
    fn = -> arg { quote arg }
    arr.map(&fn).join(' ')
  end

  def bail(msg)
    abort "DOCK-TOOLS: #{msg}"
  end

  def build(service)
    sys "#{@dock_dev} build #{service}"
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

  def container(name) # find running container NAME
    sys "docker ps -q -f name=#{name}", :true
  end

  def down
    sys "#{@dock_dev} down --remove-orphans"
  end

  def findfiles
    Dir.glob 'docker-compose*.y{a,}ml'
    # files.each do |filename|
    #   if /development/ =~ filename
    #     devfile = filename
    #   else
    #     prodfile = filename
    #   end
    # end
  end

  def ls
    findfiles.each do |file|
      puts file
      services(file).each do |filename|
        puts sprintf "  - %s", filename
      end
    end
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
    sys "#{@dock_dev} run --rm #{service name} #{as_args args}"
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
    does_extend = false
    yaml['services'].keys #.each_pair do |name, config|
      # config.each_pair do |k, v|
      #   if k == 'extends'
      #     does_extend = true
      #     puts File.exist? File.absolute_path(prod)
      #     puts File.absolute_path(v['file']) == prod
      #   end
      # end
    # end
  end

  def stop(name)
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
    sys "#{@dock_dev} up #{as_args args}"
  end

  def use(name)
    sys "eval $(docker-machine env #{name})"
  end
end
