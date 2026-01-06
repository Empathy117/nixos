# home/profiles/gui.nix
{ ... }:
{
  imports = [
    ../home.nix
    ../../modules/vscode/gui.nix
  ];
}
