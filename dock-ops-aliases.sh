# https://github.com/ackertyson/dock-ops
#
# Copy this file to your ~/ and add the following line to your
# .bash_profile or .bashrc, as appropriate (yes, it should start with
# a 'dot')...
#
# . ~/dock-ops-aliases.sh
#

alias dock-unuse='eval $(docker-machine env -u)'

function dock-use {
    eval $(docker-machine env $1)
}
