{ pkgs, ... }:
{
  networking.hostName = "devbox";

  programs.fish.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.empathy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.fish;
    description = "Primary development account";
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    fish
    git
    htop
    neovim
  ];

  virtualisation.docker.enable = true;
}
