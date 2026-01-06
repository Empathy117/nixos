# hosts/macbook-pro.nix
{ ... }:
{
  users.users.empathy = {
    name = "empathy";
    home = "/Users/empathy";
  };

  system.primaryUser = "empathy";

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;

    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";

    screensaver.askForPasswordDelay = 10;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 6;

  home-manager.users.empathy.imports = [
    ../home/profiles/gui.nix
  ];
}
