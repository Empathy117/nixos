{ pkgs, ... }:
{
  networking.hostName = "devbox";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.empathy = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "git"
    ];
    shell = pkgs.zsh;
    description = "Primary development account";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrO/0OgAxwADiPm93IrC9Y87Kfc6pr1OhkbD+bF77ge empathy@DyldadeMacBook-Pro.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXam0l+NkYNEisRt9nYAIR/cfCpMONzX+tVJpU7TjJm empathyyiyiqi@gmail.com"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    htop
    docker
    vlock
  ];

}
