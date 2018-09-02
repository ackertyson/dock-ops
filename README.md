# dock-ops

Docker CLI helpers including common development and deployment commands. Run
these commands in your project directory as you would normal Docker Compose
commands.

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
