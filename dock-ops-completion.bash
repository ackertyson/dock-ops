# Copy this file to your ~/ and add the following line to ~/.bash_profile (yes,
# it should start with a 'dot'):
#
# . ~/dock-ops-completion.bash

__dock() {
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmd="${COMP_WORDS[1]}"

    # skip over prefix flags to find command...
    for ((i = 1; i < ${#COMP_WORDS[@]}; ++i))
      do
        case "${COMP_WORDS[i]}" in
          -m|-nc|-nd|-nm|--compose|--docker|--machine)
            cmd="${COMP_WORDS[i+2]}"
            break
            ;;
          -p|--production)
            cmd="${COMP_WORDS[i+1]}"
            break
            ;;
          *)
          ;;
        esac
    done

    opts="build clean config down images logs ls ps push pull rls rmi run scp setup ssh stop tag up" # Basic commands to complete

    # Complete the arguments to specified commands...
    case "${cmd}" in
        build|run|up)
            local names=`dock services`
            COMPREPLY=( $(compgen -W "${names}" -- ${cur}) )
            return 0
            ;;
        logs|stop)
            local names=`docker ps --format "{{.Names}}"`
            COMPREPLY=( $(compgen -W "${names}" -- ${cur}) )
            return 0
            ;;
        use)
            local names=`docker-machine ls --format "{{.Name}}"`
            COMPREPLY=( $(compgen -W "${names}" -- ${cur}) )
            return 0
            ;;
        *)
        ;;
    esac

   COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
   return 0
}
complete -F __dock dock