# ~/nixos/common/keygen.nix

{ config, lib, ... }:

{
  home.activation.ensureSshKey = lib.hm.dag.entryAfter [ "writeBoundary"] ''
    set -eu
    umask 077
    if [ ! -f "$HOME/.ssh/id_ssh_empathy117" ]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.shh"
      ssh-keygen -t ssh_empathy117 -N "" -C "${config.home.user.name}@$(hostname)-hm" \
        -f "$HOME/.ssh/id_ssh_empathy117"
      echo
      echo "Generated SSH key at $HOME/.ssh/id_ssh_empathy117"
      echo "Public key:"
      cat "$HOME/.ssh/id_ssh_empathy117.pub"
      echo
    fi
  '';
}
