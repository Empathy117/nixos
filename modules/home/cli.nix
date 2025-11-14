{ pkgs, pkgsUnstable, ... }:
{
  home.packages =
    (with pkgs; [
      direnv
      fastfetch
      nixd
      nixfmt-rfc-style
      openssl
      python314
      statix
      vim
      wget
      deadnix
    ])
    ++ [
      pkgsUnstable.codex
    ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
