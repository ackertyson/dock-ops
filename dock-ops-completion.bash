# Copy this file to your ~/ and add the following line to ~/.bash_profile (yes,
# it should start with a 'dot'):
#
# . ~/dock-ops-completion.bash

__handle_colons() {
  local candidates="$1" cur="$2"
  if [[ $candidates =~ ':' ]]
  then
    # extra hand-holding for results which include colon(s), which bash will
    # otherwise interpret as a word boundary (requires bash-completion
    # package)...
    _get_comp_words_by_ref -n : cur
    COMPREPLY=( $(compgen -W "$candidates" -- $cur) )
    __ltrim_colon_completions $cur
  else
    COMPREPLY=( $(compgen -W "$candidates" -- $cur) )
  fi
  return 0
}

__main() {
  local candidates cur words
  cur="${COMP_WORDS[COMP_CWORD]}"
  words="${COMP_WORDS[@]:1}" # exclude leading "dock" in every command
  candidates=$(dock complete $words) # let DOCK-OPS command parser do the work
  if __handle_colons "$candidates" "$cur" 2>/dev/null; then
    return 0
  else # user's OS is probably missing 'bash-completion' package
    return 1
  fi
}

complete -F __main dock
