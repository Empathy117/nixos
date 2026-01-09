# hosts/macbook-pro/default.nix
{
  config,
  pkgs,
  lib,
  self,
  ...
}:
let
  appBuilders = import ../../modules/darwin/app-builders.nix { inherit pkgs lib; };
  apps = import ./apps {
    inherit pkgs lib;
    inherit (appBuilders) mkZipApp mkDmgApp;
  };
in
{
  nixpkgs.config.allowUnfree = true;

  # CLI / Shell
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # Fonts (for terminal & Nerd Font icons)
  fonts.packages = [
    pkgs."nerd-fonts"."jetbrains-mono"
    pkgs."maple-mono"."NF-CN"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.empathy = import ../../home/profiles/darwin-cli.nix;
  };

  environment.systemPackages =
    [
      pkgs.vim
    ]
    ++ lib.optional (pkgs ? codex) pkgs.codex
    ++ lib.optional
      (config.home-manager.users.empathy.programs.vscode.enable or false)
      config.home-manager.users.empathy.programs.vscode.package
    ++ apps.all;

  # Determinate Systems 已经管理 Nix 安装与 daemon；这里避免 nix-darwin 介入。
  nix.enable = false;

  users.users.empathy = {
    name = "empathy";
    home = "/Users/empathy";
    shell = pkgs.fish;
  };
  system.primaryUser = "empathy";

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;

    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";

    screensaver.askForPasswordDelay = 10;
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";

  security.pam.services.sudo_local.touchIdAuth = true;
}
