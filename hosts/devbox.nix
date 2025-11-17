{ pkgs, ... }:
{
  networking.hostName = "devbox";

  # ========================================
  # 用户配置
  # ========================================
  
  users.users.empathy = {
    isNormalUser = true;
    description = "Primary development account";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrO/0OgAxwADiPm93IrC9Y87Kfc6pr1OhkbD+bF77ge empathy@DyldadeMacBook-Pro.local"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # ========================================
  # 服务配置
  # ========================================
  
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true;
  };

  environment.etc."mihomo/config.yaml".text = ''
    # Placeholder - upload your config to /etc/mihomo/config.yaml
  '';

  # ========================================
  # 虚拟化
  # ========================================
  
  virtualisation.docker.enable = true;

  # ========================================
  # 系统工具
  # ========================================
  
  environment.systemPackages = with pkgs; [
    git
    htop
    docker
    vlock
  ];
}
