# home/home.nix
{ ... }:
{
  home.stateVersion = "25.05";

  imports = [
    ../modules/home/cli.nix
    ../modules/home/git.nix
    ../modules/home/ssh.nix
    ../modules/home/ssh-key.nix
  ];

}
