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

  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true;
  };

  environment.etc."mihomo/config.yaml".text = ''
    # placeholder – scp your real config to /etc/mihomo/config.yaml
  '';

  users.users.empathy = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.zsh;
    description = "Primary development account";
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    htop
    docker
  ];

  virtualisation.docker.enable = true;
}
