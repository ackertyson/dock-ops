# dock-ops

*[2021-06-11] Docker Compose commands are now invoked via `docker compose` (Compose V2) instead of the dedicated `docker-compose` command; see DockOps [compose-v1 branch](https://github.com/ackertyson/dock-ops/tree/compose-v1)
for [Compose V1](https://docs.docker.com/compose/cli-command/) behavior.*

This is an eminently useful CLI utility for nerds who do a lot of Docker
development, particularly using Docker Compose. It includes shorthand for many
common development and deployment commands.

Tab completion is available for base commands and for parameters of many
commands. See SHELL COMPLETION and COMMAND EQUIVALENTS sections below.

But it's not merely about succinctness! The coolest feature is arguably that you
can configure how `docker compose` commands are formulated on a per-project
basis (*and* per-mode, i.e., development/production/etc.), specifying which YAML
files should be used for each; see the `setup` command below. You might not get
how awesome this is until you're managing several different projects which all
have different conventions with respect to compose file naming and extending.
Trust me: it's awesome!

Another nice feature is the ability to create custom aliases. You know those
long `docker compose exec` commands that you're always hoping are still in your
bash history? Now there's a better way: see the CUSTOM ALIASES section below.

## Installation

### With Rake

1. `git clone https://github.com/ackertyson/dock-ops.git`

2. `cd dock-ops/`

3. `rake install completion`

4. Add a line to your `~/.bash_profile` (yes, it starts with a "dot"): `. ~/dock-ops-completion.bash`

### Without Rake

1. `git clone https://github.com/ackertyson/dock-ops.git`

2. `cd dock-ops/`

3. `gem build dock-ops.gemspec && sudo gem install -l dock-ops`

4. See the instructions in the `dock-ops-completion.bash` file included with
    this project

### With or without Rake

To get completion to work in existing shell sessions, you have to do `source
~/.bash_profile` after installing the completion script.

If for some reason you don't want to use completion, replace steps 3 and 4 with:

3. `rake install` (or, if you don't have Rake, `gem build dock-ops.gemspec &&
    sudo gem install -l dock-ops`)

*NOTE: you still need to install the real Docker applications; `dock-ops` is just a wrapper.*

## Testing

`rake test`

(Requires `sudo gem install minitest-reporters`.)

## Usage

Commands should be run from **within your project directory** (just as you would
run normal Docker commands). Commands default to *development* mode if none is
explicitly specified (see MODES below). The general format is:

`dock [FLAGS] COMMAND [ARGS]`

FLAGS influence the behavior of `dock-ops` and ARGS are passed to the
corresponding Docker COMMAND. For example:

- `dock up -d my-service` (invoke `up` command in *development* mode), or
- `dock -p up -d my-service` (do the same in *production* mode)

A **good first step** is generating the configuration for your project:

`dock setup`

...which allows you to define which Docker Compose files to use (see the `setup`
command below). Add a mode flag to configure modes other than the default
*development* mode.

## Shell completion

IKR! As if you're not saving enough keystrokes over vanilla Docker already! But
`<TAB>` suggestions are awesome, so follow the directions in the
`dock-ops-completion.bash` file included with this project. Commands with
parameter completions are noted in the COMMAND EQUIVALENTS section below.

Because arguments for `push`, `rmi` and `tag` include colons (for image tags),
and because bash normally considers `:` a word boundary, completions for these
commands unfortunately won't work right unless you have the `bash-completion`
package installed on your OS. For Mac, this is (usually) as easy as `brew update
&& brew install bash-completion`.

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

## Custom aliases

To create a shorthand alias for a frequently used command, you can do:

`dock -a NAME COMMAND`

...where `COMMAND` is the `dock-ops` command you would otherwise enter. E.g., if
you have a MongoDB instance running on a `mongodb` service with a long
connection string which you can never remember, you can do:

`dock -a mongo run mongodb bash -c 'mongo mongodb://mongodb/my-mongo-db'`

...and thenceforth you can simply enter:

`dock mongo`

You can even tab-complete on alias names! And if you forget what aliases you
have defined, you can do:

`dock aliases`

...to see all of them for the current project+mode.

Aliases can also override `dock-ops` built-ins, so if you don't like one of the
default commands, you can formulate your own version.

If you want to delete an alias, use the `-d` flag:

`dock -d previously-created-alias-name`

## Native pass-thru

Want to use a `docker`/`docker compose`/`docker-machine` command that isn't
implemented here? You can tell `dock-ops` to pass the command along to be
handled natively:

- `-nc` / `--compose`, or
- `-nd` / `--docker`, or
- `-nm` / `--machine`

For example, to call `docker-machine regenerate-certs my-app`, do:

- `dock -nm regenerate-certs my-app`, or
- `dock --machine regenerate-certs my-app`

Note that this is a simple flag which doesn't take a parameter. To run the above
command with a mode flag, the following are equivalent:

- `dock -p -nm regenerate-certs my-app`, or
- `dock -nm -p regenerate-certs my-app`

In both cases `regenerate-certs` is the COMMAND portion of the `dock-ops` call,
not a parameter to the `-nm` FLAG.

## Deployed Docker machines

If you routinely find yourself deploying Docker Compose apps to remote hosts
provisioned via `docker-machine create`, I recommend checking out the
`dock-ops-wrapper.bash` script included with this project. You can then do `dock
use MACHINENAME` to connect to a remote instance, run Docker commands on the
remote just the same as you would run them locally, and then `dock unuse` to
return to your local environment.

If you have no idea what I'm talking about but have a Docker Compose app which
you want to run on a single (i.e., non-Swarm) cloud instance somewhere, you
should look into this!

You'll probably also want to check out [docker-machine-prompt](https://github.com/docker/machine/blob/master/contrib/completion/bash/docker-machine-prompt.bash).

## Command equivalents

Last but not least, here's what all the `dock-ops` commands actually do...

*Note: though the name of this package is `dock-ops`, the actual CLI command is
simply `dock`.*

### aliases

List all defined aliases for current project+mode (see CUSTOM ALIASES section
above).

### attach

`docker attach --sig-proxy=false`

Note that the `sig-proxy` option means you can use `Ctrl-c` to detach without
stopping the container.

*Completions: currently running containers*

### build

`docker compose build`

*Completions: services defined in Compose YAML file(s)*

### clean

```
docker rm $(docker ps -f status=exited -a -q);
docker rmi $(docker images -f dangling=true -a -q);
docker volume rm $(docker volume ls -f dangling=true -q)
```

### config

`docker compose config`

### cp

`docker cp $(docker ps -q -f name=_____):source dest` (or container ID computed from dest name if container is dest)

Note that this allows you to designate source/dest containers by *name* (instead of by container
ID, which is how `docker cp` works).

*Completions: currently running containers*

### down

`docker compose down --remove-orphans`

### exec

`docker compose exec`

*Completions: services defined in Compose YAML file(s)*

### images

`docker images`

*Completions: local image repository names*

### logs

`docker compose logs -f`

*Completions: services defined in Compose YAML file(s)*

### ls

List services defined in Compose YAML file(s).

### ps

`docker compose ps`

### psa

`docker ps`

### pull

`docker pull`

### push

`docker push`

*Completions: local image repository names (with tags)*

### restart

`docker compose restart`

*Completions: services defined in Compose YAML file(s)*

### rls

`docker-machine ls`

### rmi

`docker rmi`

*Completions: local image repository names (with tags)*

### run

`docker compose run --rm`

*Completions: services defined in Compose YAML file(s)*

### scp

`docker-machine scp`

*Completions: provisioned machine names*

### setup

Configure the Docker Compose command which `dock-ops` should use for current
project.

This command will configure the specified mode (see MODES section above).
To set up for *deploy* mode, for instance, do `dock -m deploy setup`.

### ssh

`docker-machine ssh`

*Completions: provisioned machine names*

### stop

`docker stop $(docker ps -q -f name=_____)`

Note that this allows you to stop containers by *name* (instead of by container
ID, which is how `docker stop` works).

*Completions: currently running containers*

### tag

`docker tag`

*Completions: local image repository names (with tags)*

### up

`docker compose up`

*Completions: services defined in Compose YAML file(s)*
