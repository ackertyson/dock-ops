# dock-ops

This is an eminently useful CLI utility for nerds who do a lot of Docker
development, particularly using Docker Compose. It includes shorthand for many
common development and deployment commands.

But it's not merely about succinctness! The coolest feature is arguably that you
can configure how `docker-compose` commands are formulated on a per-project
basis (*and* per-mode, i.e., development/production/etc.), specifying which YAML
files should be used for each; see the `setup` command below. You might not get
how awesome this is until you're managing several different projects which all
have different conventions with respect to compose file naming and extending.
Trust me: it's awesome!

The tab-completion feature is pretty sweet, too. Read on...

*NOTE: you do still need to install the real Docker applications; `dock-ops` is
just a wrapper.*

## Installation

1. `git clone https://github.com/ackertyson/dock-ops.git`

2. `cd dock-ops/`

3. `rake` (or, if you don't have Rake, `gem build dock-ops.gemspec`)

4. `rake install` (or, if you don't have Rake, `sudo gem install -l dock-ops`)

## Testing

`rake test`

(Requires `sudo gem install minitest-reporters`. And I'm not giving you the
non-Rake version of this command. If you want to run tests, just install Rake
already.)

## Usage

Commands should be run from **within your project directory** (just as you would
run normal Docker commands). Commands default to *development* mode if none is
explicitly specified (see MODES below). The general format is:

`dock [FLAGS] COMMAND [ARGS]`

FLAGS influence the behavior of `dock-ops` and ARGS are passed to the
corresponding Docker COMMAND. For example:

- `dock up -d my-service` (run UP command in *development* mode), or
- `dock -p up -d my-service` (do the same in *production* mode)

A **good first step** is generating the configuration for your project:

`dock setup`

...which allows you to define which docker-compose files to use (see the `setup`
command below). Add a mode flag to configure modes other than the default
*development* mode.

## Shell completion

IKR! As if you're not saving enough keystrokes over vanilla Docker already! But
`<TAB>` suggestions are awesome, so follow the directions in the
`dock-ops-completion.bash` file included with this project. Commands with
parameter completion options are noted below.

## Modes

Commands which invoke Docker Compose can be set up by "mode"
(development/production/etc.) in order to designate which YAML files should be
used (see `setup` command below). The default is *development* mode; you can
specify a different mode with `-m`:

- `dock -m production COMMAND`, or
- `dock -m some-other-crazy-mode COMMAND`

For *production* mode (since that is a fairly common use-case :) you can also
do:

- `dock -p COMMAND`, or
- `dock --production COMMAND`

## Native pass-thru

Want to use a `docker`/`docker-compose`/`docker-machine` command that isn't
implemented here? You can tell `dock-ops` to pass the command along to be
handled natively:

- `-nc` / `--compose`, or
- `-nd` / `--docker`, or
- `-nm` / `--machine`

For example, to call `docker-machine regenerate-certs my-app`, do:

- `dock -nm regenerate-certs my-app`, or
- `dock --machine regenerate-certs my-app`

## Deployed Docker machines

If you're the type of person who finds themselves deploying Docker Compose apps
to remote hosts provisioned via `docker-machine create`, I recommend following
the directions found in the `dock-ops-wrapper.sh` script included with this
project. You can then do `dock use MACHINENAME` to connect to a remote instance,
run Docker commands on the remote just the same as you would run them locally,
and then `dock unuse` when you're done.

If you have no idea what I'm talking about but have a Docker Compose app which
you want to run on a single (i.e., non-Swarm) cloud instance somewhere, you
should look into this!

You'll probably also want to check out [docker-machine-prompt](https://github.com/docker/machine/blob/master/contrib/completion/bash/docker-machine-prompt.bash).

## Command equivalents

Last but not least, here's what all the `dock-ops` commands actually do...

### build

`docker-compose build`

*Completions: services defined in Compose YAML file(s)*

### clean

`docker rm $(docker ps -f status=exited -a -q); docker rmi $(docker images -f dangling=true -a -q); docker volume rm $(docker volume ls -f dangling=true -q)`

### config

`docker-compose config`

### down

`docker-compose down`

### images

`docker images`

### logs

`docker-compose logs`

*Completions: currently running containers*

### ls

List services defined in Compose YAML file(s).

### ps

`docker ps`

### pull

`docker pull`

### push

`docker push`

### rls

`docker-machine ls`

### rmi

`docker rmi`

*Completions: existing image names*

### run

`docker-compose run --rm`

*Completions: services defined in Compose YAML file(s)*

### scp

`docker-machine scp`

### setup

Configure the Docker Compose command which `dock-ops` should use for current
project.

This command will configure the specified mode (see MODES section above).
To set up for *deploy* mode, for instance, do `dock -m deploy setup`.

### ssh

`docker-machine ssh`

### stop

`docker stop $(docker ps -q -f name=_____)`

Note that this allows you to stop containers by *name* (instead of by container
ID, which is how `docker stop` works).

*Completions: currently running containers*

### tag

`docker tag`

### up

`docker-compose up`

*Completions: services defined in Compose YAML file(s)*
