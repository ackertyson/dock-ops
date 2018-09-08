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

__gitcomp () { # guess where I stole this from?
    local cur_="${3-$cur}"

    case "$cur_" in
    --*=)
        ;;
    *)
        local c i=0 IFS=$' \t\n'
        for c in $1; do
            c="$c${4-}"
            if [[ $c == "$cur_"* ]]; then
                case $c in
                --*=*|*.) ;;
                *) c="$c " ;;
                esac
                COMPREPLY[i++]="${2-}$c"
            fi
        done
        ;;
    esac
}

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

__services() {
  local cur="$1"
  local services=`dock services`
  COMPREPLY=( $(compgen -W "$services" -- $cur) )
}

__dock() {
    local cur prev base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    base=$(skip_flags "${COMP_WORDS[@]}")

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
            __services "$cur"
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
complete -F __dock dock
