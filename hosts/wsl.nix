# ~/my-nixos-config/wsl.nix

{ config, lib, pkgs, ...}:

{
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  # WSL 集成 Home Manager
  home-manager.users.nixos.imports = [
    ../home/home.nix
  ];
}
