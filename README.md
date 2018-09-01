# dock-ops

Docker CLI helpers including common development and deployment commands. Run
these commands in your project directory as you would normal Docker Compose
commands. Assumes you have `docker-compose.yaml` and
`docker-compose.development.yaml`.

## Installation

`git clone git@github.com:ackertyson/dock-ops.git`

`cd dock-ops/`

`gem build dock-ops.gemspec`

`sudo gem install dock-ops`

## Usage

`dock COMMAND [OPTIONS]`

E.g., `dock up -d my-service`

## Command equivalents

### build

`docker-compose build`

### clean

`docker rm $(docker ps -f status=exited -a -q); docker rmi $(docker images -f dangling=true -a -q); docker volume rm $(docker volume ls -f dangling=true -q)`

### down

`docker-compose down`

### ls

List services defined in docker-compose file(s).

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

`docker-compose stop`

### up

`docker-compose up`

### unuse

`eval $(docker-machine env -u)`

### use

`eval $(docker-machine env ____)`
