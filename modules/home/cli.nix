{ pkgs, pkgsUnstable, ... }:
{
  home.packages =
    (with pkgs; [
      fastfetch
      nixfmt-rfc-style
      openssl
      python314
      statix
      vim
      wget
      deadnix
      eza
      bat
      lf
      ripgrep
      nixd
      claude-code
      codex
    ])
    ++ [
    ];

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  home.sessionVariables = {
    FZF_CTRL_R_COMMAND = "";
  };
}
