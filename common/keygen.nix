# ~/nixos/common/keygen.nix

{ config, lib, ... }:

{
  home.activation.ensureSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    umask 077
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      ssh-keygen -t ed25519 -N "" -C "${config.home.username}@$(hostname)-hm" \
        -f "$HOME/.ssh/id_ed25519"
      echo
      echo "Generated SSH key at $HOME/.ssh/id_ed25519"
      echo "Public key:"
      cat "$HOME/.ssh/id_ed25519.pub"
      echo
    fi
  '';
}
