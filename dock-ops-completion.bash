# Copy this file to your ~/ and add the following line to ~/.bash_profile (yes,
# it should start with a 'dot'):
#
# . ~/dock-ops-completion.bash

_dock()
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts=`dock commands` # Basic commands to complete

    # Complete the arguments to some of the basic commands.
    case "${prev}" in
        down)
            local running=`docker ps --format "{{.Names}}"`
            COMPREPLY=( $(compgen -W "${running}" -- ${cur}) )
            return 0
            ;;
        up)
            local names=`dock services`
            COMPREPLY=( $(compgen -W "${names}" -- ${cur}) )
            return 0
            ;;
        *)
        ;;
    esac

   COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
   return 0
}
complete -F _dock dock
