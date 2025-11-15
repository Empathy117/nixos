# hosts/wsl.nix
{ pkgs, ... }: {
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  networking.hostName = "wsl";

  users.users.nixos.shell = pkgs.zsh;
}
