#!/bin/bash
#
# Copy this file to your ~/ and add the following line to ~/.bash_profile (yes,
# it should start with a 'dot'):
#
# . ~/dock-ops-wrapper.bash

__dock_wrapper () {
  if [[ "$1" == use ]]; then
    shift
    eval "$(docker-machine env "$@")"
  elif [[ "$1" == unuse ]]; then
    eval "$(docker-machine env -u)"
  else
    command dock "$@"
  fi
}

alias dock=__dock_wrapper
