{ inputs, ... }:
{
  imports = [
    inputs.nixos-vscode-server.nixosModules.default
    ../../../modules/system/vscode-remote.nix
  ];
}
