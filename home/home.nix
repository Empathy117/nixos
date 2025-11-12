# ~/my-nixos-config/home.nix

{ config, pkgs, ... }:

{

  home.stateVersion = "25.05";

  home.packages = [ 
    pkgs.vim
    pkgs.wget
    pkgs.python314
    pkgs.fastfetch
  ];

  programs.git = {
    enable = true;

    extraConfig = {
      user.name = "empathy";
      user.email = "empathyyiyiqi@gmail.com";

      net.defaultAddressFamily = "inet";
    
      #url."https://gh-proxy.com/https://github.com/".insteadOf = "https://github.com/";

      core.sshCommand = "ssh -4";
    };
    #settings = {
     # net = {
      #  defaultAddressFamily = "inet";
     # };

      #url."https://gh-proxy.com/https://github.com/" = {
       # insteadOf = "https://github.com/";
      #};
    #};
  };

}
