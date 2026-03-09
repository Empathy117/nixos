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
}
