# ~/nixos/hosts/wsl.nix

{ ... }:

{
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  # WSL 集成 Home Manager
  home-manager.users.nixos.imports = [
    ../home/home.nix
  ];
}
