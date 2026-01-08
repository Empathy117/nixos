{ ... }:
{
  imports = [
    ../common/global
    ../common/optional/docker.nix
    ../common/optional/yoohoo.nix
    ../common/optional/vscode-remote.nix
    ../common/optional/user-empathy.nix
  ];

  networking.hostName = "devbox";
}
