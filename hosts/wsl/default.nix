# hosts/wsl/default.nix
{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.nixos-vscode-server.nixosModules.default
    ../../modules/system/core.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "nixos";

  networking.hostName = "wsl";

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGAK76YpWR+nhg5nmghEHkwGV0mx4egzp+kGurwjFipE empathyyiyiqi@gmail.com"
  ];

  environment.systemPackages = [
    pkgs.google-chrome
  ];

  users.users.nixos.shell = pkgs.fish;

  virtualisation.docker = {
    enable = lib.mkDefault true;
    daemon.settings."registry-mirrors" = [
      "https://docker.mirrors.ustc.edu.cn/"
      "https://docker.mirrors.sjtug.sjtu.edu.cn/"
      "https://docker.tuna.tsinghua.edu.cn/"
      "https://docker.nju.edu.cn/"
      "https://registry.cn-hangzhou.aliyuncs.com/"
    ];
  };

  systemd.services.docker.environment = {
    HTTP_PROXY = "http://127.0.0.1:7890";
    HTTPS_PROXY = "http://127.0.0.1:7890";
    NO_PROXY = "localhost,127.0.0.1";
  };

  services.vscode-server.enable = true;
}
