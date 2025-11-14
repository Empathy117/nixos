# hosts/wsl.nix
_: {
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  networking.hostName = "wsl";
}
