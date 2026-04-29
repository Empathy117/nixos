# Shared Home Manager profile for Linux/WSL user environments.
_: {
  home.stateVersion = "25.11";

  imports = [
    ./shared-cli.nix
  ];
}
