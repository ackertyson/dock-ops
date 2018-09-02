# dock-ops

Docker CLI helpers including common development and deployment commands. Run
these commands in your project directory as you would normal Docker Compose
commands.

Also allows per-project (and per-mode, i.e., development/production/etc.)
configuration of how `docker-compose` commands are formulated (which YAML files
should be used); see the `config` command below.

## Installation

`git clone git@github.com:ackertyson/dock-ops.git`

`cd dock-ops/`

`gem build dock-ops.gemspec`

`sudo gem install dock-ops`

## Usage

Commands should be run from within your project directory (just as you would
run normal Docker Compose commands).

`dock COMMAND [OPTIONS]`

E.g., `dock up -d my-service`

Commands which invoke Docker Compose can be configured by "mode"
(development/production/etc.) in order to designate which YAML files should be
used. The default is `development` mode; you can specify a different mode with
`-m`:

- `dock -m production COMMAND`, or
- `dock -m some-other-crazy-mode COMMAND`

For `production` mode, you can also do:

- `dock -p COMMAND`, or
- `dock --production COMMAND`

## Command equivalents

### build

`docker-compose build`

### clean

`docker rm $(docker ps -f status=exited -a -q); docker rmi $(docker images -f dangling=true -a -q); docker volume rm $(docker volume ls -f dangling=true -q)`

### config

Configure the Docker Compose command which `dock-ops` should use for current
project (this is *not* `docker-compose config`!).

### down

`docker-compose down`

### ls

List services defined in `docker-compose` YAML file(s).

### ps

`docker ps`

### rls

`docker-machine ls`

### run

`docker-compose run --rm`

### scp

`docker-machine scp`

### ssh

`docker-machine ssh`

### stop

`docker stop $(docker ps -q -f name=_____)`

Note that this allows you to stop containers by _name_ (instead of by container
ID, which is how `docker stop` works).

### up

`docker-compose up`

### unuse

`eval $(docker-machine env -u)`

### use

`eval $(docker-machine env ____)`
