{ pkgsUnstable, lualineSrc, ... }:
{
  programs.nixvim = {
    enable = true;

    colorschemes.catppuccin.enable = true;

    # 禁用 nixpkgs/nixvim 自带的 lualine，避免上游 hash 出错
    plugins.lualine.enable = false;

    # 使用我们自己的 lualine.nvim 构建
    extraPlugins = [
      (pkgsUnstable.vimUtils.buildVimPlugin {
        pname = "lualine.nvim";
        version = "unstable";
        src = lualineSrc;
      })
    ];

    extraConfigLua = ''
      require("lualine").setup({})
    '';
  };
}
