# ~/nixos/common/keygen.nix

{ config, lib, pkgs, ... }:

{
  home.activation.ensureSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail
    umask 077
    key="$HOME/.ssh/id_ed25519"

    if [ ! -f "$key" ]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      
      host="$(cat /proc/sys/kernel/hostname 2>/dev/null || echo unknown)"

      "${pkgs.openssh}/bin/ssh-keygen" -t ed25519 -N "" \
        -C "${config.home.username}@$host-hm" -f "$key"

      echo
      echo "Generated SSH key at $HOME/.ssh/id_ed25519"
      echo "Public key:"
      cat "$HOME/.ssh/id_ed25519.pub"
      echo
    fi
  '';
}
