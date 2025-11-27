{ pkgsUnstable, lualineSrc, ... }:
{
  programs.nixvim = {
    enable = true;

    colorschemes.catppuccin.enable = true;

    plugins.lualine.enable = false;
  };
}
