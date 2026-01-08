# hosts/wsl/default.nix
{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../common/global
    ../common/optional/docker.nix
    ../common/optional/yoohoo.nix
    ../common/optional/vscode-remote.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "nixos";

  networking.hostName = "wsl";

  users.users.nixos.shell = pkgs.zsh;
}
