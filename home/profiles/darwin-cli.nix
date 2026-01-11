{
  config,
  pkgs,
  inputs ? { },
  ...
}:
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

    background-opacity = 0.8
    background-opacity-cells = true
    background-blur = 8

    cursor-style = bar
    adjust-cursor-thickness = 3
    cursor-style-blink = false
    cursor-opacity = 0.85

    window-save-state = always

    macos-titlebar-style = transparent
    macos-titlebar-proxy-icon = hidden
    macos-option-as-alt = left

    macos-icon = glass
  '';

  opencodePkg =
    if inputs ? opencode then
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      pkgs.opencode;

in
{
  home.username = "empathy";
  home.homeDirectory = "/Users/empathy";
  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;

  targets.darwin.linkApps.enable = false;

  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
  ];

  home.packages =
    (with pkgs; [
      codex
      claude-code
      nixd
      nixfmt
      statix
      rsync
      tailscale
      tmux
    ])
    ++ [
      opencodePkg
    ];

  xdg.configFile."ghostty/config".text = ghosttyConfig;
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    text = ghosttyConfig;
    force = true;
  };
  home.file.".skhdrc".text = ''
    cmd - space : open -b com.apple.apps.launcher

    cmd - h : yabai -m window --focus west
    cmd - j : yabai -m window --focus south
    cmd - k : yabai -m window --focus north
    cmd - l : yabai -m window --focus east

    cmd + shift - h : yabai -m window --swap west
    cmd + shift - j : yabai -m window --swap south
    cmd + shift - k : yabai -m window --swap north
    cmd + shift - l : yabai -m window --swap east

    ctrl + shift - f : yabai -m window --toggle zoom-fullscreen
    ctrl + shift - t : yabai -m window --toggle float
  '';

  imports = [
    ../../modules/cli/modern.nix
    ../../modules/vscode/gui.nix
    ../../modules/home/nixvim.nix
  ];
}
