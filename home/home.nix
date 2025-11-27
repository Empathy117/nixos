# home/home.nix
_: {
  home.stateVersion = "25.11";

  imports = [
    ../modules/home/cli.nix
    ../modules/home/git.nix
    ../modules/home/ssh.nix
    ../modules/home/ssh-key.nix
    ../modules/home/nixvim.nix
    ../modules/home/zsh.nix
    ../modules/home/direnv.nix
    ../modules/home/nodejs
  ];

}
