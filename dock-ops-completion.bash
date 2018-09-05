# Copy this file to your ~/ and add the following line to ~/.bash_profile (yes,
# it should start with a 'dot'):
#
# . ~/dock-ops-completion.bash

skip_flags() {
  if [[ "$1" = dock ]]; then
    shift
  fi
  case "$1" in
    -m|-nc|-nd|-nm|--compose|--docker|--machine)
      shift; shift
      skip_flags "$@"
      ;;
    -p|--production)
      shift
      skip_flags "$@"
      ;;
    *)
      echo "$1"
      ;;
  esac
}

__dock() {
    local cur prev base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    base=$(skip_flags "${COMP_WORDS[@]}")

    # Complete the arguments to specified commands...
    case "${base}" in
        build|run|up)
            local services=`dock services`
            COMPREPLY=( $(compgen -W "${services}" -- ${cur}) )
            return 0
            ;;
        logs|stop)
            local containers=`docker ps --format "{{.Names}}"`
            COMPREPLY=( $(compgen -W "${containers}" -- ${cur}) )
            return 0
            ;;
        rmi)
            local images=`docker images --format "{{.Repository}}"`
            COMPREPLY=( $(compgen -W "${images}" -- ${cur}) )
            return 0
            ;;
        use)
            local machines=`docker-machine ls --format "{{.Name}}"`
            COMPREPLY=( $(compgen -W "${machines}" -- ${cur}) )
            return 0
            ;;
        *)
        ;;
    esac

    local commands=`dock commands`
    COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
    return 0
}
complete -F __dock dock
