# Copy this file to your ~/ and add the following line to ~/.bash_profile (yes,
# it should start with a 'dot'):
#
# . ~/dock-ops-completion.bash

__commands() {
  local cur="$1"
  local commands=`dock commands`
  COMPREPLY=( $(compgen -W "$commands" -- $cur) )
}

__containers() {
  local cur="$1"
  local containers=`docker ps --format "{{.Names}}"`
  COMPREPLY=( $(compgen -W "$containers" -- $cur) )
}

__images_tagged() {
  # requires more hand-holding because of the ':' in completion words
  # (also requires bash-completion package)
  local cur="$1"
  local images=`docker images --format "{{.Repository}}:{{.Tag}}"`
  _get_comp_words_by_ref -n : cur
  COMPREPLY=( $(compgen -W "$images" -- $cur) )
  __ltrim_colon_completions $cur
}

__images() {
  local cur="$1"
  local images=`docker images --format "{{.Repository}}"`
  COMPREPLY=( $(compgen -W "$images" -- $cur) )
}

__machines() {
  local cur="$1"
  local machines=`docker-machine ls --format "{{.Name}}"`
  COMPREPLY=( $(compgen -W "$machines" -- $cur) )
}

__mode() {
  while [ -n "$1" ]
  do
    case "$1" in
      -m)
        echo "$2"
        return 0
        ;;
      -p|--production)
        echo "production"
        return 0
        ;;
      *)
        shift
        ;;
    esac
  done

  echo "development"
  return 0
}

__services() {
  # So this gets a little twisty; to get sensible SERVICE completions, we need
  # to parse the MODE out of the command and send it back to DOCK so we only get
  # services available to that mode...
  local cur="$1" mode="$2"
  local services=`dock services $mode`
  COMPREPLY=( $(compgen -W "$services" -- $cur) )
}

__skip_flags() {
  if [[ "$1" = dock ]]; then
    shift
  fi
  case "$1" in
    -m|-nc|-nd|-nm|-w|--compose|--docker|--machine|--working-dir)
      shift; shift
      __skip_flags "$@"
      ;;
    -p|--production)
      shift
      __skip_flags "$@"
      ;;
    *)
      echo "$1"
      ;;
  esac
}

__main() {
    local cur prev base mode
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    mode=$(__mode ${COMP_WORDS[@]})
    base=$(__skip_flags "${COMP_WORDS[@]}")

    # case "${prev}" in
    #     -w|--working-dir)
    #         COMPREPLY=( $(compgen -o nospace -o dirnames -- ${cur}) )
    #         return 0
    #         ;;
    #     *)
    #     ;;
    # esac

    # Complete the arguments to specified commands...
    case "${base}" in
        build|logs|run|up)
            __services "$cur" "$mode"
            return 0
            ;;
        images)
            __images "$cur"
            return 0
            ;;
        push|rmi|tag)
            __images_tagged "$cur"
            return 0
            ;;
        stop)
            __containers "$cur"
            return 0
            ;;
        scp|ssh|use)
            __machines "$cur"
            return 0
            ;;
        *)
        ;;
    esac

    __commands "$cur"
    return 0
}

__handle_colons() {
  local candidates="$1" cur="$2"
  if [[ $candidates =~ ':' ]]
  then
    # extra hand-holding for results which include colon(s), which bash will
    # otherwise interpret as a word boundary...
    _get_comp_words_by_ref -n : cur
    COMPREPLY=( $(compgen -W "$candidates" -- $cur) )
    __ltrim_colon_completions $cur
  else
    COMPREPLY=( $(compgen -W "$candidates" -- $cur) )
  fi
  return 0
}

__in_app() {
  local candidates cur words
  cur="${COMP_WORDS[COMP_CWORD]}"
  words="${COMP_WORDS[@]:1}" # exclude leading "dock" in every command
  candidates=$(dock complete $words) # let DOCK-OPS command parser do the work
  __handle_colons "$candidates" "$cur"
  return 0
}

# complete -F __main dock
complete -F __in_app dock
