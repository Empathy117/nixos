{ pkgs, ... }:
{
  networking.hostName = "devbox";

  programs.zsh = {
    enable = true;
    autosuggestions = {
      enable = true;
    };
    syntaxHighlighting = {
      enable = true;
    };
    enableCompletion = true;
    initExtra = ''
    '';
    history = {
      size = 10000;
      save = 10000;
      share = true;
      ignoreDuplicates = true;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.mihomo = {
    enable = true;
    # configFile = "";
    # tunMode = true;
  };

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
