{ config, ... }:
let
  ghosttyConfig = ''
    theme = "light:Catppuccin Latte,dark:Catppuccin Mocha"

    term = xterm-256color

    font-family = ""
    font-family = "Maple Mono NF CN"
    font-family = "JetBrainsMono Nerd Font Mono"
    font-size = 14

    command = /run/current-system/sw/bin/fish

    window-padding-x = 12
    window-padding-y = 12
    window-padding-balance = true

    window-colorspace = display-p3

    background-opacity = 0.9
    background-opacity-cells = true
    background-blur = 30

    cursor-style = bar
    adjust-cursor-thickness = 2
    cursor-style-blink = false
    cursor-opacity = 0.85

    window-save-state = always

    macos-titlebar-style = transparent
    macos-titlebar-proxy-icon = hidden
    macos-option-as-alt = left

    macos-icon = glass
  '';
in
{
  home.username = "empathy";
  home.homeDirectory = "/Users/empathy";
  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;

  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
  ];

  # Ghostty on macOS may prefer the App Support config path.
  xdg.configFile."ghostty/config".text = ghosttyConfig;
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    text = ghosttyConfig;
    force = true;
  };

  imports = [
    ../../modules/cli/modern.nix
    ../../modules/vscode/gui.nix
  ];
}
