# hosts/wsl.nix
{ ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  # NixOS 版本锚点 (按主机维护，避免耦合到“通用模块”)
  system.stateVersion = "25.05";

  # VS Code Remote Development (仅需要远程端的机器启用)
  services.vscode-server.enable = true;

  # WSL: 只管理 VSCode remote 端状态；GUI VS Code 由宿主系统管理
  home-manager.users.nixos.imports = [
    ../home/profiles/wsl.nix
  ];
}
