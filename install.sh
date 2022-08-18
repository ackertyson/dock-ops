#!/bin/sh

OPTS=$1

echo "Building DockOps..."
echo
cargo build --release && \
  echo && \
  echo "Installing binary..." && \
  cp target/release/dock target/release/dock_bin && \
  mv -iv target/release/dock_bin /usr/local/bin/dock && \
  cat <<EOF

Done! The 'dock' command should now be available; try 'dock help' to start. Or 'dock setup' if you're the adventurous type.
EOF

if [[ "$OPTS" == "completion" ]]
then
  echo
  echo "Installing completion script..."
  cp -v dock-ops-completion.bash ~/ && \
  cat <<EOF
Done! You should add

  . ~/dock-ops-completion.bash

(yes, that starts with a 'dot') to your ~/.bash_profile or similar and then do

  $ source ~/.bash_profile

for completions to be available in any open terminals.
EOF
fi
