# Copy this file to your ~/ and add the following line to ~/.bash_profile (yes,
# it should start with a 'dot'):
#
# . ~/dock-ops-completion.bash

skip_flags() {
  if [[ "$1" = dock ]]; then
    shift
  fi
  case "$1" in
    -m|-nc|-nd|-nm|-w|--compose|--docker|--machine|--working-dir)
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

    # case "${prev}" in
    #     -w|--working-dir)
    #         local services=`dock services`
    #         COMPREPLY=( $(compgen -o nospace -o dirnames -- ${cur}) )
    #         return 0
    #         ;;
    #     *)
    #     ;;
    # esac

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
        push|rmi|tag)
            # requires more hand-holding because of the ':' in completion words
            # (also requires bash-completion package)
            local images=`docker images --format "{{.Repository}}:{{.Tag}}"`
            _get_comp_words_by_ref -n : cur
            COMPREPLY=( $(compgen -W "${images}" -- ${cur}) )
            __ltrim_colon_completions ${cur}
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
